/// Coalesces frequent map route refresh requests without starving the map.
///
/// Only one fetch runs at a time. If the driver moves while routing is busy,
/// request one more fetch using the latest position after the current one.
/// Existing callers do not block UI while another fetch already owns the lane.
class CoalescingMapRouteRefresh {
  bool _running = false;
  bool _pending = false;
  Future<void> Function()? _latestRefresh;

  bool get isRunning => _running;

  Future<void> request(Future<void> Function() refresh) async {
    if (_running) {
      _pending = true;
      _latestRefresh = refresh;
      return;
    }
    _running = true;
    try {
      do {
        _pending = false;
        final current = _latestRefresh ?? refresh;
        _latestRefresh = null;
        await current();
      } while (_pending);
    } finally {
      _running = false;
      _latestRefresh = null;
    }
  }

  /// Stop queued work when destination mode is dismissed. A running fetch may
  /// still complete, so its caller separately validates request ownership.
  void cancelPending() {
    _pending = false;
    _latestRefresh = null;
  }
}
