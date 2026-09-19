import 'dart:async';
import 'dart:ui' as ui;
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/side%20menu/side_menu.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PanelController _panelController = PanelController();
  late final AnimationController _goOnlinePulseController;
  late final AnimationController _radarSweepController;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;
  final ValueNotifier<double> _panelSlidePosition = ValueNotifier<double>(0);
  bool showRideRequests = false;
  bool isAccountActivated = true;
  bool _isGoingOnline = false;
  bool _isOnline = false;
  bool _hasScheduledRideOffers = true;
  Set<Marker> _markers = {};
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _goOnlinePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  void _onSheetPointerDown(PointerDownEvent event) {
    _sheetPointerActive = true;
    _blockMapGestures = true;
    setState(() {});
  }

  void _onSheetPointerEnd(PointerEvent event) {
    _sheetPointerActive = false;
    if (_mainPanelPosition <= 0.001) {
      _blockMapGestures = false;
      setState(() {});
    }
  }

  void _openScheduledRides() {}

  void _goOffline() {
    setState(() => _isOnline = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DriverSideMenu(),
      body: showRideRequests
          ? const RideRequests()
          : SlidingUpPanel(
              color: Colors.transparent,
              controller: _panelController,
              minHeight: 108,
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              defaultPanelState: PanelState.CLOSED,
              onPanelSlide: (pos) {
                _mainPanelPosition = pos;
                _panelSlidePosition.value = pos;
              },
              collapsed: PointerInterceptor(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onSheetPointerDown,
                  onPointerUp: _onSheetPointerEnd,
                  onPointerCancel: _onSheetPointerEnd,
                  child: DriverSheetNav.collapsedDock(
                    context: context,
                    scaffoldKey: _scaffoldKey,
                    isOnline: _isOnline,
                    hasScheduledRideOffers: _hasScheduledRideOffers,
                    goOnlinePulseController: _goOnlinePulseController,
                    onOpenScheduledRides: _openScheduledRides,
                  ),
                ),
              ),
              panelBuilder: (sc) => PointerInterceptor(
                child: DriverSheetNav.collapsedDock(
                  context: context,
                  scaffoldKey: _scaffoldKey,
                  isOnline: _isOnline,
                  hasScheduledRideOffers: _hasScheduledRideOffers,
                  goOnlinePulseController: _goOnlinePulseController,
                  onOpenScheduledRides: _openScheduledRides,
                ),
              ),
              body: AbsorbPointer(
                absorbing: _blockMapGestures,
                child: CustomGoogleMap(
                  initialPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _goOnlinePulseController.dispose();
    _radarSweepController.dispose();
    _panelSlidePosition.dispose();
    super.dispose();
  }
}
