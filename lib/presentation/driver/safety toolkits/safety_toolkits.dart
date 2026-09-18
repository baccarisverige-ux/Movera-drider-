import 'package:flutter/material.dart';

Future<T?> showSafetyToolKitSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF172027).withOpacity(0.30),
    builder: (_) => const SafetyToolKits(),
  );
}

class SafetyToolKits extends StatefulWidget {
  const SafetyToolKits({super.key});

  @override
  State<SafetyToolKits> createState() => _SafetyToolKitsState();
}

class _SafetyToolKitsState extends State<SafetyToolKits> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _green = Color(0xFF19865C);
  static const Color _line = Color(0xFFE5E9EB);
  static const Color _canvas = Color(0xFFF4F6F7);

  bool _isRecording = false;
  bool _tripSharing = false;
  bool _pinRequired = true;
  bool _autoShare = false;
  bool _rideCheck = true;
  String? _status;

  void _showMessage(String message) {
    setState(() => _status = message);
  }

  Future<void> _confirmEmergencyCall() async {
    final call = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Contact emergency services?',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Use 112 only when you or someone else needs immediate help.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCB424B),
              ),
              child: const Text('Call 112'),
            ),
          ],
        );
      },
    );

    if (call == true && mounted) {
      _showMessage('Emergency call is ready to open on your phone.');
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      _status = _isRecording
          ? 'Audio recording started. The file stays on this device.'
          : 'Audio recording saved on this device.';
    });
  }

  void _shareTrip() {
    setState(() {
      _tripSharing = true;
      _status = 'Trip sharing is ready for your trusted contacts.';
    });
  }

  Future<void> _openPreferences() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback change) {
              setState(change);
              setSheetState(() {});
            }

            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                decoration: const BoxDecoration(
                  color: _canvas,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6DDE0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety preferences',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Set how Movera protects every trip',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: _muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _preferenceTile(
                      icon: Icons.pin_outlined,
                      title: 'PIN verification',
                      subtitle: 'Confirm the correct rider before starting',
                      value: _pinRequired,
                      onChanged: (value) {
                        update(() => _pinRequired = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    _preferenceTile(
                      icon: Icons.ios_share_outlined,
                      title: 'Automatic trip sharing',
                      subtitle: 'Share active trips with trusted contacts',
                      value: _autoShare,
                      onChanged: (value) {
                        update(() => _autoShare = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    _preferenceTile(
                      icon: Icons.route_outlined,
                      title: 'RideCheck alerts',
                      subtitle: 'Detect unusual stops or route changes',
                      value: _rideCheck,
                      onChanged: (value) {
                        update(() => _rideCheck = value);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _preferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4D5A61), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: _green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
        decoration: const BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DDE0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: _ink,
                  tooltip: 'Close',
                ),
                const Expanded(
                  child: Text(
                    'Safety',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Safety tools',
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quick tools designed to protect you during every ride.',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SafetyToolButton(
                    icon: Icons.call_outlined,
                    label: 'Contact 112',
                    onTap: _confirmEmergencyCall,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _SafetyToolButton(
                    icon: _isRecording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_outlined,
                    label: _isRecording ? 'Stop audio' : 'Record audio',
                    active: _isRecording,
                    onTap: _toggleRecording,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _SafetyToolButton(
                    icon: Icons.ios_share_outlined,
                    label: 'Share trip',
                    active: _tripSharing,
                    onTap: _shareTrip,
                  ),
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: _green,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status!,
                        style: const TextStyle(
                          color: Color(0xFF496158),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openPreferences,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: _line),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 22,
                        color: Color(0xFF4D5A61),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety preferences',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'PIN, trip sharing and RideCheck',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF98A3A8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyToolButton extends StatelessWidget {
  const _SafetyToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF19865C);
    const ink = Color(0xFF252E3A);

    return Material(
      color: active ? const Color(0xFFE5F4ED) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? const Color(0xFFB9DDCD) : const Color(0xFFE5E9EB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? green : const Color(0xFF45525A),
                size: 23,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: active ? green : ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
