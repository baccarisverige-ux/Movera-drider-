import 'package:movera/widgets/single_route_entry.dart';
import 'package:movera/core/vehicle/vehicle_year_policy.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:image_picker/image_picker.dart';

class AddVehicle extends StatefulWidget {
  const AddVehicle({super.key});

  @override
  State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  final TextEditingController _make = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _plate = TextEditingController();
  String? _year;
  bool _saving = false;
  late final String _vehicleId =
      'local-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _make.addListener(_refresh);
    _model.addListener(_refresh);
    _plate.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _plate.dispose();
    super.dispose();
  }

  bool get _ready =>
      _make.text.trim().isNotEmpty &&
      _model.text.trim().isNotEmpty &&
      _year != null &&
      _plate.text.trim().isNotEmpty;

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final years = VehicleYearPolicy.choices(
          now: DateTime.now(),
          selected: _year,
        );
        return ListView(
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Year',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final year in years)
              ListTile(
                title: Text(year),
                onTap: () => Navigator.pop(context, year),
              ),
          ],
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _year = picked);
  }

  @override
  Widget build(BuildContext context) {
    final showModel = _make.text.trim().isNotEmpty;
    final showYear = showModel && _model.text.trim().isNotEmpty;
    final showPlate = showYear && _year != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                const Text(
                  'Vehicle requirements',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'To drive with Movera, you need a vehicle that is 1990 or newer, and not salvaged.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Enter your vehicle information',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),
                _field(
                  label: 'Make',
                  child: TextField(
                    controller: _make,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _input('Search by make'),
                  ),
                ),
                if (showModel) ...[
                  const SizedBox(height: 16),
                  _field(
                    label: 'Model',
                    child: TextField(
                      controller: _model,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _input('Search by model'),
                    ),
                  ),
                ],
                if (showYear) ...[
                  const SizedBox(height: 16),
                  _field(
                    label: 'Year',
                    child: InkWell(
                      onTap: _pickYear,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _input('Select...'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _year ?? 'Select...',
                                style: TextStyle(
                                  color: _year == null ? _muted : _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (showPlate) ...[
                  const SizedBox(height: 16),
                  _field(
                    label: 'License plate number',
                    child: TextField(
                      controller: _plate,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _input(''),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  '* Required',
                  style: TextStyle(
                    color: Color(0xFFB84F3D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _ready && !_saving
                    ? () async {
                        setState(() => _saving = true);
                        try {
                          await LocalVehicleStore().upsert({
                            'id': _vehicleId,
                            'make': _make.text.trim(),
                            'model': _model.text.trim(),
                            'year': _year!,
                            'plate': _plate.text.trim(),
                          });
                          if (!context.mounted) {
                            return;
                          }
                          await pushSingle(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => VehicleDocuments(
                                vehicleId: _vehicleId,
                                make: _make.text.trim(),
                                model: _model.text.trim(),
                                year: _year!,
                                plate: _plate.text.trim(),
                              ),
                            ),
                          );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not save local vehicle draft. Retry.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  disabledBackgroundColor: const Color(0xFFE8EAEC),
                  disabledForegroundColor: const Color(0xFFB0B6BA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFB84F3D)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFF4F6F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _ink, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _line),
      ),
    );
  }
}

class VehicleDocuments extends StatefulWidget {
  const VehicleDocuments({
    super.key,
    this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    this.store,
  });

  final String? vehicleId;
  final String make;
  final String model;
  final String year;
  final String plate;
  final LocalVehicleStore? store;

  @override
  State<VehicleDocuments> createState() => _VehicleDocumentsState();
}

class _VehicleDocumentsState extends State<VehicleDocuments> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _line = Color(0xFFE6E8EA);

  late final _store = widget.store ?? LocalVehicleStore();
  Map<String, dynamic>? _draft;
  bool _busy = false;
  bool _loading = true;
  bool _restoring = false;
  bool _restoreFailed = false;
  bool get _canEdit => !_loading && !_restoreFailed && !_busy && _draft != null;
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    if (_restoring || _busy || !mounted) {
      return;
    }
    _restoring = true;
    setState(() {
      _loading = true;
      _restoreFailed = false;
    });
    try {
      final rows = await _store.list();
      final matching = rows.where((row) => row['id'] == widget.vehicleId);
      if (mounted) {
        setState(() {
          _draft = matching.isEmpty ? null : matching.first;
          _registrationDone = _draft?['registrationPhoto'] is String;
          _insuranceDone = _draft?['insurancePhoto'] is String;
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
    } finally {
      _restoring = false;
    }
  }

  bool _registrationDone = false;
  bool _insuranceDone = false;

  String get _name => '${widget.make} ${widget.model}'.toUpperCase();

  Future<void> _openPhoto({
    required String title,
    required List<String> checks,
    required bool registration,
  }) async {
    if (!_canEdit) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _openPhotoOwned(
        title: title,
        checks: checks,
        registration: registration,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openPhotoOwned({
    required String title,
    required List<String> checks,
    required bool registration,
  }) async {
    final saved = await pushSingle<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => _VehiclePhotoPage(title: title, checks: checks),
      ),
    );
    if (saved == null || !mounted) {
      return;
    }
    final updated = {
      ..._draft!,
      (registration ? 'registrationPhoto' : 'insurancePhoto'): base64Encode(
        saved,
      ),
    };
    try {
      await _store.upsert(updated);
      if (!mounted) {
        return;
      }
      _draft = updated;
    } on VehiclePhotoBudgetExceeded catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo could not be saved locally. Retry.'),
          ),
        );
      }
      return;
    }
    setState(() {
      if (registration) {
        _registrationDone = true;
      } else {
        _insuranceDone = true;
      }
    });
  }

  Future<void> _confirmRemove() async {
    if (!_canEdit || widget.vehicleId == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _removeOwned();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeOwned() async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Remove local vehicle draft?',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This removes $_name and its saved document photos from this device.',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Keep vehicle',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC4473A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Remove vehicle',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (remove == true && mounted && widget.vehicleId != null) {
      try {
        await _store.remove(widget.vehicleId!);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not remove local draft. Retry.'),
            ),
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            _name,
            style: const TextStyle(
              color: _ink,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Document photos stay on this device. No upload or verification service is connected.',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_restoreFailed) ...[
            const Text('Could not load local vehicle documents.'),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _restore,
                child: const Text('Retry'),
              ),
            ),
          ],
          if (!_loading && !_restoreFailed && _draft == null)
            const Text('This local vehicle draft is no longer available.'),
          _docRow(
            title: 'Vehicle Registration Certificate (Front Page)',
            note: _registrationDone
                ? 'Saved locally — not verified'
                : 'Recommended next step',
            noteColor: _registrationDone
                ? const Color(0xFF1F7A4D)
                : const Color(0xFF3D5A80),
            onTap: !_canEdit
                ? null
                : () => _openPhoto(
                    title: 'Take a photo of your Vehicle Registration Certificate (Front Page)',
                    checks: const [
                      'The document should be blue, black and white.',
                      'All four corners are visible.',
                    ],
                    registration: true,
                  ),
          ),
          const Divider(height: 1, color: _line),
          _docRow(
            title: 'Insurance Letter',
            note: _insuranceDone ? 'Saved locally — not verified' : null,
            noteColor: const Color(0xFF1F7A4D),
            onTap: !_canEdit
                ? null
                : () => _openPhoto(
                    title: 'Take a photo of your Insurance Letter',
                    checks: const [
                      'The document shows the car’s registration number and that it is registered as a taxi.',
                      'The start and end dates of the insurance are visible.',
                    ],
                    registration: false,
                  ),
          ),
          for (final key in ['registrationPhoto', 'insurancePhoto'])
            if (_draft?[key] is String)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.memory(
                  base64Decode(_draft![key] as String),
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: _canEdit ? _confirmRemove : null,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4F6F7),
                foregroundColor: const Color(0xFFC4473A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Remove vehicle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow({
    required String title,
    required VoidCallback? onTap,
    String? note,
    Color? noteColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: TextStyle(
                        color: noteColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8BC)),
          ],
        ),
      ),
    );
  }
}

class _VehiclePhotoPage extends StatelessWidget {
  const _VehiclePhotoPage({required this.title, required this.checks});

  final String title;
  final List<String> checks;

  static const Color _ink = Color(0xFF252E3A);

  Future<void> _take(BuildContext context) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1024,
      );
      if (!context.mounted) {
        return;
      }
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!context.mounted) {
          return;
        }
        if (bytes.length > LocalVehicleStore.maxPhotoBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo is too large to keep on this device. Retake it closer and with less detail.',
              ),
            ),
          );
          return;
        }
        Navigator.pop(context, bytes);
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not available in this preview.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E8EA)),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF8A949A),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Before saving the local photo, check the following:',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final check in checks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(color: _ink)),
                        Expanded(
                          child: Text(
                            check,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => _take(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Take photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
