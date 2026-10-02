import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoveraMapStyleField {
  const MoveraMapStyleField({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

class MoveraMapStyleController extends ChangeNotifier {
  MoveraMapStyleController._();

  static final MoveraMapStyleController instance = MoveraMapStyleController._();

  static const String _storageKey = 'movera.map_color_lab.palette.v1';

  static const List<MoveraMapStyleField> fields = [
    MoveraMapStyleField(key: 'land', label: 'Land / background', description: 'Base map and landscape'),
    MoveraMapStyleField(key: 'labels', label: 'Labels', description: 'Street and place text'),
    MoveraMapStyleField(key: 'labelStroke', label: 'Label halo', description: 'Outline behind map text'),
    MoveraMapStyleField(key: 'administrative', label: 'Boundaries', description: 'Administrative lines'),
    MoveraMapStyleField(key: 'manMade', label: 'Built areas', description: 'Man-made landscape geometry'),
    MoveraMapStyleField(key: 'poi', label: 'POI areas', description: 'General points-of-interest geometry'),
    MoveraMapStyleField(key: 'park', label: 'Parks', description: 'Park and green-space geometry'),
    MoveraMapStyleField(key: 'road', label: 'Local roads', description: 'Normal street surface'),
    MoveraMapStyleField(key: 'roadStroke', label: 'Local road edge', description: 'Normal street border'),
    MoveraMapStyleField(key: 'arterial', label: 'Main roads', description: 'Arterial road surface'),
    MoveraMapStyleField(key: 'arterialStroke', label: 'Main road edge', description: 'Arterial road border'),
    MoveraMapStyleField(key: 'highway', label: 'Highways', description: 'Highway surface'),
    MoveraMapStyleField(key: 'highwayStroke', label: 'Highway edge', description: 'Highway border'),
    MoveraMapStyleField(key: 'transit', label: 'Transit', description: 'Rail and transit geometry'),
    MoveraMapStyleField(key: 'water', label: 'Water', description: 'Sea, lakes, and waterways'),
    MoveraMapStyleField(key: 'waterLabel', label: 'Water labels', description: 'Text displayed over water'),
  ];

  static const Map<String, String> defaults = {
    'land': '#E6EAED',
    'labels': '#536170',
    'labelStroke': '#F4F6F7',
    'administrative': '#9CA8B3',
    'manMade': '#E3E7EA',
    'poi': '#E2E7E9',
    'park': '#D8E9DF',
    'road': '#F8FAFB',
    'roadStroke': '#D5DBE0',
    'arterial': '#9BB1DD',
    'arterialStroke': '#879FD1',
    'highway': '#8FA8DC',
    'highwayStroke': '#7893CB',
    'transit': '#CFD6DD',
    'water': '#9FD2F3',
    'waterLabel': '#197A91',
  };

  Map<String, String> _colors = Map<String, String>.from(defaults);
  bool _loaded = false;
  bool _dirty = false;

  bool get isDirty => _dirty;
  Map<String, String> get colors => Map<String, String>.unmodifiable(_colors);

  String colorHex(String key) => _colors[key] ?? defaults[key] ?? '#000000';

  Color color(String key) {
    final hex = colorHex(key);
    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final next = Map<String, String>.from(defaults);
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value.toString().toUpperCase();
        if (defaults.containsKey(key) && _isHex(value)) {
          next[key] = value;
        }
      }
      _colors = next;
      _dirty = false;
      notifyListeners();
    } catch (_) {
      // The editor is optional. A storage failure must never block the map.
    }
  }

  void setColor(String key, Color value) {
    if (!defaults.containsKey(key)) {
      return;
    }
    final hex = _hexFromColor(value);
    if (_colors[key] == hex) {
      return;
    }
    _colors = Map<String, String>.from(_colors)..[key] = hex;
    _dirty = true;
    notifyListeners();
  }

  bool setHex(String key, String raw) {
    final normalized = raw.trim().toUpperCase();
    final value = normalized.startsWith('#') ? normalized : '#$normalized';
    if (!defaults.containsKey(key) || !_isHex(value)) {
      return false;
    }
    if (_colors[key] == value) {
      return true;
    }
    _colors = Map<String, String>.from(_colors)..[key] = value;
    _dirty = true;
    notifyListeners();
    return true;
  }

  void resetDefaults() {
    _colors = Map<String, String>.from(defaults);
    _dirty = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_colors));
    _dirty = false;
    notifyListeners();
  }

  String get styleJson {
    String v(String key) => colorHex(key).toLowerCase();
    return '''
[
  {"elementType":"geometry","stylers":[{"color":"${v('land')}"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"${v('labels')}"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"${v('labelStroke')}"},{"weight":2}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"${v('administrative')}"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"${v('land')}"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"${v('manMade')}"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"${v('poi')}"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"${v('park')}"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"${v('road')}"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"${v('roadStroke')}"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"${v('arterial')}"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"${v('arterialStroke')}"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"${v('highway')}"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"${v('highwayStroke')}"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"${v('transit')}"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"${v('water')}"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"${v('waterLabel')}"}]}
]
''';
  }

  static bool _isHex(String value) =>
      RegExp(r'^#[0-9A-F]{6}$').hasMatch(value);

  static String _hexFromColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
