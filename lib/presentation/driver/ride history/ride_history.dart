import 'package:flutter/material.dart';

class DriverRideHistory extends StatefulWidget {
  const DriverRideHistory({super.key});

  @override
  State<DriverRideHistory> createState() => _DriverRideHistoryState();
}

enum _HistoryView { overview, rides }
enum _HistoryPeriod { today, week, month }

class _DriverRideHistoryState extends State<DriverRideHistory> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF315E4D);
  static const Color _mint = Color(0xFF58E5A6);
  static const Color _line = Color(0xFFE7EBE9);

  _HistoryView _view = _HistoryView.overview;
  _HistoryPeriod _period = _HistoryPeriod.week;

  static const List<_HistoryRide> _rides = [
    _HistoryRide(
      id: 'ride-001',
      day: 'Today',
      time: '14:42',
      category: 'Comfort',
      pickup: 'Central Station',
      dropoff: 'Södermalm',
      distance: '6.8 km',
      duration: '18 min',
      earnings: '126 kr',
    ),
    _HistoryRide(
      id: 'ride-002',
      day: 'Today',
      time: '12:18',
      category: 'Movera',
      pickup: 'Vasastan',
      dropoff: 'Solna centrum',
      distance: '8.1 km',
      duration: '22 min',
      earnings: '94 kr',
    ),
    _HistoryRide(
      id: 'ride-003',
      day: 'Today',
      time: '09:26',
      category: 'Comfort',
      pickup: 'Östermalm',
      dropoff: 'Kungsholmen',
      distance: '5.4 km',
      duration: '16 min',
      earnings: '83.25 kr',
    ),
    _HistoryRide(
      id: 'ride-004',
      day: 'Yesterday',
      time: '20:11',
      category: 'Premium',
      pickup: 'Stockholm Central',
      dropoff: 'Bromma',
      distance: '10.2 km',
      duration: '27 min',
      earnings: '174 kr',
    ),
    _HistoryRide(
      id: 'ride-005',
      day: 'Yesterday',
      time: '17:36',
      category: 'Movera',
      pickup: 'Liljeholmen',
      dropoff: 'Hammarby Sjöstad',
      distance: '7.7 km',
      duration: '21 min',
      earnings: '118 kr',
    ),
    _HistoryRide(
      id: 'ride-006',
      day: 'Fri, Sep 18',
      time: '15:08',
      category: 'Comfort',
      pickup: 'Kista',
      dropoff: 'Sundbyberg',
      distance: '9.3 km',
      duration: '24 min',
      earnings: '139 kr',
    ),
  ];

  String get _periodLabel {
    switch (_period) {
      case _HistoryPeriod.today:
        return 'Today';
      case _HistoryPeriod.week:
        return '14 Sep – 20 Sep';
      case _HistoryPeriod.month:
        return 'September';
    }
  }

  String get _periodEarnings {
    switch (_period) {
      case _HistoryPeriod.today:
        return '183.25 kr';
      case _HistoryPeriod.week:
        return '1 482.75 kr';
      case _HistoryPeriod.month:
        return '5 924.40 kr';
    }
  }

  String get _periodRides {
    switch (_period) {
      case _HistoryPeriod.today:
        return '3';
      case _HistoryPeriod.week:
        return '11';
      case _HistoryPeriod.month:
        return '43';
    }
  }

  String get _periodHours {
    switch (_period) {
      case _HistoryPeriod.today:
        return '3 h 14 m';
      case _HistoryPeriod.week:
        return '8 h 26 m';
      case _HistoryPeriod.month:
        return '36 h 48 m';
    }
  }

  void _showOverview() {
    if (_view == _HistoryView.overview) return;
    setState(() => _view = _HistoryView.overview);
  }

  void _showAllRides() {
    if (_view == _HistoryView.rides) return;
    setState(() => _view = _HistoryView.rides);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.025, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _view == _HistoryView.overview
                    ? _buildOverview()
                    : _buildAllRides(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: _view == _HistoryView.rides
                  ? _showOverview
                  : () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey<_HistoryView>(_view),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _view == _HistoryView.overview
                        ? 'Earnings & history'
                        : 'All rides',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _view == _HistoryView.overview
                        ? 'Your Movera activity'
                        : _periodLabel,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_view == _HistoryView.rides)
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 18,
                color: _ink,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final visibleRideCount = _period == _HistoryPeriod.today
        ? 3
        : _period == _HistoryPeriod.week
            ? 11
            : 43;

    return ListView(
      key: const ValueKey<String>('history-overview'),
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 14),
        _buildEarningsHero(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.schedule_rounded,
                label: 'Online',
                value: _periodHours,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.local_taxi_outlined,
                label: 'Rides',
                value: _periodRides,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Earnings breakdown',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 9),
        _buildBreakdownCard(),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latest rides',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey<String>('history-all-rides-button'),
              onPressed: _showAllRides,
              style: TextButton.styleFrom(
                foregroundColor: _green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All rides',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _HistoryRideCard(ride: _rides[0], compact: true),
        const SizedBox(height: 8),
        _HistoryRideCard(ride: _rides[1], compact: true),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('history-view-all-rides'),
            onPressed: _showAllRides,
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: Text('View all ' + visibleRideCount.toString() + ' rides'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _line),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllRides() {
    final groups = <String, List<_HistoryRide>>{};
    for (final ride in _rides) {
      groups.putIfAbsent(ride.day, () => <_HistoryRide>[]).add(ride);
    }

    return ListView(
      key: const ValueKey<String>('history-all-rides'),
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: _green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _periodRides + ' rides in ' + _periodLabel,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _periodEarnings,
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final ride in entry.value) ...[
            _HistoryRideCard(ride: ride),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 5),
        ],
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'Today',
            selected: _period == _HistoryPeriod.today,
            onTap: () => setState(() => _period = _HistoryPeriod.today),
          ),
          _PeriodButton(
            label: 'Week',
            selected: _period == _HistoryPeriod.week,
            onTap: () => setState(() => _period = _HistoryPeriod.week),
          ),
          _PeriodButton(
            label: 'Month',
            selected: _period == _HistoryPeriod.month,
            onTap: () => setState(() => _period = _HistoryPeriod.month),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsHero() {
    return TweenAnimationBuilder<double>(
      key: ValueKey<_HistoryPeriod>(_period),
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F7F3),
              Color(0xFFEAF3EE),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE8E1)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE5E0)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: _green,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _periodEarnings,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Net earnings',
                    style: TextStyle(
                      color: _green,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 34,
              width: 34,
              decoration: const BoxDecoration(
                color: _mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF1F4B3C),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: const Column(
        children: [
          _BreakdownRow(label: 'Ride earnings', value: '1 724.15 kr'),
          SizedBox(height: 10),
          _BreakdownRow(
            label: 'Tips',
            value: '+84.00 kr',
            valueColor: _green,
          ),
          SizedBox(height: 10),
          _BreakdownRow(
            label: 'Movera service fee',
            value: '−325.40 kr',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, color: _line),
          ),
          _BreakdownRow(
            label: 'Net earnings',
            value: '1 482.75 kr',
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF252E3A)
                  : const Color(0xFF7D898F),
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EBE9)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4E5B55),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7D898F),
                    fontSize: 9.5,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong
                  ? const Color(0xFF252E3A)
                  : const Color(0xFF6F7B82),
              fontSize: strong ? 12.5 : 11.5,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF252E3A),
            fontSize: strong ? 13 : 11.5,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistoryRideCard extends StatelessWidget {
  const _HistoryRideCard({
    required this.ride,
    this.compact = false,
  });

  final _HistoryRide ride;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(ride.id),
      padding: EdgeInsets.fromLTRB(
        12,
        compact ? 10 : 12,
        12,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7EBE9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: compact ? 34 : 38,
                width: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: Color(0xFF315E4D),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickup + ' → ' + ride.dropoff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ride.category +
                          ' · ' +
                          ride.duration +
                          ' · ' +
                          ride.distance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D898F),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ride.earnings,
                    style: const TextStyle(
                      color: Color(0xFF252E3A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ride.time,
                    style: const TextStyle(
                      color: Color(0xFF8B969B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 9),
            const Row(
              children: [
                SizedBox(
                  height: 6,
                  width: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF58E5A6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Color(0xFF315E4D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRide {
  const _HistoryRide({
    required this.id,
    required this.day,
    required this.time,
    required this.category,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.duration,
    required this.earnings,
  });

  final String id;
  final String day;
  final String time;
  final String category;
  final String pickup;
  final String dropoff;
  final String distance;
  final String duration;
  final String earnings;
}
