import 'dart:ui';

/// Is the second tap close enough in time and screen space to count as
/// native Maps double-tap zoom instead of two independent marker selections?
class MapDoubleTapPolicy {
  const MapDoubleTapPolicy._();

  static bool isSecondTap({
    required Duration? previousAt,
    required Offset? previousPosition,
    required Duration currentAt,
    required Offset currentPosition,
  }) {
    if (previousAt == null || previousPosition == null) return false;
    final delta = currentAt - previousAt;
    return !delta.isNegative &&
        delta <= const Duration(milliseconds: 300) &&
        (currentPosition - previousPosition).distance <= 32;
  }
}
