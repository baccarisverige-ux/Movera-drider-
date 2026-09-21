import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/session/driver_session_repository.dart';

/// Canonical driver availability (P1 / D10).
enum DriverOnlineStatus {
  offline,
  goingOnline,
  online,
  onTrip,
  suspended,
}

/// Single source of truth for driver availability during one app/session flow.
///
/// The composition root owns this controller and injects it into screens that
/// need driver availability. A backend synchronization adapter can attach here
/// later without giving individual screens their own online flags.
class DriverSessionController extends ChangeNotifier {
  DriverSessionController({
    bool initialOnline = false,
    DriverSessionRepository? repository,
  })  : _status = initialOnline
            ? DriverOnlineStatus.online
            : DriverOnlineStatus.offline,
        _repository = repository ?? MemoryDriverSessionRepository();

  final DriverSessionRepository _repository;
  DriverOnlineStatus _status;
  bool _resumeHomeAfterTrip = false;

  DriverOnlineStatus get status => _status;

  bool get isOnline =>
      _status == DriverOnlineStatus.online ||
      _status == DriverOnlineStatus.onTrip;

  bool get isGoingOnline => _status == DriverOnlineStatus.goingOnline;

  bool get isSuspended => _status == DriverOnlineStatus.suspended;

  void setOnline(bool value) {
    if (isSuspended && value) return;
    final next =
        value ? DriverOnlineStatus.online : DriverOnlineStatus.offline;
    if (_status == next) return;
    _status = next;
    notifyListeners();
    unawaited(_repository.saveOnline(value));
  }

  /// Home connecting animation. Driver is not available for offers yet.
  void beginGoingOnline() {
    if (isSuspended) return;
    if (_status == DriverOnlineStatus.goingOnline) return;
    _status = DriverOnlineStatus.goingOnline;
    notifyListeners();
    unawaited(_repository.saveOnline(false));
  }

  void completeGoingOnline() {
    if (_status != DriverOnlineStatus.goingOnline) return;
    _status = DriverOnlineStatus.online;
    notifyListeners();
    unawaited(_repository.saveOnline(true));
  }

  void suspend() {
    if (_status == DriverOnlineStatus.suspended) return;
    _status = DriverOnlineStatus.suspended;
    notifyListeners();
    unawaited(_repository.saveOnline(false));
  }

  /// D11: crash / cold start is always offline. Going online is explicit.
  Future<void> restore() async {
    final stored = await _repository.readOnline();
    if (stored == true) {
      await _repository.saveOnline(false);
    }
    if (_status == DriverOnlineStatus.offline) return;
    _status = DriverOnlineStatus.offline;
    notifyListeners();
  }

  void stayOnlineAfterTrip() {
    _resumeHomeAfterTrip = true;
    if (!isOnline) {
      _status = DriverOnlineStatus.online;
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
    if (_status == DriverOnlineStatus.offline && !_resumeHomeAfterTrip) {
      unawaited(_repository.clear());
      return;
    }
    _status = DriverOnlineStatus.offline;
    _resumeHomeAfterTrip = false;
    notifyListeners();
    unawaited(_repository.clear());
  }
}
