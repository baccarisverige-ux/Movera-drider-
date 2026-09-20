import 'package:flutter/material.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen> {
  int _selectedTab = 0;

  final List<_ScheduledRide> _requests = [
    _ScheduledRide(
      price: '126.75 kr',
      time: 'Today, 07:40–07:45',
      category: 'Comfort',
      distance: '5.8 km',
      pickup: 'Gamla vägen, Stockholm',
      destination: 'Rådans gårdsväg, Stockholm',
    ),
    _ScheduledRide(
      price: '209.25 kr',
      time: 'Today, 10:20–10:30',
      category: 'Premium',
      distance: '12 km',
      pickup: 'Högsätravägen, Lidingö',
      destination: 'Central Station, Stockholm',
    ),
  ];

  final List<_ScheduledRide> _accepted = [
    _ScheduledRide(
      price: '184.00 kr',
      time: 'Tomorrow, 08:15',
      category: 'Comfort',
      distance: '9.4 km',
      pickup: 'Södermalm, Stockholm',
      destination: 'Bromma Airport',
      accepted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rides = _selectedTab == 0 ? _requests : _accepted;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                itemCount: rides.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                      child: Row(
                        children: [
                          Text(
                            _selectedTab == 0 ? 'Available today' : 'Upcoming',
                            style: const TextStyle(
                              color: Color(0xFF6F7B82),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedTab == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4F5ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '2 new',
                                style: TextStyle(
                                  color: Color(0xFF16885B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  final ride = rides[index - 1];
                  return _ScheduledRideCard(
                    ride: ride,
                    onTap: () => _openRideDetails(ride),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _openRideDetails(_ScheduledRide ride) async {
    final action = await Navigator.of(context).push<_ScheduledRideAction>(
      MaterialPageRoute(
        builder: (_) => _ScheduledRideDetailsScreen(ride: ride),
      ),
    );

    if (!mounted || action == null) return;

    if (action == _ScheduledRideAction.accepted) {
      setState(() {
        _requests.remove(ride);
        _accepted.insert(0, ride.copyWith(accepted: true));
        _selectedTab = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation accepted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (action == _ScheduledRideAction.cancelled) {
      setState(() => _accepted.remove(ride));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation cancelled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 15),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF252E3A),
          ),
          const SizedBox(width: 2),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled rides',
                  style: TextStyle(
                    color: Color(0xFF252E3A),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Plan ahead and choose your next trip',
                  style: TextStyle(
                    color: Color(0xFF869198),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF425058),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _tabButton(0, 'Requests'),
            _tabButton(1, 'Accepted'),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        elevation: selected ? 1 : 0,
        shadowColor: const Color(0xFF1A2730).withOpacity(0.12),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() => _selectedTab = index),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF252E3A)
                    : const Color(0xFF808B91),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduledRideCard extends StatelessWidget {
  const _ScheduledRideCard({required this.ride, required this.onTap});

  final _ScheduledRide ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 13),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ride.price,
                          style: const TextStyle(
                            color: Color(0xFF252E3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFA3ADB2),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF19865C),
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4E5A61),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _RideMeta(
                        icon: Icons.directions_car_outlined,
                        label: ride.category,
                      ),
                      const SizedBox(width: 12),
                      _RideMeta(
                        icon: Icons.route_outlined,
                        label: ride.distance,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _RoutePreview(accepted: ride.accepted),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Icon(
                          Icons.radio_button_checked_rounded,
                          color: Color(0xFF2FBE7B),
                          size: 16,
                        ),
                        SizedBox(
                          height: 27,
                          child: VerticalDivider(
                            color: Color(0xFFCAD2D6),
                            thickness: 1.4,
                          ),
                        ),
                        Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFDF5A62),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickup,
                          style: const TextStyle(
                            color: Color(0xFF344047),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          ride.destination,
                          style: const TextStyle(
                            color: Color(0xFF344047),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideMeta extends StatelessWidget {
  const _RideMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF89949B), size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF89949B),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: double.infinity,
      child: CustomPaint(
        painter: _RoutePreviewPainter(accepted: accepted),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: accepted
                  ? const Color(0xFF252E3A)
                  : const Color(0xFF19865C),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A2730).withOpacity(0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              accepted ? 'Accepted' : 'Scheduled',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  const _RoutePreviewPainter({required this.accepted});

  final bool accepted;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE9EFEC);
    canvas.drawRect(Offset.zero & size, background);

    final street = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final thinStreet = Paint()
      ..color = const Color(0xFFD4DDDA)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(-10, size.height * 0.28)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.05,
          size.width * 0.58,
          size.height * 0.38,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          size.height * 0.58,
          size.width + 12,
          size.height * 0.22,
        ),
      street,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, -5),
      Offset(size.width * 0.36, size.height + 5),
      thinStreet,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, -5),
      Offset(size.width * 0.58, size.height + 5),
      thinStreet,
    );
    canvas.drawLine(
      Offset(-5, size.height * 0.72),
      Offset(size.width + 5, size.height * 0.88),
      thinStreet,
    );

    final route = Paint()
      ..color = accepted
          ? const Color(0xFF36464F)
          : const Color(0xFF19865C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.19, size.height * 0.70)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.22,
        size.width * 0.64,
        size.height * 0.82,
        size.width * 0.82,
        size.height * 0.31,
      );
    canvas.drawPath(routePath, route);

    final start = Paint()..color = const Color(0xFF2FBE7B);
    final end = Paint()..color = const Color(0xFFDF5A62);
    canvas.drawCircle(
      Offset(size.width * 0.19, size.height * 0.70),
      7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.19, size.height * 0.70),
      4.5,
      start,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.31),
      7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.31),
      4.5,
      end,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.accepted != accepted;
  }
}

class _ScheduledRide {
  const _ScheduledRide({
    required this.price,
    required this.time,
    required this.category,
    required this.distance,
    required this.pickup,
    required this.destination,
    this.accepted = false,
  });

  final String price;
  final String time;
  final String category;
  final String distance;
  final String pickup;
  final String destination;
  final bool accepted;

  _ScheduledRide copyWith({bool? accepted}) {
    return _ScheduledRide(
      price: price,
      time: time,
      category: category,
      distance: distance,
      pickup: pickup,
      destination: destination,
      accepted: accepted ?? this.accepted,
    );
  }
}

enum _ScheduledRideAction { accepted, cancelled }


class _ScheduledRideDetailsScreen extends StatelessWidget {
  const _ScheduledRideDetailsScreen({required this.ride});

  final _ScheduledRide ride;

  static const _ink = Color(0xFF252E3A);
  static const _muted = Color(0xFF7F8A91);
  static const _surface = Color(0xFFF3F5F6);
  static const _green = Color(0xFF19865C);
  static const _red = Color(0xFFC84E58);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _ink,
        ),
        titleSpacing: 0,
        title: Text(
          ride.accepted ? 'Your reservation' : 'Reservation details',
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _buildHero(),
                  const SizedBox(height: 14),
                  _buildRouteCard(),
                  const SizedBox(height: 14),
                  _buildPlanCard(),
                  if (ride.accepted) ...[
                    const SizedBox(height: 14),
                    _buildCommitmentCard(),
                  ],
                ],
              ),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ride.accepted
                                ? const Color(0xFFE9F4EF)
                                : const Color(0xFFF0F2F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ride.accepted
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 15,
                                color: ride.accepted ? _green : _muted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ride.accepted ? 'Confirmed' : 'Available',
                                style: TextStyle(
                                  color: ride.accepted ? _green : _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      ride.price,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 31,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      ride.time,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: _green,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE9ECEE)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DetailMetric(
                  icon: Icons.directions_car_outlined,
                  label: 'Ride type',
                  value: ride.category,
                ),
              ),
              Container(
                height: 34,
                width: 1,
                color: const Color(0xFFE5E9EB),
              ),
              Expanded(
                child: _DetailMetric(
                  icon: Icons.route_rounded,
                  label: 'Trip',
                  value: ride.distance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 3),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 58,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DEE1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 19,
                      color: Color(0xFFDF5A62),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ride.pickup,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 27),
                    const Text(
                      'Drop-off',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ride.destination,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF26343A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.accepted ? 'Before this ride' : 'Good to know',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const _PlanRow(
            icon: Icons.online_prediction_rounded,
            title: 'Be ready early',
            body: 'Go online 30 min before pickup so the app can guide you in time.',
          ),
          const SizedBox(height: 15),
          const _PlanRow(
            icon: Icons.alt_route_rounded,
            title: 'Trips on the way',
            body: 'You can still receive suitable rides before the scheduled pickup.',
          ),
          const SizedBox(height: 15),
          const _PlanRow(
            icon: Icons.event_busy_outlined,
            title: 'Plans changed?',
            body: 'Cancel as early as possible. Late cancellations can affect scheduled-ride access.',
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E4CE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF9B6B24),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserved for you',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We’ll keep this ride in your Accepted list. If you cancel, you’ll be asked for a reason before anything changes.',
                  style: TextStyle(
                    color: Color(0xFF6F777C),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE8EBED).withOpacity(0.9)),
        ),
      ),
      child: ride.accepted
          ? SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => _showCancelReasons(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _red,
                  side: const BorderSide(color: Color(0xFFE7C6C9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'Cancel reservation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, _ScheduledRideAction.accepted),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: Text(
                  'Accept  •  ' + ride.price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _showCancelReasons(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _CancelReasonSheet(),
    );

    if (reason == null || !context.mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelConfirmationSheet(reason: reason),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context, _ScheduledRideAction.cancelled);
    }
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF19865C)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A959B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF252E3A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  String? _selected;

  static const _reasons = <String>[
    'I can no longer make the pickup time',
    'Vehicle issue',
    'Personal emergency',
    'Pickup is too far from me',
    'Trip details no longer work for me',
    'Other reason',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD3D8DB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why are you cancelling?',
                          style: TextStyle(
                            color: Color(0xFF252E3A),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose the reason that best matches.',
                          style: TextStyle(
                            color: Color(0xFF7D888E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF39444A),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: _reasons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final reason = _reasons[index];
                  final selected = reason == _selected;
                  return Material(
                    color: selected ? Colors.white : const Color(0xFFF0F2F3),
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () => setState(() => _selected = reason),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF8AB7A3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 22,
                              width: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? const Color(0xFF19865C)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF19865C)
                                      : const Color(0xFFAFB8BD),
                                  width: 1.5,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: const Color(0xFF303B42),
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(context, _selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF252E3A),
                    disabledBackgroundColor: const Color(0xFFDCE1E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
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

class _CancelConfirmationSheet extends StatelessWidget {
  const _CancelConfirmationSheet({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3D8DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEF),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFFC84E58),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cancel this reservation?',
              style: TextStyle(
                color: Color(0xFF252E3A),
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(
                color: Color(0xFF59656C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cancelling close to pickup can affect your scheduled-ride access. This action cannot be undone in this demo flow.',
              style: TextStyle(
                color: Color(0xFF7D888E),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF252E3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'Cancel reservation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Keep reservation',
                  style: TextStyle(
                    color: Color(0xFF354047),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
