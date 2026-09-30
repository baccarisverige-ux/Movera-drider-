import 'package:flutter/material.dart';
import 'package:movera/presentation/driver/pin%20verification/pin_verification.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/settings/accessibility/accessibility.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';
import 'package:movera/presentation/driver/settings/sound%20&%20voice/sound_voice.dart';
import 'package:movera/widgets/navigation_transition.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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
          'App settings',
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
          _group([
            _row(
              icon: Icons.volume_up_outlined,
              title: 'Sound & voice',
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const SoundAndVoice()),
              ),
            ),
            _row(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              detail: 'Unavailable in demo',
            ),
            _row(
              icon: Icons.language_rounded,
              title: 'Language',
              detail: 'English (US) only',
            ),
          ]),
          const SizedBox(height: 12),
          _group([
            _row(
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility',
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const Accessibility()),
              ),
            ),
            _row(
              icon: Icons.pin_outlined,
              title: 'Pin verification',
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const PinVerification()),
              ),
            ),
            _row(
              icon: Icons.contact_phone_outlined,
              title: 'Emergency contacts',
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const EmergencyContactsScreen()),
              ),
            ),
            _row(
              icon: Icons.shield_outlined,
              title: 'Safety',
              onTap: () => showSafetyToolKitSheet(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    String? detail,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (detail != null)
              Flexible(child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  detail,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB0B8BC),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

}
