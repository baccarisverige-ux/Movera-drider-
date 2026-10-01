import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/movera_map_style_lab.dart';

class MoveraMapColorLabScreen extends StatefulWidget {
  const MoveraMapColorLabScreen({super.key});

  @override
  State<MoveraMapColorLabScreen> createState() =>
      _MoveraMapColorLabScreenState();
}

class _MoveraMapColorLabScreenState extends State<MoveraMapColorLabScreen> {
  final MoveraMapStyleController _style = MoveraMapStyleController.instance;
  final TextEditingController _hexController = TextEditingController();
  final FocusNode _hexFocus = FocusNode();

  String _selectedKey = 'land';
  String? _message;

  @override
  void initState() {
    super.initState();
    _style.addListener(_handleStyleChanged);
    _syncHexField();
    unawaited(_style.ensureLoaded());
  }

  @override
  void dispose() {
    _style.removeListener(_handleStyleChanged);
    _hexController.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  void _handleStyleChanged() {
    if (!mounted) {
      return;
    }
    if (!_hexFocus.hasFocus) {
      _syncHexField();
    }
    setState(() {});
  }

  void _syncHexField() {
    final next = _style.colorHex(_selectedKey);
    if (_hexController.text != next) {
      _hexController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  void _selectField(String key) {
    setState(() {
      _selectedKey = key;
      _message = null;
    });
    _syncHexField();
  }

  int _channel(Color color, int shift) =>
      (color.toARGB32() >> shift) & 0xFF;

  void _setChannel(int shift, double value) {
    final current = _style.color(_selectedKey);
    final argb = current.toARGB32();
    var red = (argb >> 16) & 0xFF;
    var green = (argb >> 8) & 0xFF;
    var blue = argb & 0xFF;
    final next = value.round().clamp(0, 255);
    if (shift == 16) {
      red = next;
    } else if (shift == 8) {
      green = next;
    } else {
      blue = next;
    }
    _style.setColor(_selectedKey, Color.fromARGB(255, red, green, blue));
  }

  void _applyHex() {
    final ok = _style.setHex(_selectedKey, _hexController.text);
    setState(() {
      _message = ok
          ? 'Applied live'
          : 'Use a 6-digit HEX value, for example #9FD2F3';
    });
    if (ok) {
      _syncHexField();
      _hexFocus.unfocus();
    }
  }

  Future<void> _save() async {
    try {
      await _style.save();
      if (!mounted) {
        return;
      }
      setState(() => _message = 'Saved on this device');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _message = 'Could not save locally');
    }
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: _style.styleJson));
    if (!mounted) {
      return;
    }
    setState(() => _message = 'Map style JSON copied');
  }

  @override
  Widget build(BuildContext context) {
    final selected = _style.color(_selectedKey);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const CustomGoogleMap(
            initialPosition: CameraPosition(
              target: LatLng(59.3293, 18.0686),
              zoom: 13.2,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapType: MapType.normal,
          ),
          Positioned(
            top: top + 10,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.96),
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Map Color Lab',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Move the real map and tune the palette live',
                            style: TextStyle(
                              color: Color(0xFF68737A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reset current Movera colors',
                      onPressed: () {
                        _style.resetDefaults();
                        setState(
                          () => _message = 'Reset to current Movera palette',
                        );
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                    IconButton(
                      tooltip: 'Save palette',
                      onPressed: _save,
                      icon: Icon(
                        _style.isDirty
                            ? Icons.save_outlined
                            : Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            minChildSize: 0.20,
            initialChildSize: 0.43,
            maxChildSize: 0.78,
            snap: true,
            snapSizes: const [0.20, 0.43, 0.78],
            builder: (context, scrollController) {
              return Material(
                color: Colors.white,
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4D9DC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Live palette',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _copyJson,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy JSON'),
                        ),
                      ],
                    ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _message!,
                          style: const TextStyle(
                            color: Color(0xFF526069),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    _buildEditor(selected),
                    const SizedBox(height: 12),
                    const Text(
                      'Map layers',
                      style: TextStyle(
                        color: Color(0xFF727E85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...MoveraMapStyleController.fields.map(_buildFieldTile),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(Color color) {
    final field = MoveraMapStyleController.fields
        .firstWhere((item) => item.key == _selectedKey);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      field.description,
                      style: const TextStyle(
                        color: Color(0xFF738087),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                child: TextField(
                  controller: _hexController,
                  focusNode: _hexFocus,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _applyHex(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 9,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD9DEE1)),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Apply HEX',
                      onPressed: _applyHex,
                      icon: const Icon(Icons.check_rounded, size: 17),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _rgbSlider(
            label: 'R',
            value: _channel(color, 16),
            onChanged: (value) => _setChannel(16, value),
          ),
          _rgbSlider(
            label: 'G',
            value: _channel(color, 8),
            onChanged: (value) => _setChannel(8, value),
          ),
          _rgbSlider(
            label: 'B',
            value: _channel(color, 0),
            onChanged: (value) => _setChannel(0, value),
          ),
        ],
      ),
    );
  }

  Widget _rgbSlider({
    required String label,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value.toDouble(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF637077),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTile(MoveraMapStyleField field) {
    final selected = field.key == _selectedKey;
    final color = _style.color(field.key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFF0F4F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _selectField(field.key),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _style.colorHex(field.key),
                        style: const TextStyle(
                          color: Color(0xFF7B858B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Color(0xFF3B6254),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
