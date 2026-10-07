import 'package:flutter/material.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key, this.repository});
  final SettingsRepository? repository;

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContact {
  const _EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String name;
  final String phone;
  final String relation;
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);

  final List<_EmergencyContact> _contacts = [
    const _EmergencyContact(
      name: 'Emergency services — 112',
      phone: '112',
      relation: 'Emergency',
    ),
  ];

  late final _settings = widget.repository ?? SettingsRepository();
  bool _loading = true;
  bool _restoreFailed = false;
  bool _adding = false;
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _restoreFailed = false;
      });
    }
    try {
      final data = await _settings.read('contacts');
      final rows = data['rows'];
      if (mounted) {
        setState(() {
          if (rows is List) {
            _contacts.removeWhere((c) => c.phone != '112');
            for (final row in rows) {
              if (row is Map &&
                  row['name'] is String &&
                  row['phone'] is String &&
                  _validPhone(row['phone'] as String)) {
                _contacts.add(
                  _EmergencyContact(
                    name: row['name'] as String,
                    phone: row['phone'] as String,
                    relation: row['relation'] is String
                        ? row['relation'] as String
                        : 'Trusted contact',
                  ),
                );
              }
            }
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _restoreFailed = true;
        });
      }
    }
  }

  bool _validPhone(String phone) =>
      RegExp(r'^\+?[0-9]{7,15}$')
          .hasMatch(phone.replaceAll(RegExp(r'[\s()-]'), '')) ||
      phone == '112';
  Future<void> _addContact() async {
    if (_loading || _restoreFailed || _adding) return;
    setState(() => _adding = true);
    try {
      final created = await showModalBottomSheet<_EmergencyContact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _ContactComposer(validPhone: _validPhone),
      );
      if (created != null && mounted) {
        final updated = [..._contacts, created];
        try {
          await _settings.save('contacts', {
            'rows': updated
                .where((c) => c.phone != '112')
                .map(
                  (c) => {
                    'name': c.name,
                    'phone': c.phone,
                    'relation': c.relation,
                  },
                )
                .toList(),
          });
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact could not be saved. Retry.'),
              ),
            );
          }
          return;
        }
        if (mounted) {
          setState(() => _contacts.add(created));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  Future<void> _call(_EmergencyContact contact) async {
    final uri = Uri.parse(
      'tel:${contact.phone.replaceAll(RegExp(r'[^0-9+]'), '')}',
    );
    try {
      if (!await launchUrl(uri) && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dialer is unavailable.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dialer is unavailable.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: 'Emergency contacts',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwMedium,
        ),
        actions: [
          IconButton(
            tooltip: 'Add trusted contact',
            key: const ValueKey<String>('add-emergency-contact'),
            onPressed: _loading || _restoreFailed || _adding
                ? null
                : _addContact,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF19865C)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_restoreFailed)
            TextButton(
              onPressed: _restore,
              child: const Text('Could not load trusted contacts — Retry'),
            ),
          const Text(
            'Trusted contacts stay on this device. Calling opens your dialer.',
            style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final contact in _contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFFF7FBF9),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text('${contact.relation} · ${contact.phone}'),
                  trailing: IconButton(
                    tooltip: 'Call ${contact.name}',
                    icon: const Icon(Icons.phone_outlined),
                    onPressed: () => _call(contact),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactComposer extends StatefulWidget {
  const _ContactComposer({required this.validPhone});
  final bool Function(String) validPhone;
  @override
  State<_ContactComposer> createState() => _ContactComposerState();
}

class _ContactComposerState extends State<_ContactComposer> {
  final _form = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final relation = TextEditingController(text: 'Family');
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add trusted contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) => widget.validPhone(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid phone number',
                ),
                TextFormField(
                  controller: relation,
                  decoration: const InputDecoration(labelText: 'Relation'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      _EmergencyContact(
                        name: name.text.trim(),
                        phone: phone.text.trim(),
                        relation: relation.text.trim().isEmpty
                            ? 'Trusted contact'
                            : relation.text.trim(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF19865C),
                  ),
                  child: const Text('Save contact'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
