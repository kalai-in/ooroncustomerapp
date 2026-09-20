import 'package:customer/commons/widgets/app_png_icon.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/configs/app_config.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:customer/features/orders/cubit/road_route_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Order tracking map that switches between OSM (flutter_map) and Google Maps
/// based on the app's configured map provider — same switch used on the
/// address picker screen.
class OrderTrackingMapView extends StatefulWidget {
  final bool isGoogle;
  final MapController osmController;
  final void Function(gmap.GoogleMapController) onGoogleMapCreated;
  final LatLng deliveryAddressPoint;
  final LatLng? deliveryBoyPoint;
  final LatLng? storePoint;
  final int? orderId;
  final Color primaryColor;
  final Color onPrimaryColor;

  const OrderTrackingMapView({
    super.key,
    required this.isGoogle,
    required this.osmController,
    required this.onGoogleMapCreated,
    required this.deliveryAddressPoint,
    required this.deliveryBoyPoint,
    this.storePoint,
    required this.orderId,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  @override
  State<OrderTrackingMapView> createState() => _OrderTrackingMapViewState();
}

class _OrderTrackingMapViewState extends State<OrderTrackingMapView> {
  gmap.BitmapDescriptor? _deliveryBoyIcon;
  gmap.BitmapDescriptor? _destinationIcon;
  gmap.BitmapDescriptor? _storeIcon;
  gmap.GoogleMapController? _googleController;

  /// Fit-both-points runs once, the first time a delivery-boy location is
  /// available, so the opening frame already frames boy + destination. Left
  /// alone after that so it never fights the user's own zoom/pan.
  bool _hasFittedBounds = false;

  /// Road-snapped route points from OSRM's free public routing server, used
  /// only for the OSM (flutter_map) tracking view so the line follows actual
  /// roads instead of cutting straight through buildings. The Google view
  /// never fetches this and always shows the direct 2-point line.
  List<LatLng>? _routePoints;

  /// Location the current route was fetched from, so minor GPS jitter
  /// doesn't re-hit the routing server on every location update.
  LatLng? _routedFrom;

  /// Minimum movement (metres) before re-fetching the road route.
  static const double _routeRefreshMeters = 30;

  StreamSubscription<RoadRouteState>? _routeSub;

  bool get isGoogle => widget.isGoogle;
  MapController get osmController => widget.osmController;
  void Function(gmap.GoogleMapController) get onGoogleMapCreated =>
      widget.onGoogleMapCreated;
  LatLng get deliveryAddressPoint => widget.deliveryAddressPoint;
  LatLng? get deliveryBoyPoint => widget.deliveryBoyPoint;
  Color get primaryColor => widget.primaryColor;
  Color get onPrimaryColor => widget.onPrimaryColor;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogle) {
      _loadDeliveryBoyIcon();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _captureDestinationIcon(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureStoreIcon());
    }
    _routeSub = context.read<RoadRouteCubit>().stream.listen((state) {
      if (state is RoadRouteLoaded && state.points != null && mounted) {
        setState(() => _routePoints = state.points);
      }
    });
    final origin = widget.deliveryBoyPoint ?? widget.storePoint;
    if (origin != null) {
      _maybeFetchRoute(origin);
    }
  }

  @override
  void dispose() {
    _routeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryBoyIcon() async {
    final icon = await gmap.BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(40, 40)),
      AssetsConstants.deliveryBoyTrackingIcon,
    );
    if (mounted) {
      setState(() => _deliveryBoyIcon = icon);
    }
  }

  /// Rasterizes the destination SVG (same asset used for the OSM marker)
  /// straight from its picture data so Google Maps shows the matching pin
  /// instead of its default red marker.
  ///
  /// Previously this snapshotted an offscreen `AppSvgIcon` via
  /// `RepaintBoundary`, but `SvgPicture.asset` decodes asynchronously off
  /// the build phase — the first post-frame callback fired before the
  /// offscreen icon had actually painted, so the capture came out blank and
  /// Google silently fell back to its default pin. Loading the vector
  /// picture directly and drawing it onto our own canvas sidesteps that
  /// widget-paint timing entirely.
  Future<void> _captureDestinationIcon() async {
    final icon = await _rasterizeSvgIcon(AssetsConstants.destinationLocationIcon);
    if (icon != null && mounted) setState(() => _destinationIcon = icon);
  }

  /// Same rasterization as [_captureDestinationIcon], for the store pin
  /// shown at [OrderTrackingMapView.storePoint] (mirrors the OSM `AppSvgIcon`
  /// store marker) — Google Maps has no vector-marker support, only bitmaps.
  Future<void> _captureStoreIcon() async {
    final icon = await _rasterizeSvgIcon(AssetsConstants.storePinIcon);
    if (icon != null && mounted) setState(() => _storeIcon = icon);
  }

  /// Rasterizes an svg asset straight from its picture data so Google Maps
  /// shows the matching pin instead of its default red marker.
  ///
  /// Previously this snapshotted an offscreen `AppSvgIcon` via
  /// `RepaintBoundary`, but `SvgPicture.asset` decodes asynchronously off
  /// the build phase — the first post-frame callback fired before the
  /// offscreen icon had actually painted, so the capture came out blank and
  /// Google silently fell back to its default pin. Loading the vector
  /// picture directly and drawing it onto our own canvas sidesteps that
  /// widget-paint timing entirely.
  Future<gmap.BitmapDescriptor?> _rasterizeSvgIcon(String asset) async {
    const displaySize = 35.0;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final pictureInfo = await vg.loadPicture(SvgAssetLoader(asset), null);
    final targetPx = (displaySize * pixelRatio).round();
    // `BoxFit.contain` (used by AppSvgIcon on the OSM side) auto-centers a
    // non-square viewBox inside its square box; drawing straight onto the
    // canvas doesn't, so a non-square SVG landed in a corner of the bitmap
    // instead of its center — anchor (0.5, 0.5) then pointed at empty
    // padding next to the icon instead of the icon itself.
    final scale =
        targetPx / math.max(pictureInfo.size.width, pictureInfo.size.height);
    final dx = (targetPx - pictureInfo.size.width * scale) / 2;
    final dy = (targetPx - pictureInfo.size.height * scale) / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    final image = await recorder.endRecording().toImage(targetPx, targetPx);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    pictureInfo.picture.dispose();
    if (bytes == null) return null;
    // Without `imagePixelRatio`, Google Maps treats the bitmap's raw pixel
    // count as device-independent pixels — our 2x-supersampled bitmap then
    // rendered at 2x the intended size, and got blurrier still once the
    // device's own screen density stretched it further.
    return gmap.BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  @override
  void didUpdateWidget(covariant OrderTrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFittedBounds &&
        oldWidget.deliveryBoyPoint == null &&
        widget.deliveryBoyPoint != null) {
      _fitBounds();
    }
    final origin = widget.deliveryBoyPoint ?? widget.storePoint;
    if (origin != null) {
      _maybeFetchRoute(origin);
    }
  }

  /// Re-fetches the road route — from the delivery boy once GPS is
  /// available, else from the store as the pre-rider fallback line — only if
  /// [origin] moved far enough since the last fetch, so the free OSRM demo
  /// server isn't hammered on every GPS tick. Google view skips OSRM
  /// entirely and uses the direct line — no third-party routing dependency
  /// needed on that provider.
  void _maybeFetchRoute(LatLng origin) {
    if (isGoogle) return;
    final routedFrom = _routedFrom;
    if (routedFrom != null &&
        Geolocator.distanceBetween(
              routedFrom.latitude,
              routedFrom.longitude,
              origin.latitude,
              origin.longitude,
            ) <
            _routeRefreshMeters) {
      return;
    }
    _routedFrom = origin;
    context.read<RoadRouteCubit>().fetchRoute(origin, deliveryAddressPoint);
  }

  /// Road-snapped points when available, else the direct line as fallback.
  List<LatLng> _polylinePoints(LatLng origin) =>
      _routePoints ?? [origin, deliveryAddressPoint];

  /// Tracking line to draw right now: the delivery boy's route once GPS is
  /// available, otherwise the store-to-customer route as a pre-rider
  /// fallback so the customer isn't looking at a bare map before the boy's
  /// data arrives. Both are road-snapped on OSM (via [_polylinePoints] /
  /// [_routePoints]) and a direct line on Google, same as the boy line
  /// always was.
  List<LatLng> _currentLinePoints() {
    final origin = deliveryBoyPoint ?? widget.storePoint;
    if (origin == null) return const [];
    return _polylinePoints(origin);
  }

  /// Height of the draggable bottom sheet's initial size, reserved as bottom
  /// padding so the fit doesn't tuck either marker behind it.
  double get _bottomSheetReserve => context.screenHeight * 0.42;

  /// Frames both the delivery boy and the destination on screen together,
  /// clear of the bottom sheet.
  void _fitBounds() {
    final boyPoint = widget.deliveryBoyPoint;
    if (boyPoint == null) return;
    _hasFittedBounds = true;
    if (isGoogle) {
      _googleController?.moveCamera(_googleBoundsUpdate(boyPoint));
    } else {
      osmController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(boyPoint, deliveryAddressPoint),
          padding: EdgeInsets.only(
            top: context.heightFraction(0.074),
            left: context.heightFraction(0.074),
            right: context.heightFraction(0.074),
            bottom: _bottomSheetReserve + context.heightFraction(0.05),
          ),
        ),
      );
    }
  }

  gmap.CameraUpdate _googleBoundsUpdate(LatLng boyPoint) {
    final south = math.min(boyPoint.latitude, deliveryAddressPoint.latitude);
    final north = math.max(boyPoint.latitude, deliveryAddressPoint.latitude);
    final west = math.min(
      boyPoint.longitude,
      deliveryAddressPoint.longitude,
    );
    final east = math.max(
      boyPoint.longitude,
      deliveryAddressPoint.longitude,
    );
    return gmap.CameraUpdate.newLatLngBounds(
      gmap.LatLngBounds(
        southwest: gmap.LatLng(south, west),
        northeast: gmap.LatLng(north, east),
      ),
      60,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isGoogle) return _buildFlutterMap();
    return _buildGoogleMap();
  }

  /// Compass bearing (degrees, 0-360) from [from] to [to], used to point the
  /// delivery-boy icon along the tracking line toward the destination.
  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  Widget _buildFlutterMap() {
    final boyPoint = deliveryBoyPoint;
    final linePoints = _currentLinePoints();
    return FlutterMap(
      mapController: osmController,
      options: MapOptions(
        initialCenter: deliveryAddressPoint,
        initialZoom: 17.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          if (deliveryBoyPoint != null) {
            _fitBounds();
          } else {
            osmController.move(deliveryAddressPoint, 17.0);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.osmMapRenderUrl,
          userAgentPackageName: AppConfig.appPackageName,
          subdomains: AppConstants.osmTileSubdomains,
        ),
        if (linePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: linePoints,
                color: primaryColor.withValues(alpha: 0.6),
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: deliveryAddressPoint,
              width: 40,
              height: 40,
              child: AppSvgIcon(
                AssetsConstants.destinationLocationIcon,
                size: ThemeConstants.iconXL,
              ),
            ),
            if (widget.storePoint != null)
              Marker(
                point: widget.storePoint!,
                width: 40,
                height: 40,
                child: AppSvgIcon(
                  AssetsConstants.storePinIcon,
                  size: ThemeConstants.iconXL,
                ),
              ),
            if (boyPoint != null)
              Marker(
                point: boyPoint,
                width: 40,
                height: 40,
                child: Transform.rotate(
                  angle:
                      _bearingDegrees(boyPoint, deliveryAddressPoint) *
                      math.pi /
                      180,
                  child: AppPngIcon(
                    AssetsConstants.deliveryBoyTrackingIcon,
                    size: ThemeConstants.iconXL,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    final boyPoint = deliveryBoyPoint;
    final linePoints = _currentLinePoints();
    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: gmap.LatLng(
          deliveryAddressPoint.latitude,
          deliveryAddressPoint.longitude,
        ),
        zoom: 17.0,
      ),
      onMapCreated: (controller) {
        onGoogleMapCreated(controller);
        _googleController = controller;
        if (deliveryBoyPoint != null) {
          _fitBounds();
        } else {
          controller.moveCamera(
            gmap.CameraUpdate.newLatLngZoom(
              gmap.LatLng(
                deliveryAddressPoint.latitude,
                deliveryAddressPoint.longitude,
              ),
              17.0,
            ),
          );
        }
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      padding: EdgeInsets.only(bottom: _bottomSheetReserve),
      markers: {
        gmap.Marker(
          markerId: const gmap.MarkerId('address'),
          position: gmap.LatLng(
            deliveryAddressPoint.latitude,
            deliveryAddressPoint.longitude,
          ),
          anchor: const Offset(0.5, 1.0),
          icon: _destinationIcon ?? gmap.BitmapDescriptor.defaultMarker,
        ),
        if (widget.storePoint != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('store'),
            position: gmap.LatLng(
              widget.storePoint!.latitude,
              widget.storePoint!.longitude,
            ),
            anchor: const Offset(0.5, 1.0),
            icon: _storeIcon ?? gmap.BitmapDescriptor.defaultMarker,
          ),
        if (boyPoint != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('delivery_boy'),
            position: gmap.LatLng(boyPoint.latitude, boyPoint.longitude),
            rotation: _bearingDegrees(boyPoint, deliveryAddressPoint),
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon:
                _deliveryBoyIcon ??
                gmap.BitmapDescriptor.defaultMarkerWithHue(
                  gmap.BitmapDescriptor.hueGreen,
                ),
          ),
      },
      polylines: {
        if (linePoints.isNotEmpty)
          gmap.Polyline(
            polylineId: const gmap.PolylineId('route'),
            points: linePoints
                .map((p) => gmap.LatLng(p.latitude, p.longitude))
                .toList(),
            color: primaryColor.withValues(alpha: 0.6),
            width: 3,
          ),
      },
    );
  }
}
