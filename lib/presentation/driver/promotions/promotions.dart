import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Plain promotion rows. An admin panel can replace [_catalog] with the
/// same fields: title, detail, reward, window, and whether it is live.
class Promotions extends StatefulWidget {
  const Promotions({super.key});

  @override
  State<Promotions> createState() => _PromotionsState();
}

class _Promo {
  const _Promo({
    required this.id,
    required this.title,
    required this.detail,
    required this.reward,
    required this.window,
    required this.code,
  });

  final String id;
  final String title;
  final String detail;
  final String reward;
  final String window;
  final String code;
}

class _PromotionsState extends State<Promotions> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  static const List<_Promo> _catalog = [
    _Promo(
      id: 'weekday-peak',
      title: 'Weekday peak',
      detail: 'Complete 8 trips between 07:00 and 09:00.',
      reward: '+80 kr',
      window: 'Mon–Fri · this week',
      code: 'PEAK80',
    ),
    _Promo(
      id: 'airport',
      title: 'Airport runs',
      detail: 'Two airport trips in the same day.',
      reward: '+120 kr',
      window: 'Until Sunday',
      code: 'ARN120',
    ),
    _Promo(
      id: 'evening',
      title: 'Evening hours',
      detail: 'Stay online for 3 hours after 18:00.',
      reward: '+60 kr',
      window: 'Tonight',
      code: 'EVE60',
    ),
  ];

  final Set<String> _saved = {'airport'};
  int _tab = 0;

  List<_Promo> get _visible {
    if (_tab == 1) {
      return _catalog.where((item) => _saved.contains(item.id)).toList();
    }
    return _catalog;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(tooltip: 'Back', 
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        titleSpacing: 0,
        title: const Text(
          'Promotions preview',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _tabChip('Preview', 0),
                const SizedBox(width: 8),
                _tabChip('Saved', 1),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Nothing saved yet',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _card(items[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? _ink : _line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _card(_Promo promo) {
    final saved = _saved.contains(promo.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promo.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                promo.reward,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            promo.detail,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            promo.window,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: promo.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Demo code ${promo.code} copied'),
                      backgroundColor: _ink,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  promo.code,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (saved) {
                      _saved.remove(promo.id);
                    } else {
                      _saved.add(promo.id);
                    }
                  });
                },
                child: Text(
                  saved ? 'Saved' : 'Save',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
