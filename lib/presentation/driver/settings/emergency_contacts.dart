import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

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
      name: 'Anna Johansson',
      phone: '+46 70 123 45 67',
      relation: 'Partner',
    ),
    const _EmergencyContact(
      name: 'Movera Safety desk',
      phone: '112',
      relation: 'Emergency',
    ),
  ];

  Future<void> _addContact() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final relation = TextEditingController(text: 'Family');
    final created = await showModalBottomSheet<_EmergencyContact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add trusted contact',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: relation,
                decoration: const InputDecoration(labelText: 'Relation'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      sheetContext,
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
              ),
            ],
          ),
        );
      },
    );
    name.dispose();
    phone.dispose();
    relation.dispose();
    if (created != null && mounted) {
      setState(() => _contacts.add(created));
    }
  }

  Future<void> _call(_EmergencyContact contact) async {
    final uri = Uri.parse(
      'tel:${contact.phone.replaceAll(RegExp(r'[^0-9+]'), '')}',
    );
    await launchUrl(uri);
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
            key: const ValueKey<String>('add-emergency-contact'),
            onPressed: _addContact,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF19865C)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          const Text(
            'These people can be reached from Safety tools. Contacts stay on this device.',
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
