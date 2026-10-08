/// Keeps a trip-sheet collapse from interrupting an in-progress map pinch.
///
/// A GPS-follow handoff can reveal the manual browse controls immediately;
/// sheet movement should wait until the fingers actually leave the map.
class MapZoomSheetSettle {
  final Set<int> _pointers = <int>{};
  bool _collapsePending = false;

  int get activePointers => _pointers.length;

  void pointerDown(int pointer) => _pointers.add(pointer);

  /// Returns true only when the pending sheet collapse can safely start.
  bool pointerEnded(int pointer) {
    _pointers.remove(pointer);
    return _consumeIfIdle();
  }

  /// Called when the driver first zooms; hold the sheet while fingers remain.
  bool requestCollapse() {
    _collapsePending = true;
    return _consumeIfIdle();
  }

  void cancel() {
    _collapsePending = false;
  }

  bool _consumeIfIdle() {
    if (_pointers.isNotEmpty || !_collapsePending) return false;
    _collapsePending = false;
    return true;
  }
}
