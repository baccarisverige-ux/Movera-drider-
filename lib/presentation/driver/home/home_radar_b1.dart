part of 'home.dart';

mixin _DriverHomeRadarB1 on _DriverHomeState {
  Widget _mapControlDividerImpl() {
    return Container(
      height: ResSize.h * 22,
      width: 1,
      color: const Color(0xFFE2E5E7),
    );
  }
  void _showTodaySummaryImpl() {
    if (_showTodaySummaryPopup) return;
    setState(() {
      _showTodaySummaryPopup = true;
    });
  }
  void _hideTodaySummaryImpl() {
    if (!_showTodaySummaryPopup) return;
    setState(() {
      _showTodaySummaryPopup = false;
    });
  }
  Widget _buildTodaySummaryPopupImpl() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE2E8E5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172027).withOpacity(0.16),
              blurRadius: 28,
              offset: const Offset(8, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today",
                    style: TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _hideTodaySummary,
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    height: 36,
                    width: 36,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7A858B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDDE4E1),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF435149),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "183.25 kr",
                          style: TextStyle(
                            color: Color(0xFF20282E),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Total earnings today",
                          style: TextStyle(
                            color: Color(0xFF7B878E),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2FBE7B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _premiumActivityRowImpl(
              icon: Icons.local_taxi_outlined,
              title: "3 rides",
              subtitle: "Completed today",
            ),
            const Divider(height: 1, color: Color(0xFFE8ECEE)),
            _premiumActivityRowImpl(
              icon: Icons.route_outlined,
              title: "Central Station → Södermalm",
              subtitle: "Last trip • Comfort • 21:42",
              trailing: "126 kr",
            ),
          ],
        ),
      ),
    );
  }
  Widget _premiumActivityRowImpl({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            height: 34,
            width: 34,
            child: Icon(
              icon,
              color: const Color(0xFF69757B),
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A959B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF252E3A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _goOnlineImpl() {
    if (!isAccountActivated) {
      _showAccountActivationDialog();
      return;
    }
    _onlineTransitionTimer?.cancel();
    _offerSimulationTimer?.cancel();
    _directOfferTimer?.cancel();
    _directOfferTimeoutTimer?.cancel();
    _expandedDirectOfferTimer?.cancel();
    setState(() {
      _isGoingOnline = true;
      _isOnline = false;
      _hasRideOffers = false;
      _showTodaySummaryPopup = false;
      _homeDirectOffer = null;
    });
    _clearDirectOfferRoute();
    _onlineTransitionTimer = Timer(
      const Duration(milliseconds: 1400),
      () {
        if (!mounted) return;
        setState(() {
          _isGoingOnline = false;
          _isOnline = true;
        });
        _directOfferTimer = Timer(
          const Duration(milliseconds: 2200),
          () {
            if (!mounted || !_isOnline) return;
            _showHomeDirectOffer(kVeryCloseDirectOffer);
          },
        );
        _expandedDirectOfferTimer = Timer(
          const Duration(milliseconds: 13000),
          () {
            if (!mounted || !_isOnline || _homeDirectOffer != null) return;
            _showHomeDirectOffer(kExpandedDirectOffer);
          },
        );
        _offerSimulationTimer = Timer(
          const Duration(milliseconds: 24500),
          () {
            if (!mounted ||
                !_isOnline ||
                _homeDirectOffer != null ||
                showRideRequests) {
              return;
            }
            setState(() {
              _hasRideOffers = true;
            });
            Future.delayed(const Duration(milliseconds: 260), () {
              if (!mounted ||
                  !_isOnline ||
                  !_hasRideOffers ||
                  _homeDirectOffer != null) {
                return;
              }
              _openRideOffersImpl();
            });
          },
        );
      },
    );
  }
}
