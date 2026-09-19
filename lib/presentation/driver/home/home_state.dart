part of 'home.dart';

class _DriverHomeState extends State<DriverHome>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PanelController _panelController = PanelController();
  final PanelController _destinationPanelController = PanelController();
  late final AnimationController _goOnlinePulseController;
  late final AnimationController _radarSweepController;
  Timer? _onlineTransitionTimer;
  Timer? _offerSimulationTimer;
  Timer? _directOfferTimer;
  Timer? _directOfferTimeoutTimer;
  Timer? _expandedDirectOfferTimer;
  GoogleMapController? _mapController;
  bool isPanelOpen = false;
  bool _blockMapGestures = false;
  bool _sheetPointerActive = false;
  double _mainPanelPosition = 0;
  final ValueNotifier<double> _panelSlidePosition = ValueNotifier<double>(0);
  static const Duration _sheetMotionDuration = Duration(milliseconds: 420);
  static const Curve _sheetMotionCurve = Curves.easeOutCubic;
  bool showRideRequests = false;
  bool isAccountActivated = true;
  bool _isGoingOnline = false;
  bool _isOnline = false;
  bool _hasRideOffers = false;
  bool _hasScheduledRideOffers = true;
  bool _showTodaySummaryPopup = false;
  HomeDirectOffer? _homeDirectOffer;
  Set<Marker> _markers = {};
  Set<Marker> _directOfferRouteMarkers = {};
  Set<Polyline> _directOfferRoutePolylines = {};
  bool _isDirectOfferRoutePreview = false;
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
    _loadMarkers();
  }
  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(59.3293, 18.0686),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }
  Future<void> _previewDirectOfferRoute(
    LatLng pickup,
    LatLng dropoff,
  ) async {
    final south = pickup.latitude < dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final north = pickup.latitude > dropoff.latitude
        ? pickup.latitude
        : dropoff.latitude;
    final west = pickup.longitude < dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    final east = pickup.longitude > dropoff.longitude
        ? pickup.longitude
        : dropoff.longitude;
    setState(() {
      _isDirectOfferRoutePreview = true;
      _directOfferRouteMarkers = {
        Marker(
          markerId: const MarkerId('radar_pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
        Marker(
          markerId: const MarkerId('radar_dropoff'),
          position: dropoff,
          infoWindow: const InfoWindow(title: 'Drop-off'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      };
      _directOfferRoutePolylines = {
        Polyline(
          polylineId: const PolylineId('direct_offer_route'),
          points: [pickup, dropoff],
          color: AppColor.primary,
          width: 6,
          geodesic: true,
        ),
      };
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        82,
      ),
    );
  }
  void _clearDirectOfferRoute() {
    if (!mounted) return;
    setState(() {
      _isDirectOfferRoutePreview = false;
      _directOfferRouteMarkers = {};
      _directOfferRoutePolylines = {};
    });
  }
  Future<void> _showHomeDirectOffer(
    HomeDirectOffer offer,
  ) async {
    if (!mounted || !_isOnline || showRideRequests) return;
    await _closeDriverSheet();
    if (!mounted || !_isOnline || showRideRequests) return;
    setState(() {
      _homeDirectOffer = offer;
    });
    await _previewDirectOfferRoute(
      offer.pickupPosition,
      offer.dropoffPosition,
    );
    _directOfferTimeoutTimer?.cancel();
    _directOfferTimeoutTimer = Timer(
      const Duration(milliseconds: 8500),
      () {
        if (!mounted || _homeDirectOffer?.id != offer.id) return;
        _dismissHomeDirectOffer();
      },
    );
  }
  void _dismissHomeDirectOffer() {
    _directOfferTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();
  }
  void _acceptHomeDirectOffer() {
    if (_homeDirectOffer == null) return;
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    _offerSimulationTimer?.cancel();
    setState(() {
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();
    Navigator.push(
      context,
      BottomToTopTransition(const AcceptRide()),
    );
  }
  void _showAccountActivationDialog() {
    AccountActivationDialog.show(
      context,
      onAccountActivated: () {
        setState(() {
          isAccountActivated = true;
        });
        _showSuccessSnackbar();
      },
      onCancel: () {
      },
    );
  }
  bool hideMainPanel = false;
  void openDestinationPanel() {
    setState(() {
      hideMainPanel = true;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      _destinationPanelController.open();
    });
  }
  void _setMapGesturesBlocked(bool value) {
    if (!mounted || _blockMapGestures == value) return;
    setState(() {
      _blockMapGestures = value;
    });
  }
  void _onSheetPointerDown(PointerDownEvent event) {
    _sheetPointerActive = true;
    _setMapGesturesBlocked(true);
  }
  void _onSheetPointerEnd(PointerEvent event) {
    _sheetPointerActive = false;
    if (_mainPanelPosition <= 0.001) {
      _setMapGesturesBlocked(false);
    }
  }
  Future<void> _openDriverSheet() async {
    _setMapGesturesBlocked(true);
    await _panelController.animatePanelToPosition(
      1,
      duration: _sheetMotionDuration,
      curve: _sheetMotionCurve,
    );
  }
  Future<void> _closeDriverSheet() async {
    await _panelController.animatePanelToPosition(
      0,
      duration: _sheetMotionDuration,
      curve: _sheetMotionCurve,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DriverSideMenu(),
      body: showRideRequests
          ? Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  child: _buildRadarMapBackdrop(),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 9.5, sigmaY: 9.5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF172027).withOpacity(0.46),
                            const Color(0xFF6F7D80).withOpacity(0.16),
                            const Color(0xFFF4F7F8).withOpacity(0.24),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                PointerInterceptor(
                  child: const SizedBox.expand(),
                ),
                RideRequests(
                  onCloseRides: () {
                    setState(() {
                      showRideRequests = false;
                    });
                  },
                ),
              ],
            )
          : hideMainPanel
          ? DestinationSetPanel(
              controller: _destinationPanelController,
              onClose: () {
                setState(() {
                });
              },
              body: body(isDestinationPanel: true),
            )
          : SlidingUpPanel(
              color: Colors.transparent,
              backdropColor: Colors.transparent,
              backdropOpacity: 0,
              backdropEnabled: false, // Changed to false
              backdropTapClosesPanel: false,
              controller: _panelController,
              margin: EdgeInsets.all(0),
              minHeight: 108,
              padding: EdgeInsets.zero,
              boxShadow: [],
              isDraggable: true,
              defaultPanelState: PanelState.CLOSED,
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              parallaxEnabled: false,
              onPanelSlide: (double pos) {
                _mainPanelPosition = pos;
                _panelSlidePosition.value = pos;
                final nextPanelOpen = pos > 0.3;
                final nextBlockMap = _sheetPointerActive || pos > 0.001;
                if (isPanelOpen != nextPanelOpen ||
                    _blockMapGestures != nextBlockMap) {
                  setState(() {
                    isPanelOpen = nextPanelOpen;
                    _blockMapGestures = nextBlockMap;
                  });
                }
              },
              onPanelOpened: () {
                _mainPanelPosition = 1;
                _panelSlidePosition.value = 1;
                _setMapGesturesBlocked(true);
              },
              onPanelClosed: () {
                _mainPanelPosition = 0;
                _panelSlidePosition.value = 0;
                _sheetPointerActive = false;
                if (isPanelOpen) {
                  setState(() {
                    isPanelOpen = false;
                  });
                }
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
              panelBuilder: (ScrollController sc) => PointerInterceptor(
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
  Widget _buildRadarMapBackdrop() => _buildRadarMapBackdropImpl();
  Widget body({bool isDestinationPanel = false}) => bodyImpl(isDestinationPanel: isDestinationPanel);
  Widget _buildHomeDirectOfferCard(HomeDirectOffer offer) => _buildHomeDirectOfferCardImpl(offer);
  Widget _homeDirectLocationRow({
    required Color color,
    required String title,
    required String subtitle,
  }) => _homeDirectLocationRowImpl(color: color, title: title, subtitle: subtitle);
  Widget _mapControlDivider() => _mapControlDividerImpl();
  void _showTodaySummary() => _showTodaySummaryImpl();
  void _hideTodaySummary() => _hideTodaySummaryImpl();
  Widget _buildTodaySummaryPopup() => _buildTodaySummaryPopupImpl();
  Widget _premiumActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) => _premiumActivityRowImpl(icon: icon, title: title, subtitle: subtitle, trailing: trailing);
  void _goOnline() => _goOnlineImpl();
  Future<void> _goOffline() => _goOfflineImpl();
  void _openRideOffers() => _openRideOffersImpl();
  void _openScheduledRides() => _openScheduledRidesImpl();
  Widget _buildGoOnlineButton() => _buildGoOnlineButtonImpl();
  Widget _buildGoingOnlineButton() => _buildGoingOnlineButtonImpl();
  Widget _buildTripRadarButton() => _buildTripRadarButtonImpl();
  Widget _buildRadarOrb({
    required String title,
    required String status,
    required String subtitle,
    VoidCallback? onTap,
    bool active = false,
    bool loading = false,
    bool offer = false,
    double pulse = 0,
    double sweep = 0,
  }) => _buildRadarOrbImpl(title: title, status: status, subtitle: subtitle, onTap: onTap, active: active, loading: loading, offer: offer, pulse: pulse, sweep: sweep);
  Widget panelColumn(ScrollController sc) => panelColumnImpl(sc);
  Widget _sheetAlertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) => _sheetAlertCardImpl(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle);
  Widget _driverStatCard({
    required String title,
    required String mainText,
    required Color mainColor,
    IconData? icon,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
    String? footer,
  }) => _driverStatCardImpl(title: title, mainText: mainText, mainColor: mainColor, icon: icon, iconColor: iconColor, badge: badge, badgeColor: badgeColor, footer: footer);

  @override
  void dispose() {
    _goOnlinePulseController.dispose();
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    _radarSweepController.dispose();
    _panelSlidePosition.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWidget(
                      text: "Account Approved!",
                      fontSize: 16,
                      fontWeight: fwBold,
                      color: AppColor.white,
                    ),
                    4.height,
                    TextWidget(
                      text:
                          "Your account has been approved. You can now go online and start accepting rides.",
                      fontSize: 12,
                      fontWeight: fwNormal,
                      color: AppColor.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
