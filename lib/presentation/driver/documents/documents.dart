import 'package:flutter/material.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/upload%20document/select%20document%20type/select_doc_typ.dart';
import 'package:movera/widgets/navigation_transition.dart';

class DriverDocuments extends StatelessWidget {
  const DriverDocuments({super.key});

  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        titleSpacing: 0,
        title: const Text(
          'Documents',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHERE YOU DRIVE',
                  style: TextStyle(
                    color: Color(0xFFB7C0C6),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Stockholm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Trips with a car · all of Sweden',
                  style: TextStyle(
                    color: Color(0xFFD5DCE0),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Driver',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _group(context, const [
            _Doc('Terms', 'Accepted', true),
            _Doc('Information session', 'Done', true),
            _Doc('Driving licence', 'On file', true),
            _Doc('Profile photo', 'On file', true),
            _Doc('Tax details', 'On file', true),
          ]),
          const SizedBox(height: 18),
          const Text(
            'Mercedes-Benz C200',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _group(context, const [
            _Doc('Registration', 'On file', true),
            _Doc('Insurance', 'Needs a new copy', false),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, List<_Doc> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _line),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  RightToLeftTransition(const SelectDocumentType()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        items[i].title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      items[i].status,
                      style: TextStyle(
                        color: items[i].ready ? _muted : const Color(0xFFB84F3D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB0B8BC),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Doc {
  const _Doc(this.title, this.status, this.ready);
  final String title;
  final String status;
  final bool ready;
}
