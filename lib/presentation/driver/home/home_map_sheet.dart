part of 'home.dart';

// Map, location, and sheet presentation for DriverHome.
// Timers and fields stay on the state. Geometry and map controls are unchanged.

/// One size for the floating controls on Home: recenter, safety and the
/// top island.
const double _homeMapButtonSize = 48;
// White island, same family as the reservation popup and the Home sheet.
const Color _islandFg = Color(0xFF111614);
const Color _islandMuted = Color(0xFF5E6461);
const Color _islandShadow = Color(0x38172027);

/// Faces of the top island's screen, in tap order.
enum _IslandFace { hidden, lastTrip, today, history }

const Duration _islandIdleTimeout = Duration(seconds: 5);

/// The whole island, its content included, is drawn at 80 % of its design
/// size.
const double _islandScale = 0.8;

/// Set once the first-launch hint has been shown.
const String _islandHintSeenKey = 'home_island_hint_seen';

/// How long a just-finished trip's money counts as still updating. The
/// demo has no earnings service; a real one would confirm the amount.
const Duration _lastTripSettleTime = Duration(seconds: 4);


extension _HomeMapSheet on _DriverHomeState {
    Future<void> _startDriverLocation({bool moveCamera = false}) async {
      final epoch = ++_locationEpoch;
      if (!_liveVisible) { return; }
      try {
        final position = await _driverLocationService.getCurrentPosition();
        if (!mounted) { return; }
        if (!_liveVisible || epoch != _locationEpoch) { return; }
        _applyDriverLocation(position);
        _listenToDriverLocation();
        if (moveCamera || !_didCenterOnLiveLocation) {
          _didCenterOnLiveLocation = true;
          await _animateToDriverLocation();
        }
      } catch (_) {
        if (!mounted || !_liveVisible || epoch != _locationEpoch) { return; }
        _rebuild(() => _hasLiveDriverLocation = false);
      }
    }
    void _listenToDriverLocation() {
      final epoch = _locationEpoch;
      _driverLocationSubscription?.cancel();
      _driverLocationSubscription = _driverLocationService
          .watchPosition(distanceFilterMeters: 8)
          .listen(
        (location) {
          if (!mounted || !_liveVisible || epoch != _locationEpoch) { return; }
          _applyDriverLocation(location);
          if (!_didCenterOnLiveLocation) {
            _didCenterOnLiveLocation = true;
            unawaited(_animateToDriverLocation());
          }
        },
        onError: (_) {
          if (!mounted || !_liveVisible || epoch != _locationEpoch) { return; }
          _rebuild(() => _hasLiveDriverLocation = false);
        },
      );
    }
    void _applyDriverLocation(DriverLocation location) {
      if (!mounted || !_liveVisible) { return; }
      if (!location.isDisplayableAt(DateTime.now())) {
        _rebuild(() => _hasLiveDriverLocation = false);
        return;
      }

      final next = location.point.toLatLng();
      _cameraLocation = location;
      final heading = location.courseOr(_driverHeading);
      _rebuild(() {
        _driverPosition = next;
        _driverHeading = heading;
        _hasLiveDriverLocation = location.isUsableAt(DateTime.now());
        _markers = {
          Marker(
            markerId: const MarkerId('driver_location'),
            position: next,
            infoWindow: const InfoWindow(title: 'Driver camera vehicle'),
            icon: _driverVehicleIcon,
            flat: true,
            anchor: MoveraVehicleMarker.anchor,
            rotation: _driverHeading,
            zIndexInt: 12,
          ),
        };
      });

      if (_destinationModeActive) {
        _refreshDestinationRoadRoute();
      }
      unawaited(_animateToDriverLocation());
    }
    Future<void> _prepareDriverVehicleMarker() async {
      final icon = await MoveraVehicleMarker.createIcon();
      if (!mounted) { return; }
      _rebuild(() {
        _driverVehicleIcon = icon;
        _markers = {
          Marker(
            markerId: const MarkerId('driver_location'),
            position: _driverPosition,
            infoWindow: const InfoWindow(title: 'Driver camera vehicle'),
            icon: _driverVehicleIcon,
            flat: true,
            anchor: MoveraVehicleMarker.anchor,
            rotation: _driverHeading,
            zIndexInt: 12,
          ),
        };
      });
    }
    Future<void> _animateToDriverLocation() async {
      final location = _cameraLocation;
      if (location == null || !_liveVisible) { return; }
      _camera.update(location: location,
        route: _destinationModeActive ? _cameraRoute : null,
        navigating: false);
    }
    Future<void> _zoomToDriverLocation() async {
      _camera.recenter();
      await _startDriverLocation();
      if (mounted) { await _animateToDriverLocation(); }
    }
    Widget _buildDriverLocationButton() {
      return PointerInterceptor(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MapControlButton(
              key: const ValueKey<String>('driver-location-zoom'),
              tooltip: 'Recenter',
              size: _homeMapButtonSize,
              fill: MapControlButton.recenterBlue,
              onTap: _zoomToDriverLocation,
              child: SvgPicture.asset(AppAssets.mapRecenter, width: 22, height: 22),
            ),
            // Live GPS indicator.
            Positioned(
              right: 2,
              top: 2,
              child: IgnorePointer(
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _hasLiveDriverLocation
                        ? const Color(0xFF2FBE7B)
                        : const Color(0xFFAAB2B6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    void _loadMarkers() {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverPosition,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    double _homeMapObscuredBottom(BuildContext context) {
      if (_outsideRadarOffer != null) {
        final height = MediaQuery.sizeOf(context).height;
        return math.max(320.0, height * 0.48);
      }
      if (_isDirectOfferRoutePreview || _radarHomeOffers.isNotEmpty) {
        return 188;
      }
      return MoveraSheetMetrics.collapsedHeight;
    }
    Future<void> _previewDirectOfferRoute(
      LatLng pickup,
      LatLng dropoff,
    ) async {
      if (!mounted) { return; }
      final generation = _mapPreviews.begin();
      bool isCurrent() => mounted && _mapPreviews.owns(generation) &&
          _isDirectOfferRoutePreview;

      _rebuild(() {
        _isDirectOfferRoutePreview = true;
        _directOfferRouteMarkers = {
          Marker(
            markerId: const MarkerId('radar_pickup'),
            position: pickup,
            infoWindow: const InfoWindow(title: 'Pickup'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: const MarkerId('radar_dropoff'),
            position: dropoff,
            infoWindow: const InfoWindow(title: 'Drop-off'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        };
        _directOfferRoutePolylines = <Polyline>{};
      });

      final roadPoints = <LatLng>[];

      if (_hasLiveDriverLocation) {
        try {
          final approach = await _roadRouteService.drivingRoute(
            origin: GeoPointMaps.fromLatLng(_driverPosition),
            destination: GeoPointMaps.fromLatLng(pickup),
          );
          if (!isCurrent()) return;
          roadPoints.addAll(approach.latLngPoints);
        } catch (_) {
          if (!isCurrent()) return;
        }
      }

      if (!isCurrent()) return;
      try {
        final trip = await _roadRouteService.drivingRoute(
          origin: GeoPointMaps.fromLatLng(pickup),
          destination: GeoPointMaps.fromLatLng(dropoff),
        );
        if (!isCurrent()) return;
        if (roadPoints.isNotEmpty &&
            trip.latLngPoints.isNotEmpty &&
            roadPoints.last == trip.latLngPoints.first) {
          roadPoints.addAll(trip.latLngPoints.skip(1));
        } else {
          roadPoints.addAll(trip.latLngPoints);
        }
      } catch (_) {
        if (!isCurrent()) return;
      }

      // The route request crossed an async gap: prove context is still mounted.
      if (!mounted || !isCurrent()) return;

      final media = MediaQuery.of(context);
      final insets = MapOverlayInsets.forHome(
        safeTop: media.padding.top,
        obscuredBottom: _homeMapObscuredBottom(context),
        hasTopBanner: false,
      );

      if (roadPoints.length >= 2) {
        _rebuild(() {
          _directOfferRoutePolylines = {
            Polyline(
              polylineId: const PolylineId('direct_offer_road_route'),
              points: roadPoints,
              color: DriverRouteStyle.color,
              width: DriverRouteStyle.width,
              geodesic: false,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      }

      if (!isCurrent()) return;
      await _fitPoints(
        MapPreviewGeneration.framingPoints(pickup, dropoff, roadPoints),
        padding: insets.boundsPadding,
      );
    }
    Future<void> _fitPoints(List<LatLng> points, {double padding = 80}) async {
      await _camera.preview(points.map(GeoPointMaps.fromLatLng).toList(),
        padding: padding);
    }
    void _openDestinationModePicker() {
      _closeHomeFloatingPopupsForSheet();
      if (_mainPanelPosition > 0.001 || isPanelOpen) {
        _panelController.close();
      }
      if (!mounted) { return; }

      Navigator.of(context)
          .push<DriverDestinationResult>(
            MaterialPageRoute(
              builder: (_) => const DriverDestinationPicker(),
            ),
          )
          .then((result) {
            if (!mounted || result == null) { return; }
            _activateDestinationMode(result);
          });
    }
    Future<void> _activateDestinationMode(
      DriverDestinationResult result,
    ) async {
      final destination = result.position;
      _mapPreviews.cancel(); // An old offer cannot reclaim the destination map.
      _destinationRoadRequests.cancel();
      _cameraRoute = null;
      _rebuild(() {
        _destinationModeActive = true;
        _destinationAddress = result.address;
        _destinationPosition = destination;
        _destinationRouteMarkers = {
          Marker(
            markerId: const MarkerId('destination_mode_target'),
            position: destination,
            infoWindow: InfoWindow(title: result.address),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        };
        _destinationRoutePolylines = <Polyline>{};
      });

      await _refreshDestinationRoadRoute();
      await _fitDestinationRoute();
      _HomeOfferRadar(this)._maybeShowSoonReservation();

      if (!_isOnline && !_isGoingOnline) {
        _goOnline();
      }
    }
    Future<void> _refreshDestinationRoadRoute() =>
        _destinationRoadRefresh.request(_fetchLatestDestinationRoadRoute);

    Future<void> _fetchLatestDestinationRoadRoute() async {
      final generation = _destinationRoadRequests.begin();
      final destination = _destinationPosition;
      if (destination == null || !_hasLiveDriverLocation) {
        if (mounted && _destinationRoadRequests.owns(generation)) {
          _cameraRoute = null;
          _rebuild(() => _destinationRoutePolylines = <Polyline>{});
        }
        return;
      }

      try {
        final route = await _roadRouteService.drivingRoute(
          origin: GeoPointMaps.fromLatLng(_driverPosition),
          destination: GeoPointMaps.fromLatLng(destination),
        );
        if (!mounted || !_destinationModeActive ||
            _destinationPosition != destination ||
            !_destinationRoadRequests.owns(generation)) { return; }

        _cameraRoute = route;
        unawaited(_animateToDriverLocation());

        _rebuild(() {
          _destinationRoutePolylines = {
            Polyline(
              polylineId: const PolylineId('destination_mode_road_route'),
              points: route.latLngPoints,
              color: DriverRouteStyle.color,
              width: DriverRouteStyle.width,
              geodesic: false,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      } catch (_) {
        if (!mounted || !_destinationModeActive ||
            _destinationPosition != destination ||
            !_destinationRoadRequests.owns(generation)) { return; }
        _cameraRoute = null;
        _rebuild(() => _destinationRoutePolylines = <Polyline>{});
      }
    }
    Future<void> _fitDestinationRoute() async {
      final destination = _destinationPosition;
      if (destination == null || _mapController == null) { return; }
      final generation = _mapPreviews.begin();

      final routePoints = _destinationRoutePolylines.isEmpty
          ? <LatLng>[_driverPosition, destination]
          : _destinationRoutePolylines.first.points;

      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || !_destinationModeActive ||
          _destinationPosition != destination || _mapController == null ||
          !_mapPreviews.owns(generation)) { return; }

      await _fitPoints(routePoints, padding: 74);
    }
    void _endDestinationMode() {
      if (!_destinationModeActive) { return; }
      _mapPreviews.cancel();
      _destinationRoadRequests.cancel();
      _destinationRoadRefresh.cancelPending();
      _cameraRoute = null;
      _camera.endPreview();
      _rebuild(() {
        _destinationModeActive = false;
        _destinationAddress = null;
        _destinationPosition = null;
        _destinationRouteMarkers = {};
        _destinationRoutePolylines = {};
      });
    }
    void _flashSheet(Color color) {
      _sheetToneTimer?.cancel();
      _rebuild(() {
        _sheetTone = color;
        _sheetToneShown = true;
      });
      _sheetToneTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) { return; }
        _rebuild(() => _sheetToneShown = false);
      });
    }
    Widget _inactiveSheetFace() {
      return PhysicalShape(
        clipper: const RadarSheetClipper(
          notchWidth: 126,
          notchDepth: 58,
          cornerRadius: 24,
        ),
        color: const Color(0xFF8E2E28),
        elevation: 8,
        shadowColor: const Color(0x3311181C),
        clipBehavior: Clip.antiAlias,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 62, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _openActivationDocuments,
                  child: const Text('Contact support',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: _skipActivationDemo,
                  child: const Text(
                    'Skip demo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    void openDestinationPanel() {
      if (!mounted) { return; }
      _destinationOpenTimer?.cancel();
      _rebuild(() => hideMainPanel = true);
      _destinationOpenTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) { return; }
        if (!_driverSession.isOnline || !_destinationPanelController.isAttached) {
          _rebuild(() => hideMainPanel = false);
          return;
        }
        _destinationPanelController.open();
      });
    }
    void _setMapGesturesBlocked(bool value) {
      if (!mounted || _blockMapGestures == value) { return; }
      _rebuild(() {
        _blockMapGestures = value;
      });
    }
    void _onSheetPointerDown(PointerDownEvent event) {
      _sheetTrace.down();
      _sheetPointerActive = true;
      _sheetPointerLastY = event.position.dy;
      _sheetPointerLastMs = DateTime.now().millisecondsSinceEpoch;
      _sheetPointerVelocity = 0;
      _sheetPointerTravel = 0;
      _sheetPointerStartPos =
          _panelController.isAttached ? _panelController.panelPosition : 0;
      _homeSheetPositionGuardTimer?.cancel();
      _snapSheet.stopSpring();
      _setMapGesturesBlocked(true);
    }
    void _onSheetPointerMove(PointerEvent event) {
      _trackSheetPointer(event);
    }
    void _onSheetPointerEnd(PointerEvent event) {
      _sheetTrace.up(_sheetPointerVelocity);
      _trackSheetPointer(event);
      _sheetPointerActive = false;
      if (!_panelController.isAttached) { return; }
      // A drag settles at once toward where the finger went, with the same
      // spring as a tap; no late correction afterwards.
      if (_sheetPointerTravel > 6) {
        unawaited(_snapHomeSheet(velocity: _sheetPointerVelocity));
      } else if (_panelController.panelPosition <= 0.001) {
        _setMapGesturesBlocked(false);
      }
    }
    /// Safety net only: if something outside a drag leaves the sheet
    /// between stages (e.g. a cancelled animation), settle it.
    void _scheduleHomeSheetPositionGuard({
      Duration delay = const Duration(milliseconds: 180),
    }) {
      _homeSheetPositionGuardTimer?.cancel();
      _homeSheetPositionGuardTimer = Timer(delay, () {
        if (!mounted ||
            _outsideRadarOffer != null ||
            _sheetPointerActive ||
            _snapSheet.isSpringing ||
            !_panelController.isAttached) {
          return;
        }

        final position = _panelController.panelPosition.clamp(0.0, 1.0);
        final snap = _homeSnapPoint(context);
        final nearestDistance = math.min(
          position.abs(),
          math.min((position - snap).abs(), (1 - position).abs()),
        );

        if (nearestDistance <= 0.025) { return; }
        unawaited(_snapHomeSheet(velocity: 0));
      });
    }
    Future<void> _closeDriverSheet() async {
      await _springPanelTo(0);
    }
    double _homeSnapPoint(BuildContext context) {
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final maxHeight = _homeExpandedHeight(context);
      final middleHeight = MoveraSheetMetrics.middleHeight(viewportHeight);
      final span = maxHeight - MoveraSheetMetrics.collapsedHeight;
      if (span <= 0) { return 0.5; }
      return ((middleHeight - MoveraSheetMetrics.collapsedHeight) / span)
          .clamp(0.08, 0.92);
    }
    double _homeExpandedHeight(BuildContext context) {
      return MediaQuery.sizeOf(context).height * _DriverHomeState._homeExpandedFraction;
    }
    void _trackSheetPointer(PointerEvent event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_sheetPointerLastMs != 0) {
        final dt = math.max(1, now - _sheetPointerLastMs);
        _sheetPointerVelocity = (event.position.dy - _sheetPointerLastY) / dt * 1000;
      }
      _sheetPointerTravel += (event.position.dy - _sheetPointerLastY).abs();
      _sheetPointerLastY = event.position.dy;
      _sheetPointerLastMs = now;
    }
    Future<void> _snapHomeSheet({double? velocity}) async {
      if (!_panelController.isAttached) { return; }
      _snapSheet.rangePx =
          _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
      final snap = _homeSnapPoint(context);
      final target = MoveraSheetMetrics.directionalTarget(
        start: _sheetPointerStartPos,
        position: _panelController.panelPosition.clamp(0.0, 1.0),
        velocityPxPerSec: velocity ?? _sheetPointerVelocity,
        snap: snap,
      );
      if ((target - _lastSnapHapticAt).abs() > 0.04) {
        unawaited(HapticFeedback.lightImpact());
        _lastSnapHapticAt = target;
      }
      await _snapSheet.springTo(
        target,
        velocityPxPerSec: velocity ?? _sheetPointerVelocity,
      );
    }
    void _settleHomeSheet({double? velocity}) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { return; }
        unawaited(_snapHomeSheet(velocity: velocity));
      });
    }
    Future<void> _springPanelTo(
      double target, {
      double velocityPxPerSec = 0,
    }) {
      _snapSheet.rangePx =
          _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
      return _snapSheet.springTo(target, velocityPxPerSec: velocityPxPerSec);
    }
    Widget _buildRadarMapBackdrop() {
      return SizedBox.expand(
        child: CustomGoogleMap(
          initialPosition: _DriverHomeState._initialPosition,
          markers: _markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          trafficEnabled: true,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          onUserGesture: _camera.userGesture,
          onCameraIdle: () => _cameraPort?.onIdle(),
          onCameraMove: (position) => _cameraPort?.onMove(position),
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _cameraPort = GoogleDriverCameraPort(controller,
                        onStatus: (status) {
                          if (status != null && mounted && ModalRoute.of(context)?.isCurrent == true) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status),
                              action: SnackBarAction(label: 'Retry', onPressed: _camera.recenter)));
                          }
                        },
              initialPosition: _DriverHomeState._initialPosition,
              reducedMotion: MediaQuery.disableAnimationsOf(context));
            _camera.attach(_cameraPort!);
          },
          onTap: (LatLng position) {},
        ),
      );
    }
    Widget body({bool isDestinationPanel = false}) {
      final viewport = MediaQuery.sizeOf(context);
      final viewportWidth = viewport.width;

      return SizedBox(
        height: viewport.height,
        width: viewportWidth,
        child: Stack(
          children: [
            CustomGoogleMap(
              initialPosition: _DriverHomeState._initialPosition,
              markers: {
                ..._markers,
                ..._destinationRouteMarkers,
                ..._directOfferRouteMarkers,
              },
              polylines: {
                ..._destinationRoutePolylines,
                ..._directOfferRoutePolylines,
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: true,
              onUserGesture: _camera.userGesture,
              onCameraIdle: () => _cameraPort?.onIdle(),
              onCameraMove: (position) => _cameraPort?.onMove(position),
              buildingsEnabled: true,
              indoorViewEnabled: false,
              mapType: MapType.normal,
              padding: MapOverlayInsets.forHome(
                safeTop: MediaQuery.paddingOf(context).top,
                obscuredBottom: _homeMapObscuredBottom(context),
                hasTopBanner: false,
              ).edgeInsets,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _cameraPort = GoogleDriverCameraPort(controller,
                        onStatus: (status) {
                          if (status != null && mounted && ModalRoute.of(context)?.isCurrent == true) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status),
                              action: SnackBarAction(label: 'Retry', onPressed: _camera.recenter)));
                          }
                        },
                  initialPosition: _DriverHomeState._initialPosition,
                  reducedMotion: MediaQuery.disableAnimationsOf(context));
                _camera.attach(_cameraPort!);
                if (_hasLiveDriverLocation) {
                  unawaited(_animateToDriverLocation());
                }
              },
              onTap: (LatLng position) {},
            ),
            isDestinationPanel
                ? Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      AppAssets.destinationSelected,
                      height: ResSize.h * 241,
                    ),
                  )
                : SizedBox(),
            isDestinationPanel
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 140, right: 30),
                      child: InkWell(
                        onTap: () {
                          showSafetyToolKitSheet(context);
                        },
                        child: Image.asset(
                          AppAssets.direction,
                          height: ResSize.h * 90,
                        ),
                      ),
                    ),
                  )
                : SizedBox(),

            Visibility(
              visible: true,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResSize.h * 55,
                  horizontal: screenHorizPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The top island is drawn above the scrim, further down.
                    const SizedBox(height: _homeMapButtonSize),
                    if (_destinationModeActive && !isDestinationPanel)
                      Padding(
                        padding: EdgeInsets.only(top: ResSize.h * 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: PointerInterceptor(
                            child: Material(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor:
                                  const Color(0xFF172027).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                key: const ValueKey<String>(
                                  'destination-mode-home-tab',
                                ),
                                onTap: _fitDestinationRoute,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: ResSize.w * 252,
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                    ResSize.w * 11,
                                    ResSize.h * 8,
                                    ResSize.w * 8,
                                    ResSize.h * 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: ResSize.h * 30,
                                        width: ResSize.h * 30,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F5F6),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE6E8EA),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.near_me_rounded,
                                          size: 16,
                                          color: Color(0xFF1C242C),
                                        ),
                                      ),
                                      SizedBox(width: ResSize.w * 8),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'On your way',
                                              style: TextStyle(
                                                color: Color(0xFF1C242C),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            Text(
                                              _destinationShortLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF252E3A),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: ResSize.w * 6),
                                      InkWell(
                                        key: const ValueKey<String>(
                                          'destination-mode-end',
                                        ),
                                        onTap: _endDestinationMode,
                                        borderRadius: BorderRadius.circular(15),
                                        child: const SizedBox(
                                          height: 28,
                                          width: 28,
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 17,
                                            color: Color(0xFF7D898F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (isDestinationPanel)
                      Padding(
                        padding: EdgeInsets.only(top: ResSize.h * 12),
                        child: InAirportQueue(),
                      ),
                  ],
                ),
              ),
            ),

            if (!isDestinationPanel && _outsideRadarOffer == null)
              ValueListenableBuilder<double>(
                valueListenable: _panelSlidePosition,
                builder: (context, panelPosition, child) {
                  final maxPanelHeight = _homeExpandedHeight(context);
                  const minPanelHeight = MoveraSheetMetrics.collapsedHeight;
                  final currentPanelHeight =
                      minPanelHeight +
                      ((maxPanelHeight - minPanelHeight) * panelPosition);

                  // The 104px radar remains locked into the sheet's centre notch.
                  // At the collapsed position this resolves to the existing
                  // offline position (bottom: 58), and it follows the sheet
                  // continuously while the driver drags it.
                  final radarBottom = currentPanelHeight - 50;

                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: radarBottom,
                    child: Center(
                      child: _radarDragToSheet(
                        child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        reverseDuration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final scale = Tween<double>(
                            begin: 0.97,
                            end: 1.0,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<String>(
                            _isOnline
                                ? 'radar-online'
                                : _isGoingOnline
                                ? 'radar-connecting'
                                : 'radar-offline',
                          ),
                          child: _isOnline
                              ? _buildTripRadarButton()
                              : _isGoingOnline
                              ? _buildGoingOnlineButton()
                              : _buildGoOnlineButton(),
                        ),
                      ),
                      ),
                    ),
                  );
                },
              ),
            if (!isDestinationPanel)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: 138,
                child: _buildDriverLocationButton(),
              ),
            if (!isDestinationPanel)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: 16,
                bottom: 138,
                child: MapControlButton(
                  key: const ValueKey<String>('home-safety-button'),
                  tooltip: 'Safety toolkit',
                  size: _homeMapButtonSize,
                  onTap: () => showSafetyToolKitSheet(context),
                  child: SvgPicture.asset(AppAssets.mapSafety, width: 24, height: 24),
                ),
              ),
            if (!isDestinationPanel &&
                _mainPanelPosition <= 0.04 &&
                _outsideRadarOffer != null &&
                _radarHomeOffers.isEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: _HomeOfferRadar(this)._buildOutsideRadarOfferCard(_outsideRadarOffer!),
              ),
            if (!isDestinationPanel &&
                _mainPanelPosition <= 0.04 &&
                _outsideRadarOffer == null &&
                _radarHomeOffers.isNotEmpty)
              Positioned(
                left: 14,
                width: math.max(0, viewportWidth - 28),
                // Clears the safety and recenter buttons below it.
                bottom: 138 + _homeMapButtonSize + 12,
                child: _HomeOfferRadar(this)._buildRadarOffersTray(),
              ),
            if (!isDestinationPanel) ...[
              // As high as the phone allows: tucked just under the clock
              // and notch (the safe area keeps a few spare pixels below).
              Positioned(
                left: 0,
                right: 0,
                top: math.max(MediaQuery.paddingOf(context).top - 4, 10.0),
                // Sliding the sheet up from the middle stage pushes the
                // island off the top; it comes back as the sheet goes down.
                child: ValueListenableBuilder<double>(
                  valueListenable: _panelSlidePosition,
                  child: Transform.scale(
                    scale: _islandScale,
                    alignment: Alignment.topCenter,
                    child: _buildTopIsland(viewportWidth / _islandScale),
                  ),
                  builder: (context, panelPosition, island) {
                    final snap = _homeSnapPoint(context);
                    final push = Curves.easeIn.transform(
                      ((panelPosition - snap) / (1 - snap)).clamp(0.0, 1.0),
                    );
                    final lift = MediaQuery.paddingOf(context).top +
                        DigitalIslandParts.height + 24;
                    return IgnorePointer(
                      key: const ValueKey<String>('home-island-push'),
                      ignoring: push > 0.5,
                      child: Opacity(
                        opacity: 1 - push,
                        child: Transform.translate(
                          offset: Offset(0, -lift * push),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: island,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

          ],
        ),
      );
    }
    /// White island at the top of Home: menu, today's earnings and
    /// destination search. The earnings are hidden until tapped; a second
    /// tap grows the island into the full Today details.
    /// Black island drawn like a small live screen: the blue arrow opens
    /// Destination, the middle cycles through the money faces, the menu
    /// sits on the right.
    Widget _buildTopIsland(double viewportWidth) {
      const height = DigitalIslandParts.height;
      // At launch the island is small (menu and arrow), then grows; a
      // message widens it and moves the menu and arrow aside.
      final message = _islandMessage;
      final maxWidth = viewportWidth - 32;
      // A message sizes the island to its words (never taller): the normal
      // size for short words, a little longer for longer ones. 14 + 14 for the
      // tucked sides, 2 for the border and some air on both ends.
      final width = message != null
          ? (DigitalMessageFace.widthFor(context, message.title) +
                    14 + 14 + 2 + 36)
                .clamp(math.min(244.0, maxWidth), math.min(244.0 * 1.15, maxWidth))
                .toDouble()
          : _islandWake >= 1
              ? math.min(maxWidth, 244.0)
              : 112.0;
      Widget side(Widget button) => AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: message == null ? 54 : 14,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 54,
                maxWidth: 54,
                child: IgnorePointer(
                  ignoring: message != null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: message == null ? 1 : 0,
                    child: button,
                  ),
                ),
              ),
            ),
          );
      return PointerInterceptor(
        child: DigitalIslandShell(
          width: width,
          height: height,
          // Online, the driver is on the road: no light passing over it.
          calm: _isOnline,
          // Every size change, out and back, glides with a soft spring.
          duration: const Duration(milliseconds: 680),
          curve: Curves.easeOutCubic,
          child: Row(
            children: [
              side(Builder(
                builder: (context) => Tooltip(
                  message: 'Menu',
                  child: InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: SizedBox(
                      width: 54,
                      height: height,
                      child: DigitalIslandParts.menuIcon(),
                    ),
                  ),
                ),
              )),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (_islandFace == _IslandFace.history &&
                        (details.primaryVelocity ?? 0).abs() > 80) {
                      _openRideHistoryFromIsland();
                    }
                  },
                  child: InkWell(
                    key: const ValueKey<String>('last-trip-launcher'),
                    onTap: message != null
                        ? () => _onIslandMessageTap(message)
                        : _onIslandEarningsTap,
                    // Holding the middle goes straight to Ride history.
                    onLongPress: message != null
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _openRideHistoryFromIsland();
                          },
                    child: SizedBox(
                      height: height,
                      child: DigitalFaceSwitcher(
                        child: message != null
                            ? _islandMessageView(message)
                            : _islandWake >= 2
                                ? _islandFaceView()
                                : const SizedBox(
                                    key: ValueKey<String>('island-asleep'),
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
              side(Tooltip(
                message: 'Search destination',
                child: InkWell(
                  key: const ValueKey<String>('destination-mode-open'),
                  onTap: _openDestinationModePicker,
                  child: const SizedBox(
                    width: 54,
                    height: height,
                    child: DigitalIslandParts.searchIcon,
                  ),
                ),
              )),
            ],
          ),
        ),
      );
    }
    Widget _islandFaceView() {
      switch (_islandFace) {
        case _IslandFace.hidden:
          return DigitalIslandParts.hiddenFace();
        case _IslandFace.lastTrip:
          if (_lastTripSettling) {
            return const DigitalUpdatingFace(
              key: ValueKey<String>('island-updating'),
            );
          }
          return DigitalIslandParts.amountFace(
              'island-last-trip', 'LAST TRIP', _lastTripFareLabel);
        case _IslandFace.today:
          return DigitalIslandParts.amountFace(
              'island-today', 'TODAY', DigitalIslandParts.sampleToday);
        case _IslandFace.history:
          return DigitalIslandParts.historyFace();
      }
    }
    Widget _islandMessageView(IslandMessage message) {
      final (color, icon) = DigitalIslandParts.toneLook(message.tone);
      return DigitalMessageFace(
        key: ValueKey<String>('island-message-$_islandMessageSeq'),
        title: message.title,
        color: color,
        icon: icon,
        pulse: message.live,
      );
    }
    /// A posted message: show it now if the screen is free, or replace an
    /// outdated one of the same group.
    void _onIslandMessagesChanged() {
      if (!mounted) { return; }
      final current = _islandMessage;
      final next = IslandMessages.peek();
      if (current != null &&
          next != null &&
          current.group != null &&
          current.group == next.group) {
        _islandMessageTimer?.cancel();
        _islandMessage = null;
      }
      _showNextIslandMessage();
    }
    void _showNextIslandMessage() {
      if (!mounted || _islandMessage != null) { return; }
      final next = IslandMessages.take();
      if (next == null) { return; }
      _islandWakeTimer?.cancel();
      _rebuild(() {
        _islandWake = 2;
        _islandMessage = next;
        _islandMessageSeq++;
      });
      _islandMessageTimer?.cancel();
      _islandMessageTimer = Timer(next.priority.duration, _endIslandMessage);
    }
    void _endIslandMessage() {
      _islandMessageTimer?.cancel();
      if (!mounted) { return; }
      _rebuild(() => _islandMessage = null);
      _showNextIslandMessage();
    }
    /// A saved-trip problem: a heads-up on the island and a sheet that
    /// stays until the driver acts, since a tap only closes the island.
    void _tripProblem(IslandMessage notice, String message,
        {String action = 'Retry'}) {
      IslandMessages.show(notice);
      unawaited(showTripProblemSheet(
        context,
        title: notice.title,
        message: message,
        actionLabel: action,
        onAction: () => unawaited(_restoreActiveRideIfNeeded()),
      ));
    }
    /// Tapping a message closes it; only the first-launch hint also acts.
    void _onIslandMessageTap(IslandMessage message) {
      _endIslandMessage();
      message.onTap?.call();
    }
    /// Hidden total → last trip → today's total → Ride history → hidden.
    /// Left untouched for 5 s, the island goes back to the hidden total.
    void _onIslandEarningsTap() {
      if (_islandWake < 2) {
        // A tap during the launch animation just finishes it.
        _islandWakeTimer?.cancel();
        _rebuild(() => _islandWake = 2);
        return;
      }
      HapticFeedback.selectionClick();
      _rebuild(() {
        _islandFace = _IslandFace
            .values[(_islandFace.index + 1) % _IslandFace.values.length];
      });
      _restartIslandIdle();
    }
    void _restartIslandIdle() {
      _islandIdleTimer?.cancel();
      if (_islandFace == _IslandFace.hidden) { return; }
      _islandIdleTimer = Timer(_islandIdleTimeout, () {
        if (!mounted || _islandFace == _IslandFace.hidden) { return; }
        _rebuild(() => _islandFace = _IslandFace.hidden);
      });
    }
    /// Launch: small island, it grows after a beat, then its screen turns on.
    void _startIslandWake() {
      _islandWakeTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) { return; }
        _rebuild(() => _islandWake = 1);
        _islandWakeTimer = Timer(const Duration(milliseconds: 560), () {
          if (!mounted) { return; }
          _rebuild(() => _islandWake = 2);
          unawaited(_showIslandHintOnce());
        });
      });
      _scheduleLastTripSettle();
    }
    /// First launch only: tell the driver the middle shows the earnings.
    Future<void> _showIslandHintOnce() async {
      if (!DriverRuntimeConfig.current.islandHint) { return; }
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || (prefs.getBool(_islandHintSeenKey) ?? false)) { return; }
      await prefs.setBool(_islandHintSeenKey, true);
      IslandMessages.show(HomeIslandNotices.earningsHint(_onIslandEarningsTap));
    }
    /// A trip that just ended still has its money updating.
    bool get _lastTripSettling {
      final pending = _lastTripPendingId;
      return pending != null && pending == _waybills.last?.tripId;
    }
    String get _lastTripFareLabel {
      final fare = _waybills.last?.fare;
      if (fare == null || !fare.contains(RegExp(r'\d'))) { return DigitalIslandParts.sampleLastTrip; }
      return fare;
    }
    void _onLastTripChanged() {
      if (!mounted) { return; }
      _rebuild(() {});
      _scheduleLastTripSettle();
    }
    void _scheduleLastTripSettle() {
      _lastTripSettleTimer?.cancel();
      final last = _waybills.last;
      final left = last == null
          ? Duration.zero
          : _lastTripSettleTime - DateTime.now().difference(last.issuedAt);
      if (left <= Duration.zero) {
        _lastTripPendingId = null;
        return;
      }
      _lastTripPendingId = last!.tripId;
      _lastTripSettleTimer = Timer(left, () {
        if (!mounted) { return; }
        // The money is in: show it, and give the driver 5 s to read it.
        _rebuild(() => _lastTripPendingId = null);
        if (_islandFace == _IslandFace.lastTrip) { _restartIslandIdle(); }
      });
    }
    void _openRideHistoryFromIsland() {
      _islandIdleTimer?.cancel();
      _rebuild(() => _islandFace = _IslandFace.hidden);
      pushSingle(
        context,
        MaterialPageRoute<void>(builder: (_) => const DriverRideHistory()),
      );
    }
    void _onRadarSheetDragStart(DragStartDetails details) {
      _sheetPointerStartPos =
          _panelController.isAttached ? _panelController.panelPosition : 0;
    }
    void _onRadarSheetDragUpdate(DragUpdateDetails details) {
      if (!_panelController.isAttached) { return; }
      _snapSheet.stopSpring();
      final range = _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
      if (range <= 0) { return; }
      final next = (_panelController.panelPosition - details.delta.dy / range)
          .clamp(0.0, 1.0);
      _panelController.panelPosition = next;
    }
    void _onRadarSheetDragEnd(DragEndDetails details) {
      _settleHomeSheet(velocity: details.primaryVelocity ?? 0);
    }
    Widget _radarDragToSheet({required Widget child}) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onRadarSheetDragStart,
        onVerticalDragUpdate: _onRadarSheetDragUpdate,
        onVerticalDragEnd: _onRadarSheetDragEnd,
        child: child,
      );
    }
    void _closeHomeFloatingPopupsForSheet() {
      if (!showRideRequests &&
          !_isDirectOfferRoutePreview) {
        return;
      }

      _mapPreviews.cancel();
      _camera.endPreview();
      _rebuild(() {
        showRideRequests = false;
        _isDirectOfferRoutePreview = false;
        _directOfferRouteMarkers = {};
        _directOfferRoutePolylines = {};
      });
    }
    bool _isVersionNewer(String candidate, String current) {
      List<int> parse(String value) {
        return value
            .split('.')
            .map((part) => int.tryParse(part) ?? 0)
            .toList(growable: true);
      }

      final a = parse(candidate);
      final b = parse(current);
      final length = math.max(a.length, b.length);

      while (a.length < length) {
        a.add(0);
      }
      while (b.length < length) {
        b.add(0);
      }

      for (var index = 0; index < length; index++) {
        if (a[index] > b[index]) { return true; }
        if (a[index] < b[index]) { return false; }
      }

      return false;
    }
    Future<void> _maybeShowAppUpdatePrompt() async {
      if (_updatePromptShown || !mounted) { return; }

      final update = _adminHomeConfig.update;
      if (!update.enabled ||
          !_isVersionNewer(update.latestVersion, _DriverHomeState._currentAppVersion)) {
        return;
      }

      _updatePromptShown = true;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: !update.mandatory,
        enableDrag: !update.mandatory,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEDB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: Color(0xFF19865C),
                    size: 27,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  update.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  update.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7D898F),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version ${update.latestVersion}',
                  style: const TextStyle(
                    color: Color(0xFF19865C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () async {
                      final rawUrl = update.updateUrl;
                      if (rawUrl == null || rawUrl.isEmpty) {
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        if (!mounted) { return; }
                        IslandMessages.show(HomeIslandNotices.updateUnavailable);
                        return;
                      }

                      final uri = Uri.tryParse(rawUrl);
                      if (uri != null) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF252E3A),
                      foregroundColor: _islandFg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      update.actionLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (!update.mandatory) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(
                      update.dismissLabel,
                      style: const TextStyle(
                        color: Color(0xFF66737A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }
    Future<void> _openDriverEvent(DriverEventConfig event) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: _islandShadow,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            initialChildSize: 0.76,
            minChildSize: 0.52,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FBFA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.72,
                            child: Image.network(
                              event.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8EFEC),
                                child: const MoveraLineIcon(
                                  mark: MoveraMark.calendar,
                                  color: Color(0xFF1C242C),
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: _eventChip(event.category),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Color(0xFF252E3A),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _eventDetailRow(
                            mark: MoveraMark.calendar,
                            title: event.dateLabel,
                            subtitle: event.timeLabel,
                          ),
                          const SizedBox(height: 10),
                          _eventDetailRow(
                            mark: MoveraMark.place,
                            title: event.location,
                            subtitle: 'Area',
                          ),
                          const SizedBox(height: 18),
                          Text(
                            event.description,
                            style: const TextStyle(
                              color: Color(0xFF58656C),
                              fontSize: 12,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252E3A),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    MoveraLineIcon(
                                      mark: MoveraMark.bolt,
                                      color: _islandFg,
                                      size: 19,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Best time to be online',
                                      style: TextStyle(
                                        color: _islandFg,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.recommendedWindow,
                                  style: const TextStyle(
                                    color: _islandFg,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  event.demandLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF9ED9BD),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.driverNote,
                                  style: const TextStyle(
                                    color: Color(0xFFD5DDDA),
                                    fontSize: 10.5,
                                    height: 1.42,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Photo · ${event.imageCredit}',
                            style: const TextStyle(
                              color: _islandMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
    Widget _eventDetailRow({
      required MoveraMark mark,
      required String title,
      required String subtitle,
    }) {
      return Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MoveraLineIcon(
              mark: mark,
              color: const Color(0xFF1C242C),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7D898F),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    Widget _eventChip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1C242C),
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      );
    }
    Widget _driverEventCard(DriverEventConfig event, {double width = 252}) {
      return SizedBox(
        width: width,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDriverEvent(event),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 104,
                      width: double.infinity,
                      child: Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE8EFEC),
                          alignment: Alignment.center,
                          child: const MoveraLineIcon(
                            mark: MoveraMark.calendar,
                            color: Color(0xFF1C242C),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _eventChip(event.category),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF252E3A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const MoveraLineIcon(
                            mark: MoveraMark.calendar,
                            size: 13,
                            color: Color(0xFF1C242C),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${event.dateLabel} · ${event.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF66737A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const MoveraLineIcon(
                            mark: MoveraMark.place,
                            size: 13,
                            color: Color(0xFF8D989D),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8D989D),
                                fontSize: 9.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    /// One quiet row of the Home sheet list: line icon, label, and a value
    /// or a chevron when the row opens something.
    Widget _todayRow({
      Key? key,
      required MoveraMark mark,
      required String label,
      String? value,
      Color valueColor = const Color(0xFF111614),
      bool dot = false,
      VoidCallback? onTap,
      bool last = false,
    }) {
      const ink = Color(0xFF111614);
      return InkWell(
        key: key,
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFEDEFF0))),
          ),
          child: Row(
            children: [
              MoveraLineIcon(mark: mark, size: 20, color: ink),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (dot) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: valueColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (value != null)
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB4BBB8),
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    Widget _todayGroup(List<Widget Function(bool last)> rows) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E9EA)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) rows[i](i == rows.length - 1),
          ],
        ),
      );
    }
    /// Home sheet, open: "Today" numbers, then Waybill, Reservations and
    /// Events. Nothing else.
    List<Widget> _todayList() {
      final performance = _adminHomeConfig.performance;
      final events = _adminHomeConfig.events
          .where((event) => event.enabled)
          .toList(growable: false);
      final stats = <Widget Function(bool)>[
        if (performance.showRating)
          (last) => _todayRow(
                mark: MoveraMark.star,
                label: 'Rating',
                value: performance.rating.toStringAsFixed(2),
                last: last,
              ),
        if (performance.showAcceptanceRate)
          (last) => _todayRow(
                mark: MoveraMark.check,
                label: 'Acceptance',
                value: '${performance.acceptanceRate.toStringAsFixed(0)}%',
                last: last,
              ),
        if (performance.showCancellationRate)
          (last) => _todayRow(
                mark: MoveraMark.close,
                label: 'Cancellation',
                value: '${performance.cancellationRate.toStringAsFixed(1)}%',
                last: last,
              ),
      ];
      return [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(
            'Today',
            key: ValueKey<String>('home-sheet-today'),
            style: TextStyle(
              color: Color(0xFF111614),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (stats.isNotEmpty) _todayGroup(stats),
        const SizedBox(height: 22),
        ValueListenableBuilder<WaybillRecord?>(
          valueListenable: _waybills.lastListenable,
          builder: (context, lastWaybill, _) => _todayGroup([
            (last) => _todayRow(
                  key: const ValueKey<String>('home-sheet-last-waybill'),
                  mark: MoveraMark.receipt,
                  label: 'Waybill',
                  value: lastWaybill == null ? 'None yet' : lastWaybill.fare,
                  valueColor: lastWaybill == null
                      ? const Color(0xFF8A9390)
                      : const Color(0xFF111614),
                  onTap: lastWaybill == null
                      ? null
                      : () => showMoveraWaybillSheet(
                            context,
                            lastWaybill,
                            title: 'Last waybill',
                          ),
                  last: last,
                ),
            if (_adminHomeConfig.scheduledRides.enabled)
              (last) => _todayRow(
                    key: const ValueKey<String>('home-sheet-reservations'),
                    mark: MoveraMark.calendar,
                    label: 'Reservations',
                    value: _hasScheduledRideOffers ? 'New' : null,
                    valueColor: const Color(0xFF1FA463),
                    dot: _hasScheduledRideOffers,
                    onTap: _openScheduledRides,
                    last: last,
                  ),
            if (events.isNotEmpty)
              (last) => _todayRow(
                    key: const ValueKey<String>('home-sheet-events'),
                    mark: MoveraMark.city,
                    label: 'Events',
                    value: '${events.length}',
                    valueColor: const Color(0xFF8A9390),
                    onTap: () => _openDriverEvents(events),
                    last: last,
                  ),
          ]),
        ),
      ];
    }
    /// The event cards, one under the other, on their own page.
    void _openDriverEvents(List<DriverEventConfig> events) {
      pushSingle(
        context,
        MaterialPageRoute<void>(
          builder: (pageContext) => Scaffold(
            key: const ValueKey<String>('driver-events-page'),
            backgroundColor: const Color(0xFFF6F7F7),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(pageContext).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF111614),
                ),
              ),
              centerTitle: true,
              title: Text(
                _adminHomeConfig.eventsSectionTitle,
                style: const TextStyle(
                  color: Color(0xFF111614),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) =>
                  _driverEventCard(events[index], width: double.infinity),
            ),
          ),
        ),
      );
    }
    Widget panelColumn(ScrollController sc) {
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PhysicalShape(
            clipper: const RadarSheetClipper(
              notchWidth: 126,
              notchDepth: 58,
              cornerRadius: 24,
            ),
            color: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x3311181C),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 88),
                  Expanded(
                    child: ListView(
                      key: const PageStorageKey<String>('driver-overview-list'),
                      controller: sc,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      children: [
                        ..._todayList(),
                      ],
                    ),
                  ),
                  if (_isOnline)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _goOffline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3F454A),
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFD5DCDF),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: TextWidget(
                            text: "Go offline",
                            color: const Color(0xFF3F454A),
                            fontSize: 14,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                      ),
                    ),
                  DriverSheetNav.sheetQuickActionsBar(
                    context: context,
                    scaffoldKey: _scaffoldKey,
                    hasScheduledRideOffers: _hasScheduledRideOffers,
                    goOnlinePulseController: _goOnlinePulseController,
                    onOpenScheduledRides: _openScheduledRides,
                  ),
                ],
              ),
            ),
          ),
          DriverSheetNav.onlineEdgeDashOverlay(
            isOnline: _isOnline,
            hasRideOffers: _hasRideOffers || _radarHomeOffers.isNotEmpty,
          ),
        ],
      );
    }
}
