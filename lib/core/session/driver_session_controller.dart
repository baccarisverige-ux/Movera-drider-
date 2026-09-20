import 'package:flutter/foundation.dart';

/// Single source of truth for driver availability during one app/session flow.
///
/// The composition root owns this controller and injects it into screens that
/// need driver availability. A backend synchronization adapter can attach here
/// later without giving individual screens their own online flags.
class DriverSessionController extends ChangeNotifier {
  DriverSessionController({
    bool initialOnline = false,
  }) : _isOnline = initialOnline;

  bool _isOnline;

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
