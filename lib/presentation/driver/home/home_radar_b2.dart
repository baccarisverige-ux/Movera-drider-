part of 'home.dart';

extension _DriverHomeRadarB2 on _DriverHomeState {
  Future<void> _goOfflineImpl() async {
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    setState(() {
      _isGoingOnline = false;
      _isOnline = false;
      _hasRideOffers = false;
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();
    await _closeDriverSheet();
  }
  void _openRideOffersImpl() {
    if (_homeDirectOffer != null) return;
    setState(() {
      showRideRequests = true;
      _hasRideOffers = false;
    });
  }
  void _openScheduledRidesImpl() {
    setState(() {
      _hasScheduledRideOffers = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScheduledRidesScreen(),
      ),
    );
  }
  Widget _buildGoOnlineButtonImpl() {
    return AnimatedBuilder(
      animation: _goOnlinePulseController,
      builder: (context, child) {
        return _buildRadarOrbImpl(
          title: isAccountActivated ? "Trip radar" : "Account pending",
          status: isAccountActivated ? "OFFLINE" : "UNAVAILABLE",
          subtitle: isAccountActivated
              ? "Tap to start\nscanning"
              : "Activation required",
          onTap: _goOnline,
          pulse: _goOnlinePulseController.value,
        );
      },
    );
  }
  Widget _buildGoingOnlineButtonImpl() {
    return AnimatedBuilder(
      animation: _radarSweepController,
      builder: (context, child) {
        return _buildRadarOrbImpl(
          title: "Trip radar",
          status: "CONNECTING",
          subtitle: "Starting nearby\nride scanning",
          active: true,
          loading: true,
          sweep: _radarSweepController.value,
        );
      },
    );
  }
  Widget _buildTripRadarButtonImpl() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _goOnlinePulseController,
        _radarSweepController,
      ]),
      builder: (context, child) {
        return _buildRadarOrbImpl(
          title: _hasRideOffers ? "New ride" : "Finding new trips",
          status: _hasRideOffers ? "RIDE AVAILABLE" : "SCANNING",
          subtitle: _hasRideOffers
              ? "Tap to view\nthe offer"
              : "Searching nearby\nrequests",
          active: true,
          offer: _hasRideOffers,
          pulse: _goOnlinePulseController.value,
          sweep: _radarSweepController.value,
          onTap: _openRideOffers,
        );
      },
    );
  }
  Widget _buildRadarOrbImpl({
    required String title,
    required String status,
    required String subtitle,
    VoidCallback? onTap,
    bool active = false,
    bool loading = false,
    bool offer = false,
    double pulse = 0,
    double sweep = 0,
  }) {
    const mint = Color(0xFF58E5A6);
    final glowStrength = active ? 0.12 + (pulse * 0.28) : 0.08;
    final ringScale = active ? 0.76 + (pulse * 0.40) : 1.0;
    return Semantics(
      button: true,
      label: "$title, $status. $subtitle",
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mint.withOpacity(active ? 0.035 : 0.025),
                  border: Border.all(
                    color: mint.withOpacity(active ? 0.22 : 0.15),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mint.withOpacity(active ? 0.045 : 0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.72),
                  width: 1.2,
                ),
              ),
            ),
            Container(
              width: 79,
              height: 79,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBFD9CF).withOpacity(0.12),
                border: Border.all(
                  color: mint.withOpacity(active ? 0.30 : 0.19),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: mint.withOpacity(glowStrength),
                    blurRadius: active ? 19 : 11,
                    spreadRadius: active ? 5 : 2,
                  ),
                ],
              ),
            ),
            if (active)
              Transform.rotate(
                angle: sweep * 6.283185307179586,
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 2,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            mint.withOpacity(0),
                            mint.withOpacity(0.72),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              elevation: 16,
              shadowColor: const Color(0xFF12201C).withOpacity(0.38),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                width: 73,
                height: 73,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.24, -0.32),
                    radius: 0.98,
                    colors: [
                      Color(0xD98F999C),
                      Color(0xD9727D80),
                      Color(0xE05A6468),
                    ],
                    stops: [0, 0.58, 1],
                  ),
                  border: Border.all(
                    color: const Color(0xD9E7ECEE),
                    width: 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D263238),
                      blurRadius: 11,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x66FFFFFF),
                      blurRadius: 3,
                      offset: Offset(-1, -2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  splashColor: mint.withOpacity(0.12),
                  highlightColor: mint.withOpacity(0.06),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        child: Container(
                          width: offer ? 7 : 5,
                          height: offer ? 7 : 5,
                          decoration: BoxDecoration(
                            color: offer ? const Color(0xFFFFD166) : mint,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (offer
                                        ? const Color(0xFFFFD166)
                                        : mint)
                                    .withOpacity(0.82),
                                blurRadius: offer ? 11 : 7,
                                spreadRadius: offer ? 2.5 : 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 16, 6, 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.8,
                                height: 1.1,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: offer
                                    ? const Color(0xFFFFD166)
                                    : const Color(0xFFD8E1DE),
                                fontSize: 5.4,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 10,
                              height: 1,
                              color: Colors.white.withOpacity(0.36),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB7C2BE),
                                fontSize: 5.9,
                                height: 1.12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loading)
                        Positioned(
                          bottom: 5,
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.1,
                              color: mint.withOpacity(0.85),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
