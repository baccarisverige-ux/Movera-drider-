import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/session/driver_session_repository.dart';

/// Single source of truth for driver availability during one app/session flow.
///
/// The composition root owns this controller and injects it into screens that
/// need driver availability. A backend synchronization adapter can attach here
/// later without giving individual screens their own online flags.
class DriverSessionController extends ChangeNotifier {
  DriverSessionController({
    bool initialOnline = false,
    DriverSessionRepository? repository,
  })  : _isOnline = initialOnline,
        _repository = repository ?? MemoryDriverSessionRepository();

  final DriverSessionRepository _repository;
  bool _isOnline;
  bool _resumeHomeAfterTrip = false;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
    unawaited(_repository.saveOnline(value));
  }

  Future<void> restore() async {
    final stored = await _repository.readOnline();
    if (stored == null || stored == _isOnline) return;
    _isOnline = stored;
    notifyListeners();
  }

  void stayOnlineAfterTrip() {
    _resumeHomeAfterTrip = true;
    if (!_isOnline) {
      _isOnline = true;
      unawaited(_repository.saveOnline(true));
    }
    notifyListeners();
  }

  bool consumeResumeHomeAfterTrip() {
    if (!_resumeHomeAfterTrip) return false;
    _resumeHomeAfterTrip = false;
    return true;
  }

  void reset() {
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
    unawaited(_repository.clear());
  }
}
