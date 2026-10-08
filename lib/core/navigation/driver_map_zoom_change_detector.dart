/// Tracks actual SDK zoom changes without mistaking camera panning for zoom.
///
/// Capture every map frame (including GPS following), then report a change
/// only when the viewport already belongs to the driver. Native Google Maps
/// +/- controls do not generate a pinch or mouse-wheel event in Flutter.
class DriverMapZoomChangeDetector {
  DriverMapZoomChangeDetector({double? initialZoom})
      : _lastZoom = initialZoom;

  double? _lastZoom;

  bool observe(double zoom, {required bool browsing}) {
    if (!zoom.isFinite) return false;
    final previous = _lastZoom;
    _lastZoom = zoom;
    return browsing && previous != null && (zoom - previous).abs() >= 0.075;
  }
}
