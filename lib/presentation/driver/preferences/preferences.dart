import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/core/settings/settings_repository.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF6E737A);
  static const Color _line = Color(0xFFE3E6EA);

  // Stored order: the saved `selected` list is indexed by this list, so new
  // categories are only ever appended. [_displayOrder] controls the grid.
  final List<_DriverCategory> _categories = const [
    _DriverCategory(
      title: 'Movera',
      subtitle: 'Standard • Everyday ride',
      icon: AppAssets.rideMovera,
    ),
    _DriverCategory(
      title: 'Comfort',
      subtitle: 'Extra comfort • Plush',
      icon: AppAssets.rideComfort,
    ),
    _DriverCategory(
      title: 'Premium',
      subtitle: 'Luxury • Premium service',
      icon: AppAssets.ridePremium,
    ),
    _DriverCategory(
      title: 'Priority',
      subtitle: 'Faster pickup • Priority',
      icon: AppAssets.ridePriority,
    ),
    _DriverCategory(
      title: 'Movera XL',
      subtitle: '6 seat • Spacious',
      icon: AppAssets.rideXl,
    ),
    _DriverCategory(
      title: 'Electric',
      subtitle: 'Low emissions • Eco',
      icon: AppAssets.rideElectric,
    ),
    _DriverCategory(
      title: 'Movera Pet',
      subtitle: 'Pet friendly • Carrier OK',
      icon: AppAssets.ridePet,
    ),
    _DriverCategory(
      title: 'Booster Seat',
      subtitle: 'Child seat • Kids safe',
      icon: AppAssets.rideBooster,
    ),
  ];

  static const List<int> _displayOrder = [4, 5, 6, 0, 1, 2, 3, 7];

  late List<bool> _selected;

  final _settings = SettingsRepository();
  bool _settingsTouched = false;
  Future<void> _restoreSettings() async {
    try {
      final data = await _settings.read('categories');
      if (!mounted || _settingsTouched) {
        return;
      }
      final saved = data['selected'];
      setState(() {
        if (saved is List &&
            saved.length <= _categories.length &&
            saved.every((v) => v is bool)) {
          // Saves from before a category existed keep it enabled by default.
          _selected = [
            ...saved.cast<bool>(),
            ...List<bool>.filled(_categories.length - saved.length, true),
          ];
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load saved preferences.'),
            action: SnackBarAction(label: 'Retry', onPressed: _restoreSettings),
          ),
        );
      }
    }
  }

  Future<bool> _persistSettings() async {
    _settingsTouched = true;
    try {
      await _settings.save('categories', {'selected': _selected});
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save preferences. Retry.')),
        );
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(_categories.length, true);
    _restoreSettings();
  }

  int get _selectedCount => _selected.where((selected) => selected).length;

  void _toggle(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
    _persistSettings();
  }

  Future<void> _save() async {
    if (!await _persistSettings() || !mounted) {
      return;
    }
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
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: largeText
            ? ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTopBar(),
                  _buildHeading(),
                  for (final index in _displayOrder)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCategory(index),
                    ),
                  _buildSaveArea(),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(children: [_buildTopBar(), _buildHeading()]),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 142,
                          ),
                      itemCount: _displayOrder.length,
                      itemBuilder: (context, i) =>
                          _buildCategory(_displayOrder[i]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSaveArea(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _ink,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$_selectedCount of ${_categories.length} active',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 6, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Choose your ride options',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Select the ride types you'd like available for your trips",
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(int index) {
    final category = _categories[index];
    final selected = _selected[index];
    final foreground = selected ? _ink : const Color(0xFFB4B9BF);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggle(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _ink : _line,
                width: selected ? 1.4 : 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  category.icon,
                  height: 58,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                ),
                const SizedBox(height: 8),
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? _ink : _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _selectedCount == 0 ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD6DBDE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Save preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
  });

  final String title;
  final String subtitle;
  final String icon;
}
