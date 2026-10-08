/// Coalesces frequent map route refresh requests without starving the map.
///
/// Only one fetch runs at a time. If the driver moves while routing is busy,
/// request one more fetch using the latest position after the current one.
/// Existing callers do not block UI while another fetch already owns the lane.
class CoalescingMapRouteRefresh {
  bool _running = false;
  bool _pending = false;

  bool get isRunning => _running;

  Future<void> request(Future<void> Function() refresh) async {
    if (_running) {
      _pending = true;
      return;
    }
    _running = true;
    try {
      do {
        _pending = false;
        await refresh();
      } while (_pending);
    } finally {
      _running = false;
    }
  }

  /// Stop queued work when destination mode is dismissed. A running fetch may
  /// still complete, so its caller separately validates request ownership.
  void cancelPending() {
    _pending = false;
  }
}
