import 'package:flutter/material.dart';
import 'package:movera/widgets/movera_line_icon.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE5E9EB);
  static const Color _canvas = Color(0xFFF4F6F7);

  final List<_DriverCategory> _categories = const [
    _DriverCategory(
      title: 'Movera',
      subtitle: 'Affordable everyday rides',
      icon: MoveraMark.car,
      badge: 'RECOMMENDED',
    ),
    _DriverCategory(
      title: 'Comfort',
      subtitle: 'Newer cars with extra legroom',
      icon: MoveraMark.user,
    ),
    _DriverCategory(
      title: 'Premium',
      subtitle: 'Premium cars and elevated service',
      icon: MoveraMark.star,
    ),
    _DriverCategory(
      title: 'Priority',
      subtitle: 'Faster pickup requests',
      icon: MoveraMark.bolt,
      badge: 'FASTER',
    ),
    _DriverCategory(
      title: 'Movera XL',
      subtitle: 'Larger groups of up to 6 riders',
      icon: MoveraMark.city,
    ),
    _DriverCategory(
      title: 'Electric',
      subtitle: 'Quiet and fossil-free rides',
      icon: MoveraMark.trend,
    ),
    _DriverCategory(
      title: 'Movera Pet',
      subtitle: 'Pet-friendly ride requests',
      icon: MoveraMark.shield,
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
            _buildSummary(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) => _buildCategory(index),
              ),
            ),
            _buildSaveArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$_selectedCount of 7 active',
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleAll,
            style: TextButton.styleFrom(
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _selectedCount == _categories.length ? 'Clear' : 'Select all',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
              color: selected ? _ink : _line,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: selected ? _ink : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _ink : const Color(0xFFC9D0D3),
                      width: 1.3,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const Spacer(),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: MoveraLineIcon(
                  mark: category.icon,
                  color: _ink,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (category.badge != null) ...[
                const SizedBox(height: 4),
                Text(
                  category.badge!,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                category.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
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
  final MoveraMark icon;
  final String? badge;
}
