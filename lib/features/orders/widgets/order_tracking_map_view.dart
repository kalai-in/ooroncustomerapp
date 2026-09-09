import 'package:customer/commons/widgets/app_png_icon.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/configs/app_config.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/features/orders/cubit/road_route_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
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
  gmap.GoogleMapController? _googleController;
  final GlobalKey _destinationIconKey = GlobalKey();

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
    }
    _routeSub = context.read<RoadRouteCubit>().stream.listen((state) {
      if (state is RoadRouteLoaded && state.points != null && mounted) {
        setState(() => _routePoints = state.points);
      }
    });
    final boyPoint = widget.deliveryBoyPoint;
    if (boyPoint != null) {
      _maybeFetchRoute(boyPoint);
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

  /// Snapshots the offscreen destination SVG (built in [build], same asset
  /// and tint as the OSM marker) into a bitmap so Google Maps shows the
  /// matching pin instead of its default red marker.
  Future<void> _captureDestinationIcon() async {
    final boundary =
        _destinationIconKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null || !mounted) return;
    setState(() {
      _destinationIcon = gmap.BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
      );
    });
  }

  @override
  void didUpdateWidget(covariant OrderTrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFittedBounds &&
        oldWidget.deliveryBoyPoint == null &&
        widget.deliveryBoyPoint != null) {
      _fitBounds();
    }
    final boyPoint = widget.deliveryBoyPoint;
    if (boyPoint != null) {
      _maybeFetchRoute(boyPoint);
    }
  }

  /// Re-fetches the road route only if the delivery boy moved far enough
  /// since the last fetch, so the free OSRM demo server isn't hammered on
  /// every GPS tick. Google view skips OSRM entirely and uses the direct
  /// line — no third-party routing dependency needed on that provider.
  void _maybeFetchRoute(LatLng boyPoint) {
    if (isGoogle) return;
    final routedFrom = _routedFrom;
    if (routedFrom != null &&
        Geolocator.distanceBetween(
              routedFrom.latitude,
              routedFrom.longitude,
              boyPoint.latitude,
              boyPoint.longitude,
            ) <
            _routeRefreshMeters) {
      return;
    }
    _routedFrom = boyPoint;
    context.read<RoadRouteCubit>().fetchRoute(boyPoint, deliveryAddressPoint);
  }

  /// Road-snapped points when available, else the direct line as fallback.
  List<LatLng> _polylinePoints(LatLng boyPoint) =>
      _routePoints ?? [boyPoint, deliveryAddressPoint];

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
            top: 60,
            left: 60,
            right: 60,
            bottom: _bottomSheetReserve + 40,
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
    return Stack(
      children: [
        _buildGoogleMap(),
        // Rendered off-screen once so it can be snapshotted into a
        // BitmapDescriptor for the Google marker; never visible to the user.
        Positioned(
          left: -1000,
          top: -1000,
          child: RepaintBoundary(
            key: _destinationIconKey,
            child: AppSvgIcon(
              AssetsConstants.destinationLocationIcon,
              size: 36,
            ),
          ),
        ),
      ],
    );
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
        if (boyPoint != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polylinePoints(boyPoint),
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
              alignment: Alignment.topCenter,
              child: AppSvgIcon(
                AssetsConstants.destinationLocationIcon,
                size: 36,
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
                    size: 40,
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
        if (boyPoint != null)
          gmap.Polyline(
            polylineId: const gmap.PolylineId('route'),
            points: _polylinePoints(boyPoint)
                .map((p) => gmap.LatLng(p.latitude, p.longitude))
                .toList(),
            color: primaryColor.withValues(alpha: 0.6),
            width: 3,
          ),
      },
    );
  }
}
