part of 'home.dart';

// Map, location, and sheet presentation for DriverHome.
// Timers and fields stay on the state. Geometry and map controls are unchanged.

/// One size for the floating controls on Home: recenter, safety and the
/// top island.
const double _homeMapButtonSize = 48;
// White island, same family as the reservation popup and the Home sheet.
const Color _islandBg = Color(0xFFFFFFFF);
const Color _islandFg = Color(0xFF111614);
const Color _islandMuted = Color(0xFF5E6461);
const Color _islandLine = Color(0xFFE4E6E5);
const Color _islandChip = Color(0xFFEDEEED);
const Color _islandDivider = Color(0xFFE2E5E7);
const Color _islandShadow = Color(0x38172027);
const Color _islandButtonBg = Color(0xFF111614);
const Color _islandButtonFg = Color(0xFFFFFFFF);
const Color _islandAccent = Color(0xFF1FA463);

// Sample figures until earnings come from the backend.
const String _todayEarnings = '183.25 kr';
const String _lastTripFare = '126 kr';

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
        if (!mounted) { return; }
        _rebuild(() => _hasLiveDriverLocation = false);
      }
    }
    void _listenToDriverLocation() {
      _driverLocationSubscription?.cancel();
      _driverLocationSubscription = _driverLocationService
          .watchPosition(distanceFilterMeters: 8)
          .listen(
        (location) {
          _applyDriverLocation(location);
          if (!_didCenterOnLiveLocation) {
            _didCenterOnLiveLocation = true;
            unawaited(_animateToDriverLocation());
          }
        },
        onError: (_) {
          if (!mounted) { return; }
          _rebuild(() => _hasLiveDriverLocation = false);
        },
      );
    }
    void _applyDriverLocation(DriverLocation location) {
      if (!mounted || !_liveVisible || !location.point.latitude.isFinite || !location.point.longitude.isFinite || location.point.latitude.abs() > 90 || location.point.longitude.abs() > 180) { return; }

      final next = location.point.toLatLng();
      final heading =
          location.headingDegrees.isFinite && location.headingDegrees >= 0
              ? location.headingDegrees
              : _driverHeading;
      _rebuild(() {
        _driverPosition = next;
        _driverHeading = heading;
        _hasLiveDriverLocation = location.isUsableAt(DateTime.now());
        _markers = {
          Marker(
            markerId: const MarkerId('driver_location'),
            position: next,
            infoWindow: const InfoWindow(title: 'Your live location'),
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
            infoWindow: const InfoWindow(title: 'Your live location'),
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
      final controller = _mapController;
      if (controller == null) { return; }

      try {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _driverPosition,
              zoom: 16.8,
              bearing: _driverHeading,
              tilt: 35,
            ),
          ),
        );
      } catch (_) {}
    }
    Future<void> _zoomToDriverLocation() async {
      await _startDriverLocation(moveCamera: true);
      if (!mounted) { return; }
      await _animateToDriverLocation();
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
          roadPoints.addAll(approach.latLngPoints);
        } catch (_) {}
      }

      try {
        final trip = await _roadRouteService.drivingRoute(
          origin: GeoPointMaps.fromLatLng(pickup),
          destination: GeoPointMaps.fromLatLng(dropoff),
        );
        if (roadPoints.isNotEmpty &&
            trip.latLngPoints.isNotEmpty &&
            roadPoints.last == trip.latLngPoints.first) {
          roadPoints.addAll(trip.latLngPoints.skip(1));
        } else {
          roadPoints.addAll(trip.latLngPoints);
        }
      } catch (_) {}

      if (!mounted) { return; }

      final media = MediaQuery.of(context);
      final insets = MapOverlayInsets.forHome(
        safeTop: media.padding.top,
        obscuredBottom: _homeMapObscuredBottom(context),
        hasTopBanner: _homeRadarMatchNotice != null,
      );

      if (roadPoints.length >= 2) {
        _rebuild(() {
          _directOfferRoutePolylines = {
            Polyline(
              polylineId: const PolylineId('direct_offer_road_route'),
              points: roadPoints,
              color: AppColor.primary,
              width: 6,
              geodesic: false,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      }

      await _fitPoints(
        roadPoints.isNotEmpty ? roadPoints : <LatLng>[pickup, dropoff],
        padding: insets.boundsPadding,
      );
    }
    Future<void> _fitPoints(
      List<LatLng> points, {
      double padding = 80,
    }) async {
      if (points.isEmpty || _mapController == null) { return; }

      var south = points.first.latitude;
      var north = points.first.latitude;
      var west = points.first.longitude;
      var east = points.first.longitude;

      for (final point in points.skip(1)) {
        south = math.min(south, point.latitude);
        north = math.max(north, point.latitude);
        west = math.min(west, point.longitude);
        east = math.max(east, point.longitude);
      }

      if ((north - south).abs() < 0.00001 &&
          (east - west).abs() < 0.00001) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 16),
        );
        return;
      }

      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            padding,
          ),
        );
      } catch (_) {}
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
    Future<void> _refreshDestinationRoadRoute() async {
      final destination = _destinationPosition;
      if (destination == null || !_hasLiveDriverLocation) {
        if (mounted) {
          _rebuild(() => _destinationRoutePolylines = <Polyline>{});
        }
        return;
      }

      try {
        final route = await _roadRouteService.drivingRoute(
          origin: GeoPointMaps.fromLatLng(_driverPosition),
          destination: GeoPointMaps.fromLatLng(destination),
        );
        if (!mounted || _destinationPosition != destination) { return; }

        _rebuild(() {
          _destinationRoutePolylines = {
            Polyline(
              polylineId: const PolylineId('destination_mode_road_route'),
              points: route.latLngPoints,
              color: AppColor.primary,
              width: 6,
              geodesic: false,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });
      } catch (_) {
        if (!mounted || _destinationPosition != destination) { return; }
        _rebuild(() => _destinationRoutePolylines = <Polyline>{});
      }
    }
    Future<void> _fitDestinationRoute() async {
      final destination = _destinationPosition;
      if (destination == null || _mapController == null) { return; }

      final routePoints = _destinationRoutePolylines.isEmpty
          ? <LatLng>[_driverPosition, destination]
          : _destinationRoutePolylines.first.points;

      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || _mapController == null) { return; }

      await _fitPoints(routePoints, padding: 74);
    }
    void _endDestinationMode() {
      if (!_destinationModeActive) { return; }
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
      if (_mainPanelPosition <= 0.001) {
        _setMapGesturesBlocked(false);
      }
      // Let SlidingUpPanel finish its native release animation first. iOS web
      // can occasionally interrupt that settle and leave the sheet between
      // collapsed / middle / open, so a delayed guard normalizes the position.
      _scheduleHomeSheetPositionGuard(
        delay: const Duration(milliseconds: 460),
      );
    }
    void _scheduleHomeSheetPositionGuard({
      Duration delay = const Duration(milliseconds: 180),
    }) {
      _homeSheetPositionGuardTimer?.cancel();
      _homeSheetPositionGuardTimer = Timer(delay, () {
        if (!mounted ||
            _outsideRadarOffer != null ||
            _sheetPointerActive ||
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
      _sheetPointerLastY = event.position.dy;
      _sheetPointerLastMs = now;
    }
    Future<void> _snapHomeSheet({double? velocity}) async {
      if (!_panelController.isAttached) { return; }
      _snapSheet.rangePx =
          _homeExpandedHeight(context) - MoveraSheetMetrics.collapsedHeight;
      final snap = _homeSnapPoint(context);
      final target = MoveraSheetMetrics.targetPosition(
        position: _panelController.panelPosition,
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
          trafficEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
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
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              mapType: MapType.normal,
              padding: MapOverlayInsets.forHome(
                safeTop: MediaQuery.paddingOf(context).top,
                obscuredBottom: _homeMapObscuredBottom(context),
                hasTopBanner: _homeRadarMatchNotice != null,
              ).edgeInsets,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
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
                _radarHomeOffers.isEmpty &&
                _pendingRadarHomeOffers.isNotEmpty)
              Positioned(
                left: 14,
                width: math.max(0, viewportWidth - 28),
                bottom: 178,
                child: _HomeOfferRadar(this)._buildRadarRefreshPrompt(),
              ),
            if (!isDestinationPanel &&
                _mainPanelPosition <= 0.04 &&
                _outsideRadarOffer == null &&
                _radarHomeOffers.isNotEmpty)
              Positioned(
                left: 14,
                width: math.max(0, viewportWidth - 28),
                bottom: 178,
                child: _HomeOfferRadar(this)._buildRadarOffersTray(),
              ),
            if (!isDestinationPanel) ...[
              if (_showTodaySummaryPopup)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey<String>('today-summary-scrim'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _hideTodaySummary,
                    child: ColoredBox(
                      color: const Color(0xFF172027).withValues(alpha: 0.22),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: ResSize.h * 55,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: PointerInterceptor(
                    child: _buildTopIsland(viewportWidth),
                  ),
                ),
              ),
            ],
            if (!isDestinationPanel && _homeRadarMatchNotice != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _HomeOfferRadar(this)._buildHomeRadarMatchNotice(_homeRadarMatchNotice!),
              ),

          ],
        ),
      );
    }
    /// White island at the top of Home: menu, today's earnings and
    /// destination search. The earnings are hidden until tapped; a second
    /// tap grows the island into the full Today details.
    Widget _buildTopIsland(double viewportWidth) {
      final expanded = _showTodaySummaryPopup;
      Widget divider() => Container(
            width: 1,
            height: 20,
            color: _islandDivider,
          );
      return AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        width: expanded ? math.min(viewportWidth - 32, 340.0) : 252,
        decoration: BoxDecoration(
          color: _islandBg,
          borderRadius: BorderRadius.circular(_homeMapButtonSize / 2),
          boxShadow: [
            BoxShadow(
              color: _islandShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _homeMapButtonSize,
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => Tooltip(
                        message: 'Menu',
                        child: InkWell(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: const SizedBox(
                            width: 50,
                            height: _homeMapButtonSize,
                            child: Icon(
                              Icons.menu_open_rounded,
                              size: 22,
                              color: _islandFg,
                            ),
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    Expanded(
                      child: InkWell(
                        key: const ValueKey<String>('last-trip-launcher'),
                        onTap: _onIslandEarningsTap,
                        child: SizedBox(
                          height: _homeMapButtonSize,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _islandEarningsLabel(),
                          ),
                        ),
                      ),
                    ),
                    divider(),
                    Tooltip(
                      message: 'Search destination',
                      child: InkWell(
                        key: const ValueKey<String>('destination-mode-open'),
                        onTap: _openDestinationModePicker,
                        child: SizedBox(
                          width: 50,
                          height: _homeMapButtonSize,
                          child: Center(
                            child: Image.asset(
                              AppAssets.search,
                              height: 17,
                              color: _islandFg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                key: const ValueKey<String>('today-summary-pointer'),
                ignoring: !expanded,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? _buildTodaySummaryPopup()
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      );
    }
    Widget _islandEarningsLabel() {
      const muted = _islandMuted;
      const accent = _islandAccent;
      if (_showTodaySummaryPopup) {
        return const Row(
          key: ValueKey<String>('island-today'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Today',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _islandFg,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: muted),
          ],
        );
      }
      if (_islandShowsLastTrip) {
        return const Row(
          key: ValueKey<String>('island-last-trip'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Last trip  ',
                      style: TextStyle(color: muted, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: _lastTripFare,
                      style: TextStyle(color: _islandFg, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.5),
              ),
            ),
          ],
        );
      }
      return const Row(
        key: ValueKey<String>('island-hidden'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 19, color: accent),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              '•••• kr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _islandFg,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      );
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
        onVerticalDragUpdate: _onRadarSheetDragUpdate,
        onVerticalDragEnd: _onRadarSheetDragEnd,
        child: child,
      );
    }
    void _showTodaySummary() {
      if (_showTodaySummaryPopup) { return; }
      _rebuild(() {
        _showTodaySummaryPopup = true;
      });
    }
    void _hideTodaySummary() {
      if (!_showTodaySummaryPopup && !_islandShowsLastTrip) { return; }
      _rebuild(() {
        _showTodaySummaryPopup = false;
        _islandShowsLastTrip = false;
      });
    }
    /// Hidden total → last trip fare → full Today details → hidden.
    void _onIslandEarningsTap() {
      if (_showTodaySummaryPopup) {
        _hideTodaySummary();
      } else if (_islandShowsLastTrip) {
        _showTodaySummary();
      } else {
        _rebuild(() => _islandShowsLastTrip = true);
      }
    }
    void _closeHomeFloatingPopupsForSheet() {
      if (!_showTodaySummaryPopup &&
          !showRideRequests &&
          !_isDirectOfferRoutePreview) {
        return;
      }

      _rebuild(() {
        _showTodaySummaryPopup = false;
        _islandShowsLastTrip = false;
        showRideRequests = false;
        _isDirectOfferRoutePreview = false;
        _directOfferRouteMarkers = {};
        _directOfferRoutePolylines = {};
      });
    }
    Widget _buildTodaySummaryPopup() {
      const muted = _islandMuted;
      const line = _islandLine;
      return Padding(
        key: const ValueKey<String>('today-summary-card'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: line),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _todayEarnings,
                          style: TextStyle(
                            color: _islandFg,
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Earnings today',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _islandChip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '3 rides',
                    style: TextStyle(
                      color: _islandFg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line, width: 1.5),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last trip · Comfort',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                      Text(
                        _lastTripFare,
                        style: TextStyle(
                          color: _islandFg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _islandRouteRow(
                    square: false,
                    label: 'Pickup',
                    place: 'Central Station',
                    time: '21:20',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 2, height: 12, color: line),
                    ),
                  ),
                  _islandRouteRow(
                    square: true,
                    label: 'Drop-off',
                    place: 'Södermalm',
                    time: '21:42',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Material(
                color: _islandButtonBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey<String>('today-history-button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _hideTodaySummary();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DriverRideHistory(),
                      ),
                    );
                  },
                  child: const Center(
                    child: Text(
                      'Ride history',
                      style: TextStyle(
                        color: _islandButtonFg,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget _islandRouteRow({
      required bool square,
      required String label,
      required String place,
      required String time,
    }) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: square ? _islandFg : _islandBg,
              shape: square ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: square ? BorderRadius.circular(2) : null,
              border: square ? null : Border.all(color: _islandFg, width: 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _islandMuted, fontSize: 11),
                ),
                Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _islandFg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: _islandFg,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Update link is unavailable right now. Try again later.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
    Widget _driverEventCard(DriverEventConfig event) {
      return SizedBox(
        width: 252,
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
    Widget _performanceSummaryCard() {
      final performance = _adminHomeConfig.performance;
      final metrics = <({String label, String value, MoveraMark icon})>[
        if (performance.showRating)
          (
            label: 'Rating',
            value: performance.rating.toStringAsFixed(2),
            icon: MoveraMark.star,
          ),
        if (performance.showAcceptanceRate)
          (
            label: 'Acceptance',
            value: '${performance.acceptanceRate.toStringAsFixed(0)}%',
            icon: MoveraMark.check,
          ),
        if (performance.showCancellationRate)
          (
            label: 'Cancellation',
            value: '${performance.cancellationRate.toStringAsFixed(1)}%',
            icon: MoveraMark.close,
          ),
      ];

      if (metrics.isEmpty) { return const SizedBox.shrink(); }

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFF0F2F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                color: Color(0xFF252E3A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Your recent activity',
              style: TextStyle(
                color: Color(0xFF8A959A),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(
                    child: _performanceCell(
                      label: metrics[index].label,
                      value: metrics[index].value,
                      icon: metrics[index].icon,
                    ),
                  ),
                  if (index != metrics.length - 1)
                    Container(
                      width: 1,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xFFEBEFF0),
                    ),
                ],
              ],
            ),
          ],
        ),
      );
    }
    Widget _stockholmWorkStats() {
      final stats = _adminHomeConfig.stockholmWork;
      final strongest = stats.innerAreas.reduce(
        (current, next) =>
            next.demandPercent > current.demandPercent ? next : current,
      );
      return Container(
        key: const ValueKey<String>('stockholm-work-stats'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE0E9E5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF18392E).withValues(alpha: 0.055),
              blurRadius: 28,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 43,
                  width: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFF163D31),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF163D31).withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const MoveraLineIcon(
                    mark: MoveraMark.city,
                    color: Color(0xFFE8F6EF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.title,
                        style: const TextStyle(
                          color: Color(0xFF1E2932),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stats.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF84908E),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF173F32),
                    Color(0xFF245845),
                  ],
                ),
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF173F32).withValues(alpha: 0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const MoveraLineIcon(
                      mark: MoveraMark.trend,
                      color: Color(0xFFBCE7D2),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Strongest area',
                          style: TextStyle(
                            color: Color(0xFFBFD5CC),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strongest.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF7F1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '${strongest.demandPercent}%',
                      style: const TextStyle(
                        color: Color(0xFF176F52),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < stats.innerAreas.length; i++) ...[
              _stockholmAreaRow(stats.innerAreas[i]),
              if (i != stats.innerAreas.length - 1)
                const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1EBE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDFE9E4)),
                        ),
                        child: const MoveraLineIcon(
                          mark: MoveraMark.explore,
                          size: 15,
                          color: Color(0xFF1C242C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stats.surroundingTitle,
                        style: const TextStyle(
                          color: Color(0xFF22312D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.05,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final area in stats.surroundingAreas)
                        _stockholmSurroundingChip(area),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    Widget _stockholmSurroundingChip(StockholmAreaConfig area) {
      final status = area.demandLabel.toLowerCase();
      final isBusy = status == 'busy';
      final isQuiet = status == 'quiet';

      final background = isBusy
          ? const Color(0xFFE8F5EF)
          : isQuiet
              ? const Color(0xFFF3F5F4)
              : const Color(0xFFF0F7F3);
      final border = isBusy
          ? const Color(0xFFCFE7DC)
          : isQuiet
              ? const Color(0xFFE2E7E4)
              : const Color(0xFFDCE9E3);
      final accent = isBusy
          ? const Color(0xFF167653)
          : isQuiet
              ? const Color(0xFF98A49F)
              : const Color(0xFF65A98B);
      final textColor = isBusy
          ? const Color(0xFF155F47)
          : isQuiet
              ? const Color(0xFF737F7A)
              : const Color(0xFF526F64);

      return Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: isBusy
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.20),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              area.name,
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${area.demandPercent}%',
              style: TextStyle(
                color: accent,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }
    Widget _stockholmAreaRow(StockholmAreaConfig area) {
      final busy = area.demandPercent >= 75;
      final accent =
          busy ? const Color(0xFF1C7D5B) : const Color(0xFF67A98C);
      final percent =
          (area.demandPercent / 100).clamp(0.0, 1.0).toDouble();

      return Container(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECE9)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    area.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF26323A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: busy
                        ? const Color(0xFFE9F5EF)
                        : const Color(0xFFF0F4F2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    area.demandLabel,
                    style: TextStyle(
                      color: busy
                          ? const Color(0xFF177454)
                          : const Color(0xFF66756F),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${area.demandPercent}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: busy
                          ? const Color(0xFF166E50)
                          : const Color(0xFF5D6B66),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEEC),
                borderRadius: BorderRadius.circular(99),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: percent,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: busy
                            ? const [
                                Color(0xFF1A7958),
                                Color(0xFF4BA17F),
                              ]
                            : const [
                                Color(0xFF6DAE92),
                                Color(0xFF91C9AF),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget _performanceCell({
      required String label,
      required String value,
      required MoveraMark icon,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoveraLineIcon(
            mark: icon,
            size: 15,
            color: const Color(0xFF6B777C),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF252E3A),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7D898F),
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    Widget _lastWaybillCard(WaybillRecord last) {
      return _sheetAlertCard(
        key: const ValueKey<String>('home-sheet-last-waybill'),
        mark: MoveraMark.receipt,
        iconColor: const Color(0xFF1C242C),
        title: 'Last waybill',
        subtitle: '${last.service} · ${last.fare} · ${last.dropoff}',
        onTap: () {
          showMoveraWaybillSheet(
            context,
            last,
            title: 'Last waybill',
          );
        },
      );
    }
    Widget panelColumn(ScrollController sc) {
      const ink = Color(0xFF252E3A);
      const muted = Color(0xFF7B878E);

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
                        const Padding(
                          padding: EdgeInsets.fromLTRB(2, 2, 2, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Driver overview",
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.35,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Your shift at a glance",
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Color(0xFF2FBE7B),
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    "Ready",
                                    style: TextStyle(
                                      color: Color(0xFF19865C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<WaybillRecord?>(
                          valueListenable: _waybills.lastListenable,
                          builder: (context, lastWaybill, _) {
                            if (lastWaybill == null) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _lastWaybillCard(lastWaybill),
                            );
                          },
                        ),
                        _performanceSummaryCard(),
                        if (_adminHomeConfig.scheduledRides.enabled) ...[
                          const SizedBox(height: 10),
                          _sheetAlertCard(
                            mark: MoveraMark.calendar,
                            iconColor: const Color(0xFF1C242C),
                            title: _adminHomeConfig.scheduledRides.title,
                            subtitle: _adminHomeConfig.scheduledRides.subtitle,
                            onTap: _openScheduledRides,
                          ),
                        ],
                        if (_adminHomeConfig.events
                            .where((event) => event.enabled)
                            .isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _adminHomeConfig.eventsSectionTitle,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _adminHomeConfig.eventsSectionSubtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF8A959A),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 208,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _adminHomeConfig.events
                                  .where((event) => event.enabled)
                                  .length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final events = _adminHomeConfig.events
                                    .where((event) => event.enabled)
                                    .toList(growable: false);
                                return _driverEventCard(events[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _stockholmWorkStats(),
                        ],
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
    Widget _sheetAlertCard({
      Key? key,
      required MoveraMark mark,
      required Color iconColor,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      return Material(
        key: key,
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: MoveraLineIcon(
                    mark: mark,
                    color: AppColor.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: title,
                        color: const Color(0xFF252E3A),
                        fontSize: 15,
                        fontWeight: fwSemiBold,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        TextWidget(
                          text: subtitle,
                          color: const Color(0xFF667483),
                          fontSize: 11,
                          fontWeight: fwNormal,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA5AFB4),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    }
}

