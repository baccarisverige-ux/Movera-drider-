import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/side%20menu/side_menu.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PanelController _panelController = PanelController();
  late final AnimationController _goOnlinePulseController;
  late final AnimationController _radarSweepController;
  Timer? _onlineTransitionTimer;
  GoogleMapController? _mapController;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;
  bool showRideRequests = false;
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

  void _setMapGesturesBlocked(bool value) {
    if (!mounted || _blockMapGestures == value) return;
    setState(() => _blockMapGestures = value);
  }

  void _onSheetPointerDown(PointerDownEvent event) {
    _sheetPointerActive = true;
    _setMapGesturesBlocked(true);
  }

  void _onSheetPointerEnd(PointerEvent event) {
    _sheetPointerActive = false;
    if (_mainPanelPosition <= 0.001) _setMapGesturesBlocked(false);
  }

  void _goOnline() {
    _onlineTransitionTimer?.cancel();
    setState(() {
      _isGoingOnline = true;
      _isOnline = false;
    });
    _onlineTransitionTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isGoingOnline = false;
        _isOnline = true;
      });
    });
  }

  Future<void> _goOffline() async {
    _onlineTransitionTimer?.cancel();
    setState(() {
      _isGoingOnline = false;
      _isOnline = false;
    });
    await _panelController.animatePanelToPosition(0);
  }

  void _openScheduledRides() {
    setState(() => _hasScheduledRideOffers = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduledRidesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DriverSideMenu(),
      body: showRideRequests
          ? RideRequests(
              onCloseRides: () => setState(() => showRideRequests = false),
            )
          : SlidingUpPanel(
              color: Colors.transparent,
              controller: _panelController,
              minHeight: 108,
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              defaultPanelState: PanelState.CLOSED,
              boxShadow: const [],
              onPanelSlide: (pos) {
                _mainPanelPosition = pos;
                final nextOpen = pos > 0.3;
                final nextBlock = _sheetPointerActive || pos > 0.001;
                if (isPanelOpen != nextOpen || _blockMapGestures != nextBlock) {
                  setState(() {
                    isPanelOpen = nextOpen;
                    _blockMapGestures = nextBlock;
                  });
                }
              },
              onPanelClosed: () {
                _mainPanelPosition = 0;
                _sheetPointerActive = false;
                if (isPanelOpen) setState(() => isPanelOpen = false);
                _setMapGesturesBlocked(false);
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
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onSheetPointerDown,
                  onPointerUp: _onSheetPointerEnd,
                  onPointerCancel: _onSheetPointerEnd,
                  child: panelColumn(sc),
                ),
              ),
              body: AbsorbPointer(
                absorbing: _blockMapGestures,
                child: body(),
              ),
            ),
    );
  }

  Widget body({bool isDestinationPanel = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomGoogleMap(
          initialPosition: _initialPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (c) => _mapController = c,
        ),
        if (!isDestinationPanel)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 118 + MediaQuery.paddingOf(context).bottom,
              ),
              child: _isGoingOnline
                  ? const CircularProgressIndicator()
                  : _isOnline
                      ? FilledButton(
                          onPressed: () =>
                              setState(() => showRideRequests = true),
                          child: const Text('Scanning'),
                        )
                      : FilledButton(
                          onPressed: _goOnline,
                          child: const Text('Go online'),
                        ),
            ),
          ),
      ],
    );
  }

  Widget panelColumn(ScrollController sc) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PhysicalShape(
          clipper: const RadarSheetClipper(
            notchWidth: 126,
            notchDepth: 58,
            cornerRadius: 24,
          ),
          color: const Color(0xFFFCFDFD),
          elevation: 8,
          shadowColor: const Color(0x3311181C),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: const Color(0xFFFCFDFD),
            child: Column(
              children: [
                const SizedBox(height: 62),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.all(18),
                    children: const [
                      Text('Driver overview',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text('Your shift at a glance'),
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
                        child: TextWidget(
                          text: 'Go offline',
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
        DriverSheetNav.onlineEdgeDashOverlay(isOnline: _isOnline),
      ],
    );
  }

  @override
  void dispose() {
    _goOnlinePulseController.dispose();
    _onlineTransitionTimer?.cancel();
    _radarSweepController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
