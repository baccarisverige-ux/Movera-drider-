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
  // Measured from the approved ride options design.
  static const Color _ink = Color(0xFF111614);
  static const Color _heading = Color(0xFF0F221C);
  static const Color _text = Color(0xFF1F2523);
  static const Color _border = Color(0xFF2A302E);
  static const Color _offInk = Color(0xFFB7BCBA);
  static const Color _offBorder = Color(0xFFDDE1DF);

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
    final side = MediaQuery.sizeOf(context).width >= 360 ? 32.0 : 18.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: largeText
            ? ListView(
                padding: EdgeInsets.symmetric(horizontal: side),
                children: [
                  _buildHeader(),
                  for (final index in _displayOrder)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCategory(index),
                    ),
                  _buildSaveArea(),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Shrink the cards so all four rows fit on screen.
                        final extent =
                            ((constraints.maxHeight - 8 - 3 * 12) / 4).clamp(
                              100.0,
                              137.0,
                            );
                        return GridView.builder(
                          padding: EdgeInsets.fromLTRB(side, 0, side, 8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 14,
                                mainAxisExtent: extent,
                              ),
                          itemCount: _displayOrder.length,
                          itemBuilder: (context, i) =>
                              _buildCategory(_displayOrder[i], extent: extent),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: _buildSaveArea(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Transform.translate(
                // Line the arrow up with the heading's left edge.
                offset: const Offset(-10, 0),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 24),
                  color: _heading,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_selectedCount of ${_categories.length} active',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your ride options',
          style: TextStyle(
            color: _heading,
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Select the ride types you'd like available for your trips",
          style: TextStyle(
            color: _text,
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCategory(int index, {double extent = 137}) {
    // Small screens get slightly smaller text so the icon keeps its room.
    final compact = extent < 120;
    final iconHeight = (extent - (compact ? 58 : 69)).clamp(36.0, 68.0);
    final category = _categories[index];
    final selected = _selected[index];
    final radius = BorderRadius.circular(11);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggle(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? _border : _offBorder,
                width: 1.1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  category.icon,
                  width: iconHeight * 124 / 68,
                  height: iconHeight,
                  colorFilter: ColorFilter.mode(
                    selected ? _ink : _offInk,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _heading : _offInk,
                      fontSize: compact ? 15 : 17,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    category.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _text : _offInk,
                      fontSize: compact ? 11 : 12,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
        height: 48,
        child: OutlinedButton(
          onPressed: _selectedCount == 0 ? null : _save,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _heading,
            disabledForegroundColor: _offInk,
            side: BorderSide(
              color: _selectedCount == 0 ? _offBorder : _border,
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: const Text(
            'Save preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
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
  });

  final String title;
  final String subtitle;
  final String icon;
}
