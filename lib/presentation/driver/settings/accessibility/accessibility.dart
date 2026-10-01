import 'package:movera/core/settings/settings_repository.dart';
import 'package:flutter/material.dart';

class Accessibility extends StatefulWidget {
  const Accessibility({super.key});

  @override
  State<Accessibility> createState() => _AccessibilityState();
}

class _AccessibilityState extends State<Accessibility> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  bool _flash = false;
  bool _vibration = false;

  final _settings = SettingsRepository();
  bool _settingsTouched = false;
  Future<void> _restoreSettings() async {
    try {
    final data=await _settings.read('accessibility'); if(!mounted || _settingsTouched) { return; }
    setState(() { if(data['flash'] is bool) { _flash=data['flash'] as bool; }if(data['vibration'] is bool) { _vibration=data['vibration'] as bool; } });
      } catch (_) {
      if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not load saved preferences.'),
        action: SnackBarAction(label:'Retry',onPressed:_restoreSettings))); }
    }
  }
  Future<bool> _persistSettings() async {
    _settingsTouched=true;
    try { await _settings.save('accessibility',{'flash':_flash,'vibration':_vibration}); return true; }
    catch(_) { if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save preferences. Retry.'))); } return false; }
  }

  @override
  void initState() { super.initState(); _restoreSettings(); }

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
          'Accessibility',
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
          const Text('Local demo preferences — saved on this device; effects are previews.'),
          _tile(
            title: 'Hearing',
            detail: 'Tell riders if you are deaf or hard of hearing.',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8BC)),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Hearing'),
                    content: const Text(
                      'Demo preview — no information is shared with riders.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Not now'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: FilledButton.styleFrom(backgroundColor: _ink),
                        child: const Text('Close preview'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          _tile(
            title: 'Flash for requests',
            detail: 'The screen flashes when a request arrives.',
            trailing: Switch.adaptive(
              value: _flash,
              activeTrackColor: _ink,
              onChanged: (value) { setState(() => _flash = value); _persistSettings(); },
            ),
          ),
          const SizedBox(height: 10),
          _tile(
            title: 'Vibration for requests',
            detail: 'The phone vibrates when a request arrives.',
            trailing: Switch.adaptive(
              value: _vibration,
              activeTrackColor: _ink,
              onChanged: (value) { setState(() => _vibration = value); _persistSettings(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String detail,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
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
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
