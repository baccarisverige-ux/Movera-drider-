/// Invalidates repository instances owned by a departing local session.
class LocalWriteSession {
  LocalWriteSession._();
  static int _generation = 0;
  static bool _clearing = false;
  static int get generation => _generation;
  static void check(int generation) {
    if (_clearing || generation != _generation) {
      throw StateError('Local session ended; reopen the screen before saving');
    }
  }

  static void beginCleanup() {
    if (_clearing) throw StateError('Local cleanup already in progress');
    _clearing = true;
    _generation++;
  }

  static void endCleanup() {
    _clearing = false;
  }
}
