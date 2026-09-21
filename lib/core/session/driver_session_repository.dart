/// Persistence boundary for driver online/offline recovery.
///
/// Memory-only [DriverSessionController] is not durable. A backend-backed
/// implementation should restore the last known availability after restart.
abstract interface class DriverSessionRepository {
  Future<bool?> readOnline();

  Future<void> saveOnline(bool isOnline);

  Future<void> clear();
}

class MemoryDriverSessionRepository implements DriverSessionRepository {
  bool? _online;

  @override
  Future<bool?> readOnline() async => _online;

  @override
  Future<void> saveOnline(bool isOnline) async {
    _online = isOnline;
  }

  @override
  Future<void> clear() async {
    _online = null;
  }
}
