import 'package:flutter/material.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _line = Color(0xFFE5E9EB);
  static const Color _canvas = Color(0xFFF4F6F7);

  final List<_DriverCategory> _categories = const [
    _DriverCategory(
      title: 'Movera',
      subtitle: 'Affordable everyday rides',
      icon: Icons.local_taxi_outlined,
      badge: 'RECOMMENDED',
    ),
    _DriverCategory(
      title: 'Comfort',
      subtitle: 'Newer cars with extra legroom',
      icon: Icons.airline_seat_recline_extra_rounded,
    ),
    _DriverCategory(
      title: 'Premium',
      subtitle: 'Premium cars and elevated service',
      icon: Icons.workspace_premium_outlined,
    ),
    _DriverCategory(
      title: 'Priority',
      subtitle: 'Faster pickup requests',
      icon: Icons.bolt_rounded,
      badge: 'FASTER',
    ),
    _DriverCategory(
      title: 'Movera XL',
      subtitle: 'Larger groups of up to 6 riders',
      icon: Icons.airport_shuttle_outlined,
    ),
    _DriverCategory(
      title: 'Electric',
      subtitle: 'Quiet and fossil-free rides',
      icon: Icons.electric_car_outlined,
    ),
    _DriverCategory(
      title: 'Movera Pet',
      subtitle: 'Pet-friendly ride requests',
      icon: Icons.pets_outlined,
    ),
  ];

  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(_categories.length, true);
  }

  int get _selectedCount => _selected.where((selected) => selected).length;

  void _toggleAll() {
    final selectAll = _selectedCount != _categories.length;
    setState(() {
      _selected = List<bool>.filled(_categories.length, selectAll);
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_selectedCount ride categories saved',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _ink,
        ),
        titleSpacing: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride preferences',
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Choose the requests you want to receive',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 14),
                  for (var index = 0; index < _categories.length; index++) ...[
                    _buildCategory(index),
                    if (index != _categories.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            _buildSaveArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedCount of 7 active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'You can change this at any time',
                  style: TextStyle(
                    color: Color(0xFFB9C2C7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggleAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF75D7B0),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              _selectedCount == _categories.length ? 'Clear' : 'Select all',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(int index) {
    final category = _categories[index];
    final selected = _selected[index];

    return Material(
      color: selected ? Colors.white : const Color(0xFFF8F9F9),
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selected[index] = !_selected[index];
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected ? const Color(0xFFBFDCCD) : _line,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE6F5EE)
                      : const Color(0xFFEEF1F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  category.icon,
                  color: selected ? _green : const Color(0xFF78848A),
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (category.badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category.badge!,
                              style: const TextStyle(
                                color: _green,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 25,
                width: 25,
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _green : const Color(0xFFC9D0D3),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 17,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _selectedCount == 0 ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            disabledBackgroundColor: const Color(0xFFD6DBDE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Save preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverCategory {
  const _DriverCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
}
