import 'package:flutter/foundation.dart';

/// Single source of truth for driver availability during the app session.
///
/// Backend synchronization will plug into this controller later. Screens should
/// read/write availability here instead of owning independent online flags.
class DriverSessionController extends ChangeNotifier {
  DriverSessionController._();

  static final DriverSessionController instance = DriverSessionController._();

  bool _isOnline = false;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
  }

  void reset() {
    setOnline(false);
  }
}
