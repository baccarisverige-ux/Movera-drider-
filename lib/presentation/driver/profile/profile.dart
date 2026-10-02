import 'package:flutter/material.dart';
import 'package:movera/core/privacy/local_data.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:movera/core/session/driver_runtime_scope.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/driver/analytics/analytics.dart';
import 'package:movera/presentation/driver/auth/starter/starter.dart';
import 'package:movera/presentation/driver/documents/documents.dart';
import 'package:movera/presentation/driver/my%20bank/my_bank.dart';
import 'package:movera/presentation/driver/profile/legal_document.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';
import 'package:movera/widgets/navigation_transition.dart';

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

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
        leading: IconButton(tooltip: 'Back', 
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        titleSpacing: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(tooltip: 'Settings', 
            onPressed: () {
              Navigator.push(context, RightToLeftTransition(const Settings()));
            },
            icon: const Icon(Icons.tune_rounded, color: _ink, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(AppAssets.profileImg),
                  backgroundColor: Color(0xFFECECEC),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample driver profile',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Demo — no verified account',
                        style: TextStyle(
                          color: _muted,
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
          const SizedBox(height: 12),
          FutureBuilder<({String vehicle, String plate})?>(
            future: LocalVehicleStore().primaryIdentity(),
            builder: (context, snapshot) => _link(
              context,
              icon: Icons.directions_car_outlined,
              title: 'Vehicles',
              detail: snapshot.data?.vehicle ?? 'Vehicle data unavailable',
              page: DriverVehicles(),
            ),
          ),
          const SizedBox(height: 12),
          _group(context, [
            _item(Icons.insights_outlined, 'Analytics', const Analytics()),
            _item(Icons.account_balance_outlined, 'My bank', const MyBank()),
            _item(
              Icons.description_outlined,
              'Documents',
              const DriverDocuments(),
            ),
          ]),
          const SizedBox(height: 12),
          _group(context, [
            _item(
              Icons.privacy_tip_outlined,
              'Privacy policy',
              LegalDocumentScreen.privacy,
            ),
            _item(
              Icons.article_outlined,
              'Terms of service',
              LegalDocumentScreen.terms,
            ),
            _item(
              Icons.help_outline_rounded,
              'Help center',
              const SupportInboxScreen(),
            ),
          ]),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _confirmLogout(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFB84F3D),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFB84F3D),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
    required Widget page,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.push(context, RightToLeftTransition(page)),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Icon(icon, color: _ink, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8BC)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, List<_ProfileItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          for (final item in items)
            InkWell(
              onTap: () =>
                  Navigator.push(context, RightToLeftTransition(item.page)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    Icon(item.icon, color: _ink, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
      ),
    );
  }

  _ProfileItem _item(IconData icon, String title, Widget page) {
    return _ProfileItem(icon, title, page);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Log out?'),
          content: const Text(
            'Local preview data on this device will be cleared, including trip history, contacts, and drafts. You will return to the sign-in screen offline.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF252E3A),
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
    if (leave == true && context.mounted) {
      final runtime = DriverRuntimeScope.maybeOf(context);
      try {
        if (runtime?.logout != null) {
          await runtime!.logout!();
        } else {
          await clearLocalUserData();
          runtime?.session.reset();
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not clear local data. You are still signed in. Please retry.'),
          ));
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DriverStarter()),
        (route) => false,
      );
    }
  }
}

class _ProfileItem {
  const _ProfileItem(this.icon, this.title, this.page);
  final IconData icon;
  final String title;
  final Widget page;
}
