import 'dart:js_interop';

@JS('driverMapCamera.anchor')
external void _anchor(JSNumber mapId);
@JS('driverMapCamera.claim')
external void _claim(JSNumber mapId);
@JS('driverMapCamera.vehicle')
external void _vehicle(JSNumber mapId, JSNumber heading);
@JS('driverMapCamera.configure')
external void _configure(
  JSNumber mapId,
  JSNumber top,
  JSNumber bottom,
  JSNumber anchor,
);
@JS('driverMapCamera.gestures')
external void _gestures(JSNumber mapId, JSBoolean enabled);
void gestures(int mapId, bool enabled) => _gestures(mapId.toJS, enabled.toJS);

@JS('driverMapCamera.listen')
external JSFunction _listen(JSNumber mapId, JSFunction callback);
void applyAnchor(int mapId) => _anchor(mapId.toJS);

/// The next programmatic pan is a follow frame: instant, then anchored once.
void claim(int mapId) => _claim(mapId.toJS);
void vehicle(int mapId, double heading) => _vehicle(mapId.toJS, heading.toJS);
void configure(int mapId, double top, double bottom, double anchor) =>
    _configure(mapId.toJS, top.toJS, bottom.toJS, anchor.toJS);
void Function() listen(int mapId, void Function() onGesture) {
  final remove = _listen(mapId.toJS, onGesture.toJS);
  return () => remove.callAsFunction();
}

@JS('driverMapCamera.supports3D')
external JSBoolean _supports3D(JSNumber mapId);
bool supports3D(int mapId) => _supports3D(mapId.toJS).toDart;
@JS('driverMapCamera.listenRenderer')
external JSFunction _listenRenderer(JSNumber mapId, JSFunction callback);
void Function() listenRenderer(int mapId, void Function() onChanged) {
  final remove = _listenRenderer(mapId.toJS, onChanged.toJS);
  return () => remove.callAsFunction();
}
