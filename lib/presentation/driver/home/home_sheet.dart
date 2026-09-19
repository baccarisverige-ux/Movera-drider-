part of 'home.dart';

extension _DriverHomeSheet on _DriverHomeState {
  Widget panelColumnImpl(ScrollController sc) {
    const ink = Color(0xFF252E3A);
    const muted = Color(0xFF7B878E);
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                  _sheetAlertCardImpl(
                    icon: Icons.event_available_outlined,
                    iconColor: const Color(0xFF7E8A93),
                    title: "Scheduled rides available",
                    subtitle: "View open requests in your area",
                  ),
                  const SizedBox(height: 10),
                  _driverStatCardImpl(
                    title: "Star rating",
                    mainText: "★ 4.88",
                    mainColor: ink,
                  ),
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
        DriverSheetNav.onlineEdgeDashOverlay(isOnline: _isOnline),
      ],
    );
  }
  Widget _sheetAlertCardImpl({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColor.white, size: 24),
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
        ],
      ),
    );
  }
  Widget _driverStatCardImpl({
    required String title,
    required String mainText,
    required Color mainColor,
    IconData? icon,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
    String? footer,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: title,
                  color: const Color(0xFF8A97A8),
                  fontSize: 12,
                  fontWeight: fwNormal,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9DA9B8),
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: TextWidget(
                  text: mainText,
                  color: mainColor,
                  fontSize: 19,
                  fontWeight: fwSemiBold,
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextWidget(
                text: badge,
                color: AppColor.white,
                fontSize: 11,
                fontWeight: fwSemiBold,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 10),
            TextWidget(
              text: footer,
              color: const Color(0xFF8A97A8),
              fontSize: 10,
              fontWeight: fwNormal,
            ),
          ],
        ],
      ),
    );
  }
}
