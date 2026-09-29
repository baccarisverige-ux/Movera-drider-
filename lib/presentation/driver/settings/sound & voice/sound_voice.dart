import 'package:flutter/material.dart';

class SoundAndVoice extends StatefulWidget {
  const SoundAndVoice({super.key});

  @override
  State<SoundAndVoice> createState() => _SoundAndVoiceState();
}

class _SoundAndVoiceState extends State<SoundAndVoice> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  double generalVolume = 0.35;
  bool alwaysPlayRequests = true;
  bool voiceNavigation = true;
  bool readRiderMessages = false;

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
          'Sound & voice',
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
          _card(
            children: [
              const Text(
                'Volume',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Slider(
                value: generalVolume,
                activeColor: _ink,
                onChanged: (value) => setState(() => generalVolume = value),
              ),
              _switchRow(
                'Always play trip requests',
                'Plays even when the phone is silent',
                alwaysPlayRequests,
                (value) => setState(() => alwaysPlayRequests = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _card(
            children: [
              const Text(
                'Voice',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _switchRow(
                'Voice navigation',
                'Spoken turns while you drive',
                voiceNavigation,
                (value) => setState(() => voiceNavigation = value),
              ),
              _switchRow(
                'Read rider messages',
                'Reads new chat messages aloud',
                readRiderMessages,
                (value) => setState(() => readRiderMessages = value),
              ),
              const SizedBox(height: 8),
              _test('Test alerts', _onTestAlerts),
              const SizedBox(height: 8),
              _test('Test voice', _onTestVoice),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _switchRow(
    String title,
    String detail,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: _ink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _test(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _onTestAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing alert sound (mock)')),
    );
  }

  void _onTestVoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing voice sound (mock)')),
    );
  }
}
