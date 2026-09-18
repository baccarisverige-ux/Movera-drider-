import 'package:flutter/material.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen> {
  int _selectedTab = 0;

  static const _requests = [
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

  static const _accepted = [
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
                  return _ScheduledRideCard(ride: rides[index - 1]);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
  const _ScheduledRideCard({required this.ride});

  final _ScheduledRide ride;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
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
                      Text(
                        ride.time,
                        style: const TextStyle(
                          color: Color(0xFF4E5A61),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _RideMeta(
                        icon: Icons.directions_car_outlined,
                        label: ride.category,
                      ),
                      const SizedBox(width: 10),
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
}
