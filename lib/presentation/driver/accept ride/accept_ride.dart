import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/common/chat/chat.dart';
import 'package:movera/presentation/driver/ride%20completed/ride_completed.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/navigation_transition.dart';

class AcceptRide extends StatefulWidget {
  const AcceptRide({
    super.key,
    this.offerId = 'demo-radar-offer',
    this.riderName = 'Angelica',
    this.riderRating = 4.9,
    this.riderTrips = 312,
    this.pickupAddress = 'Odlarvägen 22',
    this.pickupArea = 'Enhörna',
    this.dropoffAddress = 'T-Centralen, Stockholm',
    this.pickupPosition = const LatLng(59.3279, 18.0615),
    this.dropoffPosition = const LatLng(59.3326, 18.0649),
  });

  final String offerId;
  final String riderName;
  final double riderRating;
  final int riderTrips;
  final String pickupAddress;
  final String pickupArea;
  final String dropoffAddress;
  final LatLng pickupPosition;
  final LatLng dropoffPosition;

  @override
  State<AcceptRide> createState() => _AcceptRideState();
}

enum _RideStage { headingToPickup, waitingForRider, onTrip }

class _AcceptRideState extends State<AcceptRide> {
  static const Color _ink = Color(0xFF101416);
  static const Color _panel = Color(0xFF111719);
  static const Color _panel2 = Color(0xFF1A2225);
  static const Color _muted = Color(0xFF9AA5A9);
  static const Color _green = Color(0xFF45C987);
  static const Color _line = Color(0xFF30393C);
  static const Color _danger = Color(0xFFE75D65);

  static const LatLng _driverStart = LatLng(59.3262, 18.0595);

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#202830"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a9b3ba"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#202830"},{"weight":2}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#39434b"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#202830"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#222b32"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#39434b"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#171d22"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#414c55"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#48545d"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2a333a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#102b3e"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5f93bf"}]}
]
''';

  GoogleMapController? _mapController;
  _RideStage _stage = _RideStage.headingToPickup;
  Timer? _waitTimer;
  int _waitSeconds = 0;

  @override
  void dispose() {
    _waitTimer?.cancel();
    _mapController = null;
    super.dispose();
  }

  List<LatLng> get _routePoints {
    switch (_stage) {
      case _RideStage.headingToPickup:
      case _RideStage.waitingForRider:
        return [
          _driverStart,
          const LatLng(59.3269, 18.0602),
          const LatLng(59.3274, 18.0609),
          widget.pickupPosition,
        ];
      case _RideStage.onTrip:
        return [
          widget.pickupPosition,
          const LatLng(59.3292, 18.0624),
          const LatLng(59.3307, 18.0630),
          widget.dropoffPosition,
        ];
    }
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: _stage == _RideStage.onTrip
            ? const LatLng(59.3292, 18.0624)
            : _driverStart,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };

    if (_stage != _RideStage.onTrip) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.pickupAddress),
        ),
      );
    } else {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: widget.dropoffPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.dropoffAddress),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('active-route'),
          points: _routePoints,
          width: 6,
          color: _green,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = _routePoints;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100,
        ),
      );
    } catch (_) {}
  }

  void _advanceRide() {
    switch (_stage) {
      case _RideStage.headingToPickup:
        setState(() {
          _stage = _RideStage.waitingForRider;
          _waitSeconds = 0;
        });
        _startWaitTimer();
        break;
      case _RideStage.waitingForRider:
        _waitTimer?.cancel();
        setState(() => _stage = _RideStage.onTrip);
        break;
      case _RideStage.onTrip:
        Navigator.pushReplacement(
          context,
          BottomToTopTransition(const DriverRideCompleted()),
        );
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitRoute();
    });
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _stage != _RideStage.waitingForRider) return;
      setState(() => _waitSeconds++);
    });
  }

  String get _waitLabel {
    final minutes = _waitSeconds ~/ 60;
    final seconds = (_waitSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _title {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return 'Heading to pickup';
      case _RideStage.waitingForRider:
        return 'Waiting for rider';
      case _RideStage.onTrip:
        return 'Dropping off ${widget.riderName}';
    }
  }

  String get _subtitle {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return '${widget.riderName} is waiting at ${widget.pickupAddress}';
      case _RideStage.waitingForRider:
        return '${widget.riderName} will be out shortly';
      case _RideStage.onTrip:
        return 'On the way to ${widget.dropoffAddress}';
    }
  }

  String get _actionLabel {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return 'I’m at pickup';
      case _RideStage.waitingForRider:
        return 'Start trip';
      case _RideStage.onTrip:
        return 'Complete trip';
    }
  }

  String get _actionHint {
    switch (_stage) {
      case _RideStage.headingToPickup:
        return 'Use when you reach the pickup point';
      case _RideStage.waitingForRider:
        return 'Start when the rider is in the car';
      case _RideStage.onTrip:
        return 'Complete only at the drop-off point';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = math.min(430.0, constraints.maxHeight * 0.49);
          final safeTop = MediaQuery.paddingOf(context).top;

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomGoogleMap(
                initialPosition: const CameraPosition(
                  target: LatLng(59.3272, 18.0610),
                  zoom: 15.8,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                customMapStyle: _darkMapStyle,
                padding: EdgeInsets.only(bottom: panelHeight - 18),
                onMapCreated: (controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fitRoute();
                  });
                },
              ),
              Positioned(
                left: 14,
                right: 14,
                top: safeTop + 10,
                child: _buildNavigationCard(),
              ),
              Positioned(
                right: 14,
                bottom: panelHeight + 18,
                child: _buildMapControls(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: _buildRidePanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationCard() {
    final onTrip = _stage == _RideStage.onTrip;
    final waiting = _stage == _RideStage.waitingForRider;

    return Container(
      key: const ValueKey<String>('active-ride-navigation-card'),
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: const Color(0xEF090D0F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: (waiting ? const Color(0xFF4B5960) : _green)
                  .withOpacity(waiting ? 0.20 : 0.13),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              waiting
                  ? Icons.location_on_rounded
                  : onTrip
                      ? Icons.turn_right_rounded
                      : Icons.navigation_rounded,
              color: waiting ? Colors.white : _green,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waiting
                      ? 'PICKUP'
                      : onTrip
                          ? 'IN 350 M'
                          : 'TO PICKUP',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting
                      ? widget.pickupAddress
                      : onTrip
                          ? 'Turn right'
                          : widget.pickupAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting
                      ? widget.pickupArea
                      : onTrip
                          ? widget.dropoffAddress
                          : '${widget.pickupArea} · 3 min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB9C2C5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  waiting ? 'AT PICKUP' : onTrip ? '2 min' : '1.1 km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waiting ? '0 m' : onTrip ? '650 m' : '3 min',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _mapCircleButton(
          icon: Icons.my_location_rounded,
          onTap: _fitRoute,
        ),
        const SizedBox(height: 10),
        _mapCircleButton(
          icon: Icons.shield_outlined,
          accent: _green,
          onTap: () => showSafetyToolKitSheet(context),
        ),
        const SizedBox(height: 10),
        _mapCircleButton(
          icon: Icons.layers_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Map layers will be connected to map settings.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _mapCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color accent = Colors.white,
  }) {
    return Material(
      color: const Color(0xE914191B),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.24),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 46,
          width: 46,
          child: Icon(icon, color: accent, size: 21),
        ),
      ),
    );
  }

  Widget _buildRidePanel() {
    return Container(
      key: ValueKey<String>('active-ride-panel-${_stage.name}'),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C565A),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.55,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildEtaTile(),
                ],
              ),
              const SizedBox(height: 15),
              _buildProgress(),
              const SizedBox(height: 16),
              _buildRiderRow(),
              const SizedBox(height: 16),
              _buildPrimaryAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtaTile() {
    final main = _stage == _RideStage.waitingForRider
        ? _waitLabel
        : _stage == _RideStage.onTrip
            ? '2 min'
            : '3 min';
    final sub = _stage == _RideStage.waitingForRider
        ? 'WAITING'
        : _stage == _RideStage.onTrip
            ? '650 m'
            : '1.1 km';

    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Text(
            main,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final activeIndex = switch (_stage) {
      _RideStage.headingToPickup => 1,
      _RideStage.waitingForRider => 1,
      _RideStage.onTrip => 2,
    };

    final labels = _stage == _RideStage.waitingForRider
        ? const ['Matched', 'Waiting', 'On trip', 'Done']
        : const ['Matched', 'Pickup', 'On trip', 'Done'];

    return Row(
      children: List.generate(labels.length, (index) {
        final completed = index < activeIndex;
        final active = index == activeIndex;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 20 : 16,
                    height: active ? 20 : 16,
                    decoration: BoxDecoration(
                      color: completed
                          ? _green
                          : active
                              ? _panel
                              : const Color(0xFF4A5458),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? _green : Colors.transparent,
                        width: active ? 3 : 0,
                      ),
                    ),
                    child: completed
                        ? const Icon(
                            Icons.check_rounded,
                            color: _ink,
                            size: 11,
                          )
                        : null,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active || completed
                          ? Colors.white
                          : const Color(0xFF727C80),
                      fontSize: 8.5,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (index != labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.fromLTRB(5, 0, 5, 18),
                    color: completed ? _green : _line,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRiderRow() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const CircleAvatar(
            backgroundImage: AssetImage(AppAssets.profileImg),
            backgroundColor: Color(0xFF263034),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: _showRiderProfile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.riderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.riderRating.toStringAsFixed(1)} ★  ·  ${widget.riderTrips} rides',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _riderAction(
          tooltip: 'Call rider',
          icon: Icons.call_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Calling will use the device phone integration.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        _riderAction(
          tooltip: 'Message rider',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () {
            Navigator.push(
              context,
              BottomToTopTransition(const Chat()),
            );
          },
        ),
        const SizedBox(width: 6),
        _riderAction(
          tooltip: 'Rider profile',
          icon: Icons.person_outline_rounded,
          onTap: _showRiderProfile,
        ),
      ],
    );
  }

  Widget _riderAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _panel2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    final danger = _stage == _RideStage.onTrip;

    return Row(
      children: [
        Material(
          color: _panel2,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: _showTripOptions,
            borderRadius: BorderRadius.circular(17),
            child: const SizedBox(
              height: 56,
              width: 56,
              child: Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 56,
            child: FilledButton(
              key: const ValueKey<String>('active-ride-primary-action'),
              onPressed: _advanceRide,
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: danger
                    ? const Color(0xFF2A3438)
                    : _green,
                foregroundColor: danger ? Colors.white : _ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    danger
                        ? Icons.flag_outlined
                        : _stage == _RideStage.waitingForRider
                            ? Icons.play_arrow_rounded
                            : Icons.near_me_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actionLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _actionHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: danger
                                ? const Color(0xFFABB5B9)
                                : _ink.withOpacity(0.72),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 21),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRiderProfile() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF151B1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundImage: AssetImage(AppAssets.profileImg),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.riderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.riderRating.toStringAsFixed(1)} ★ · ${widget.riderTrips} rides',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _panel2,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Rider details from the booking will appear here when the backend profile is connected.',
                    style: TextStyle(
                      color: Color(0xFFC2C9CC),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTripOptions() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEDF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                _optionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Trip details',
                  subtitle: '${widget.pickupAddress} → ${widget.dropoffAddress}',
                  onTap: () => Navigator.pop(sheetContext),
                ),
                _optionTile(
                  icon: Icons.shield_outlined,
                  title: 'Safety toolkit',
                  subtitle: 'Share trip, record audio or get help',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showSafetyToolKitSheet(context);
                  },
                ),
                if (_stage != _RideStage.onTrip)
                  _optionTile(
                    icon: Icons.close_rounded,
                    title: 'Cancel trip',
                    subtitle: 'Only cancel when you cannot continue',
                    danger: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmCancelTrip();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFFECEE)
                      : const Color(0xFFEAF1EE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: danger ? _danger : const Color(0xFF315E4D),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? _danger : const Color(0xFF252E3A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D898F),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA7B0B4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancelTrip() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Cancel this trip?'),
          content: const Text(
            'The trip will be released and you’ll return to the previous driver screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep trip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: _danger),
              child: const Text('Cancel trip'),
            ),
          ],
        );
      },
    );

    if (cancel == true && mounted) {
      Navigator.pop(context);
    }
  }
}
