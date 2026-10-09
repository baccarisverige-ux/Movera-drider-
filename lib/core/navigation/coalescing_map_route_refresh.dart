/// Coalesces frequent map route refresh requests without starving the map.
///
/// Only one fetch runs at a time. If the driver moves while routing is busy,
/// request one more fetch using the latest position after the current one.
/// Existing callers do not block UI while another fetch already owns the lane.
class CoalescingMapRouteRefresh {
  bool _running = false;
  Future<void> Function()? _pending;

  bool get isRunning => _running;

  Future<void> request(Future<void> Function() refresh) async {
    if (_running) {
      _pending = refresh;
      return;
    }
    _running = true;
    Object? firstError;
    StackTrace? firstStack;
    try {
      var next = refresh;
      do {
        _pending = null;
        try {
          await next();
        } catch (error, stack) {
          firstError ??= error;
          firstStack ??= stack;
        }
        if (_pending == null) break;
        next = _pending!;
      } while (true);
    } finally {
      _running = false;
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  /// Stop queued work when destination mode is dismissed. A running fetch may
  /// still complete, so its caller separately validates request ownership.
  void cancelPending() {
    _pending = null;
  }
}
