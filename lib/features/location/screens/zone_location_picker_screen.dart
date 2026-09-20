import 'package:customer/commons/models/zones_model.dart';
import 'package:customer/commons/utils/location_camera_mixin.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/localization/services/localization_service.dart';
import 'package:customer/commons/models/app_settings_model.dart';
import 'package:customer/features/address/cubit/geocoding_cubit.dart';
import 'package:customer/features/address/widgets/location_confirm_card.dart';
import 'package:customer/features/address/widgets/location_map_view.dart';
import 'package:customer/features/address/models/location_result.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/geo_polygon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';

/// Map pin picker for a delivery zone chosen from [CountryZoneSelector].
/// The zone's `polygon_boundary` is drawn on the map and every pin move is
/// checked against it locally (no `ZoneCubit` API call — the zone is already
/// known). Pops `true` after saving the picked point to [SettingsHiveBox],
/// same contract as `LocationSearchScreen`.
class ZoneLocationPickerScreen extends StatelessWidget {
  final ZonesData zone;

  const ZoneLocationPickerScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GeocodingCubit(),
      child: _ZoneLocationPickerView(zone: zone),
    );
  }
}

class _ZoneLocationPickerView extends StatefulWidget {
  final ZonesData zone;
  const _ZoneLocationPickerView({required this.zone});

  @override
  State<_ZoneLocationPickerView> createState() =>
      _ZoneLocationPickerViewState();
}

class _ZoneLocationPickerViewState extends State<_ZoneLocationPickerView>
    with SingleTickerProviderStateMixin, LocationCameraMixin {
  late List<LatLng> _boundary;
  late LatLng _pickedPoint;
  bool? _isInsideZone;
  bool _isGeocoding = false;
  String _locationTitle = LocalizationService.instance.translate(
    LanguageLabelKeys.loadingAddress,
  );
  String _locationSubtitle = '';
  LocationResult? _pendingResult;

  AppSettingsData? get _settings => SettingsHiveBox.instance.getAppSettings();
  bool get _isGoogle => _settings?.mapProvider == AppConstants.mapProvider;

  @override
  void initState() {
    super.initState();
    _boundary = (widget.zone.polygonBoundary ?? [])
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => LatLng(p.lat!, p.lng!))
        .toList();

    final hive = SettingsHiveBox.instance;
    final storedLat = double.tryParse(hive.userLatitude) ?? 0;
    final storedLng = double.tryParse(hive.userLongitude) ?? 0;
    final storedPoint = (storedLat != 0 && storedLng != 0)
        ? LatLng(storedLat, storedLng)
        : null;
    final centroid = _boundary.length >= 3 ? polygonCentroid(_boundary) : null;

    _pickedPoint = (storedPoint != null && _checkInside(storedPoint) != false)
        ? storedPoint
        : (centroid ?? storedPoint ?? const LatLng(20.5937, 78.9629));
    _isInsideZone = _checkInside(_pickedPoint);

    initLocationCamera(this, onCameraIdle: _handleCameraIdle);

    WidgetsBinding.instance.addPostFrameCallback((_) => _geocode(_pickedPoint));
  }

  @override
  void dispose() {
    disposeLocationCamera();
    super.dispose();
  }

  /// null when there's no boundary data to test against — confirm stays
  /// enabled in that case since we can't verify either way.
  bool? _checkInside(LatLng point) {
    if (_boundary.length < 3) return null;
    return isPointInPolygon(point, _boundary);
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  void _onGoogleMapCreated(gmap.GoogleMapController controller) {
    onGoogleMapCreated(
      controller,
      onReadyWithoutPendingMove: () => _fitBoundaryOnGoogleMap(controller),
    );
  }

  /// Frames the whole zone the way the OSM map does via `initialCameraFit` —
  /// Google's initial camera position only takes a point, so the fit has to
  /// wait for the controller.
  void _fitBoundaryOnGoogleMap(gmap.GoogleMapController controller) {
    final fit = polygonFitBounds(_pickedPoint, _boundary);
    if (fit == null) return;
    // The resulting idle only re-centres the pin; initState already kicked
    // off the geocode for this point.
    skipNextIdleGeocode = true;
    controller.animateCamera(
      gmap.CameraUpdate.newLatLngBounds(
        gmap.LatLngBounds(
          southwest: gmap.LatLng(
            fit.southWest.latitude,
            fit.southWest.longitude,
          ),
          northeast: gmap.LatLng(
            fit.northEast.latitude,
            fit.northEast.longitude,
          ),
        ),
        LocationMapView.boundaryFitPadding,
      ),
    );
  }

  void _handleCameraIdle(LatLng point) {
    if (skipNextIdleGeocode) {
      skipNextIdleGeocode = false;
      setState(() {
        _pickedPoint = point;
        _isInsideZone = _checkInside(point);
      });
      return;
    }
    setState(() {
      _pickedPoint = point;
      _isInsideZone = _checkInside(point);
    });
    _geocode(point);
  }

  void _geocode(LatLng point) {
    setState(() {
      _locationTitle = context.translate(LanguageLabelKeys.loadingAddress);
      _locationSubtitle = '';
      _isGeocoding = true;
    });
    context.read<GeocodingCubit>().geocode(
      latitude: point.latitude.toString(),
      longitude: point.longitude.toString(),
    );
  }

  // ── Current location ──────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() => useCurrentLocation(
    onLocated: (point) async {
      setState(() {
        _pickedPoint = point;
        _isInsideZone = _checkInside(point);
      });
      moveCamera(point, zoom: 15, isGoogle: _isGoogle);
      _geocode(point);
    },
  );

  // ── Confirm ───────────────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    final result =
        _pendingResult ??
        LocationResult(
          latitude: _pickedPoint.latitude,
          longitude: _pickedPoint.longitude,
        );
    final label = result.city.isNotEmpty ? result.city : _locationTitle;
    await SettingsHiveBox.instance.saveUserLocation(
      latitude: result.latitude.toString(),
      longitude: result.longitude.toString(),
      label: label,
      address: _locationSubtitle,
    );
    if (mounted) AppNavigator.pop(context, true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeocodingCubit, GeocodingState>(
      listener: (context, state) {
        if (state is GeocodingLoaded) {
          final r = state.result;
          setState(() {
            _locationTitle = r.city.isNotEmpty
                ? r.city
                : context.translate(LanguageLabelKeys.locationSelected);
            _locationSubtitle = r.formattedAddress;
            _isGeocoding = false;
          });
          _pendingResult = LocationResult(
            latitude: _pickedPoint.latitude,
            longitude: _pickedPoint.longitude,
            city: r.city,
            state: r.state,
            country: r.country,
            pincode: r.postalCode,
            area: r.area,
            road: r.road,
          );
        } else if (state is GeocodingError) {
          setState(() {
            _locationTitle = context.translate(
              LanguageLabelKeys.locationSelected,
            );
            _locationSubtitle =
                '${_pickedPoint.latitude.toStringAsFixed(4)}, ${_pickedPoint.longitude.toStringAsFixed(4)}';
            _isGeocoding = false;
          });
          _pendingResult = LocationResult(
            latitude: _pickedPoint.latitude,
            longitude: _pickedPoint.longitude,
          );
        }
      },
      child: AppScaffold(
        applyBottomInset: false,
        appBar: CustomAppBar(
          title: context.translate(LanguageLabelKeys.setDeliveryLocation),
          onBackPressed: () => AppNavigator.pop(context),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: LocationMapView(
                isGoogle: _isGoogle,
                osmController: osmMapController,
                pickedPoint: _pickedPoint,
                pulseAnimation: pulseAnim,
                onGoogleMapCreated: _onGoogleMapCreated,
                onGoogleCameraMove: onGoogleCameraMove,
                onGoogleCameraIdle: onGoogleCameraIdle,
                boundaryPolygon: _boundary,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LocationConfirmCard(
                title: _locationTitle,
                subtitle: _locationSubtitle,
                isLocating: isLocating,
                confirmLabel: context.translate(LanguageLabelKeys.confirm),
                confirmIsLoading: _isGeocoding,
                confirmDisabled: _isGeocoding,
                isAvailable: _isInsideZone,
                onConfirm: _onConfirm,
                onCurrentLocation: _useCurrentLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
