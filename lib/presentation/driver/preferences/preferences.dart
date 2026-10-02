import 'package:movera/core/settings/settings_repository.dart';
import 'package:flutter/material.dart';

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

  static const Color _green = Color(0xFF1C6B45);

  final List<_DriverCategory> _categories = const [
    _DriverCategory(
      title: 'Movera',
      subtitle: 'Affordable everyday rides',
      image: 'assets/images/prefs/movera.jpg',
    ),
    _DriverCategory(
      title: 'Comfort',
      subtitle: 'Newer cars with extra legroom',
      image: 'assets/images/prefs/comfort.jpg',
    ),
    _DriverCategory(
      title: 'Premium',
      subtitle: 'Premium cars and elevated service',
      image: 'assets/images/prefs/premium.jpg',
    ),
    _DriverCategory(
      title: 'Priority',
      subtitle: 'Faster pickup requests',
      image: 'assets/images/prefs/priority.jpg',
    ),
    _DriverCategory(
      title: 'Movera XL',
      subtitle: 'Larger groups of up to 6 riders',
      image: 'assets/images/prefs/xl.jpg',
    ),
    _DriverCategory(
      title: 'Electric',
      subtitle: 'Quiet and fossil-free rides',
      image: 'assets/images/prefs/electric.jpg',
    ),
    _DriverCategory(
      title: 'Movera Pet',
      subtitle: 'Pet-friendly ride requests',
      image: 'assets/images/prefs/pet.jpg',
    ),
  ];

  late List<bool> _selected;

  final _settings = SettingsRepository();
  bool _settingsTouched = false;
  Future<void> _restoreSettings() async {
    try {
    final data=await _settings.read('categories'); if(!mounted || _settingsTouched) { return; }
    setState(() { if(data['selected'] is List && (data['selected'] as List).length==_categories.length && (data['selected'] as List).every((v)=>v is bool)) { _selected=List<bool>.from(data['selected'] as List); } });
      } catch (_) {
      if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not load saved preferences.'),
        action: SnackBarAction(label:'Retry',onPressed:_restoreSettings))); }
    }
  }
  Future<bool> _persistSettings() async {
    _settingsTouched=true;
    try { await _settings.save('categories',{'selected':_selected}); return true; }
    catch(_) { if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save preferences. Retry.'))); } return false; }
  }

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(_categories.length, true);
    _restoreSettings();
  }

  int get _selectedCount => _selected.where((selected) => selected).length;

  void _toggleAll() {
    final selectAll = _selectedCount != _categories.length;
    setState(() {
      _selected = List<bool>.filled(_categories.length, selectAll);
    });
    _persistSettings();
  }

  Future<void> _save() async {
    if (!await _persistSettings() || !mounted) { return; }
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
        leading: IconButton(tooltip: 'Back', 
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _ink,
        ),
        titleSpacing: 2,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
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
        child: MediaQuery.textScalerOf(context).scale(14) > 20
          ? ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              const Padding(padding: EdgeInsets.all(8), child: Text('Local demo preferences', style: TextStyle(fontSize: 12))),
              _buildSummary(),
              for (var index = 0; index < _categories.length; index++)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: SizedBox(height: 330, child: _buildCategory(index))),
              _buildSaveArea(),
            ])
          : Column(
          children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('Local demo preferences', style: TextStyle(fontSize: 12))),
            _buildSummary(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.textScalerOf(context).scale(14) > 20 ? 1 : 2,
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(14) > 20 ? 330 : null,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedCount of 7 active',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'You can change this at any time',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 28, color: _line),
            TextButton(
              onPressed: _toggleAll,
              style: TextButton.styleFrom(foregroundColor: _green),
              child: Text(
                _selectedCount == _categories.length ? 'Clear' : 'All',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
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
          _persistSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
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
                      color: selected ? _green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? _green : const Color(0xFFD5DADD),
                        width: 1.4,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
                    child: ColoredBox(
                      color: const Color(0xFFF7F8F8),
                      child: Image.asset(
                        category.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
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
            backgroundColor: const Color(0xFF16382C),
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
    required this.image,
  });

  final String title;
  final String subtitle;
  final String image;
}
