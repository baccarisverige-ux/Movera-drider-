import 'package:flutter/foundation.dart';
import 'package:movera/core/session/driver_session_repository.dart';

/// Canonical driver availability (P1 / D10).
enum DriverOnlineStatus { offline, goingOnline, online, onTrip, suspended }

/// Single source of truth for driver availability during one app/session flow.
///
/// The composition root owns this controller and injects it into screens that
/// need driver availability. A backend synchronization adapter can attach here
/// later without giving individual screens their own online flags.
class DriverSessionController extends ChangeNotifier {
  DriverSessionController({
    bool initialOnline = false,
    DriverSessionRepository? repository,
  }) : _status = initialOnline
           ? DriverOnlineStatus.online
           : DriverOnlineStatus.offline,
       _repository = repository ?? MemoryDriverSessionRepository();

  final DriverSessionRepository _repository;
  DriverOnlineStatus _status;
  bool _resumeHomeAfterTrip = false;
  String? _activeTripId;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();
  Object? persistenceError;
  bool get availableForOffers => _status == DriverOnlineStatus.online;
  String? get activeTripId => _activeTripId;

  void _save(Future<void> Function() operation) {
    _writes = _writes.then((_) => operation()).catchError((Object error) {
      persistenceError = error;
      if (!_disposed) notifyListeners();
    });
  }

  void beginTrip(String tripId) {
    if (_disposed) return;
    _revision++;
    _activeTripId = tripId;
    _status = DriverOnlineStatus.onTrip;
    notifyListeners();
    _save(() => _repository.saveOnline(false));
  }

  DriverOnlineStatus get status => _status;

  bool get isOnline =>
      _status == DriverOnlineStatus.online ||
      _status == DriverOnlineStatus.onTrip;

  bool get isGoingOnline => _status == DriverOnlineStatus.goingOnline;

  bool get isSuspended => _status == DriverOnlineStatus.suspended;

  void setOnline(bool value) {
    if (_disposed || _activeTripId != null || (isSuspended && value)) return;
    _revision++;
    final next = value ? DriverOnlineStatus.online : DriverOnlineStatus.offline;
    if (_status == next) return;
    _status = next;
    notifyListeners();
    _save(() => _repository.saveOnline(value));
  }

  /// Home connecting animation. Driver is not available for offers yet.
  void beginGoingOnline() {
    if (_disposed || _activeTripId != null || isSuspended) return;
    _revision++;
    if (_status == DriverOnlineStatus.goingOnline) return;
    _status = DriverOnlineStatus.goingOnline;
    notifyListeners();
    _save(() => _repository.saveOnline(false));
  }

  void completeGoingOnline() {
    if (_disposed || _status != DriverOnlineStatus.goingOnline) return;
    _revision++;
    _status = DriverOnlineStatus.online;
    notifyListeners();
    _save(() => _repository.saveOnline(true));
  }

  void suspend() {
    if (_disposed || _status == DriverOnlineStatus.suspended) return;
    _revision++;
    _status = DriverOnlineStatus.suspended;
    notifyListeners();
    _save(() => _repository.saveOnline(false));
  }

  /// D11: crash / cold start is always offline. Going online is explicit.
  Future<void> restore() async {
    final revision = _revision;
    try {
      final stored = await _repository.readOnline();
      if (_disposed || revision != _revision) return;
      if (stored == true) _save(() => _repository.saveOnline(false));
      if (_status == DriverOnlineStatus.offline) return;
      _status = DriverOnlineStatus.offline;
      notifyListeners();
    } catch (error) {
      persistenceError = error;
      if (!_disposed) notifyListeners();
    }
  }

  void stayOnlineAfterTrip() {
    if (_disposed) return;
    _revision++;
    _activeTripId = null;
    _status = DriverOnlineStatus.online;
    _save(() => _repository.saveOnline(true));
    _resumeHomeAfterTrip = true;
    if (!isOnline) {
      _status = DriverOnlineStatus.online;
      _save(() => _repository.saveOnline(true));
    }
    notifyListeners();
  }

  bool consumeResumeHomeAfterTrip() {
    if (!_resumeHomeAfterTrip) return false;
    _resumeHomeAfterTrip = false;
    return true;
  }

  void reset() {
    if (_disposed) return;
    _revision++;
    _activeTripId = null;
    if (_status == DriverOnlineStatus.offline && !_resumeHomeAfterTrip) {
      _save(_repository.clear);
      return;
    }
    _status = DriverOnlineStatus.offline;
    _resumeHomeAfterTrip = false;
    notifyListeners();
    _save(_repository.clear);
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
