import 'package:flutter/material.dart';
import 'document_preview.dart';
import 'package:movera/widgets/navigation_transition.dart';

class DriverDocuments extends StatelessWidget {
  const DriverDocuments({super.key});

  static const Color _ink = Color(0xFF252E3A);
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
                  'Stockholm · Trips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Can earn in: All of Sweden',
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
            'Driver requirements',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _group(context, const [
            _Doc('Terms and Conditions', 'Not verified', true),
            _Doc('Virtual information session', 'Not verified', true),
            _Doc('Driver’s License', 'Not verified', true),
            _Doc('Profile photo', 'Not verified', true),
            _Doc(
              'Registration certificate from Bolagsverket (for AB, KB or HB) or register extract from Skatteverket (in the case of a sole proprietorship) (NOT needed if you deliver for a Fleet Partner)',
              'Not verified',
              true,
            ),
            _Doc('Taxi Driver License', 'Not verified', true),
            _Doc('Taxi Traffic Permit', 'Not verified', true),
            _Doc('Tax settings', 'Not verified', true),
            _Doc('Bank statement', 'Not verified', true),
          ]),
          const SizedBox(height: 18),
          const Text(
            'Sample vehicle documents',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _group(context, const [
            _Doc(
              'Vehicle Registration Certificate (Front Page)',
              'Not verified',
              true,
            ),
            _Doc('Insurance Letter', 'Not verified', true),
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
                  RightToLeftTransition(DocumentPreview(title: items[i].title)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        items[i].title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        items[i].status,
                        style: TextStyle(
                          color: items[i].ready
                              ? const Color(0xFF1F7A4D)
                              : const Color(0xFFB84F3D),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
