// Contract tests for our JS adapter, not a replacement for real Maps/device QA.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
let clock = 1000;
class Element {
  constructor(id = '') { this.id = id; this.style = {}; this.handlers = {}; this.clientHeight = 800; this.isConnected = true; }
  addEventListener(name, callback) { this.handlers[name] = callback; }
  fire(name, touches = [], props = {}) { this.handlers[name]?.({type: name, touches,
    ...props, preventDefault() {}, stopImmediatePropagation() {}}); }
  appendChild() {} remove() {}
}
class MapMock {
  constructor(div, options) { this.div = div; this.options = options;
    this.camera = {center: {x: 0, y: 0}, zoom: 16, heading: 0, tilt: 0}; }
  moveCamera(camera) { Object.assign(this.camera, camera); }
  addListener(event, callback) { this.listeners ??= {}; this.listeners[event] = callback; return {remove: () => delete this.listeners[event]}; }
  getRenderingType() { return this.renderer ?? this.options.renderingType; }
  getCenter() { return this.camera.center; } getZoom() { return this.camera.zoom; }
  getHeading() { return this.camera.heading; } getTilt() { return this.camera.tilt; }
}
class OverlayMock {
  setMap(map) { if (this.map) this.onRemove(); this.map = map;
    if (map) { this.onAdd(); this.draw(); } }
  getPanes() { return {overlayLayer: new Element()}; }
  getProjection() { if (!this.map) return null; return {
    fromLatLngToContainerPixel: p => p,
    fromContainerPixelToLatLng: p => p,
    fromLatLngToDivPixel: p => p,
  }; }
}
class MarkerMock {
  constructor(options) { this.options = options; this.handlers = {}; }
  addListener(event, callback) { this.handlers[event] = callback; }
  setMap(map) { this.options.map = map; this.handlers.map_changed?.(); }
  getMap() { return this.options.map; } getPosition() { return this.options.position; }
  getIcon() { return this.options.icon; } getVisible() { return this.options.visible; }
  setVisible(visible) { this.options.visible = visible; this.handlers.visible_changed?.(); }
}
const maps = {Map: MapMock, Marker: MarkerMock, OverlayView: OverlayMock,
  Point: class {constructor(x,y) {this.x=x;this.y=y;}}, RenderingType: {VECTOR: 'VECTOR', RASTER: 'RASTER'}};
const images = [];
const context = {google: {maps}, performance: {now: () => clock},
  queueMicrotask,
  document: {querySelector: () => ({content: 'configured-vector-style'}), body: new Element(), createElement: () => {
    const image = new Element(); images.push(image); return image;
  }},
  MutationObserver: class {observe() {} disconnect() {}}};
vm.runInNewContext(fs.readFileSync('web/driver_map_camera.js', 'utf8'), context);
const div = new Element('plugins.flutter.io/google_maps_7');
const style = [{featureType: 'water'}];
const map = new maps.Map(div, {styles: style});
assert.equal(map.options.renderingType, 'VECTOR');
assert.equal(map.options.styles, undefined, 'Cloud style and inline styles cannot coexist');
assert.equal(map.options.mapId, 'configured-vector-style');
assert.equal(map.options.headingInteractionEnabled, true);
const api = context.driverMapCamera;
assert.equal(api.supports3D(7), true);
context.document.querySelector = () => ({content: ''});
const rasterDiv = new Element('plugins.flutter.io/google_maps_8');
const raster = new maps.Map(rasterDiv, {styles: style});
assert.equal(raster.options.renderingType, 'RASTER');
assert.equal(raster.options.styles, style, 'Explicit 2D preview retains approved palette');
assert.equal(api.supports3D(8), false);
rasterDiv.fire('touchstart', [{clientX:100,clientY:100},{clientX:200,clientY:100}]);
rasterDiv.fire('touchmove', [{clientX:80,clientY:80},{clientX:220,clientY:120}]);
assert.equal(raster.getHeading(), 0, 'Raster gestures do not request rotation');
assert.equal(raster.getTilt(), 0, 'Raster gestures do not request tilt');
let changed = 0;
const removeRenderer = api.listenRenderer(7, () => changed++);
map.renderer = 'RASTER'; map.listeners.renderingtype_changed();
assert.equal(changed, 1); assert.equal(api.supports3D(7), false);
removeRenderer(); map.renderer = 'VECTOR'; map.listeners.renderingtype_changed();
assert.equal(changed, 1, 'Renderer listener is released');
let gestures = 0;
const remove = api.listen(7, () => gestures++);
const mouse = (x, y) => ({pointerType: 'mouse', clientX: x, clientY: y});
div.fire('pointerdown', [], mouse(100,100));
assert.equal(gestures, 0, 'Mouse tap must not release follow');
div.fire('pointermove', [], mouse(103,100));
assert.equal(gestures, 0, 'Mouse jitter must not release follow');
div.fire('pointermove', [], mouse(113,100));
assert.equal(gestures, 1, 'Real mouse drag releases follow');
div.fire('pointermove', [], mouse(130,100));
assert.equal(gestures, 1, 'One drag releases once');
div.fire('pointerup', [], mouse(130,100));
const touch = (x, y) => ({clientX: x, clientY: y});
div.fire('touchstart', [touch(100,100)]);
div.fire('touchend');
assert.equal(gestures, 1, 'Single finger tap preserves follow');
clock += 350;
div.fire('touchstart', [touch(100,100)]);
div.fire('touchmove', [touch(103,102)]);
assert.equal(gestures, 1, 'Touch jitter preserves follow');
div.fire('touchmove', [touch(130,120)]);
assert.equal(gestures, 2, 'Touch pan releases follow');
assert.equal(map.camera.center.x, -27, 'One-finger pan after jitter threshold');
div.fire('touchend');
div.fire('touchstart', [touch(100,100),touch(200,100)]);
div.fire('touchmove', [touch(80,80),touch(220,120)]);
assert.ok(map.getZoom() > 16 && map.getHeading() !== 0, 'Combined pinch + twist');
div.fire('touchend');
map.moveCamera({tilt: 0});
div.fire('touchstart', [touch(100,100),touch(200,100)]);
div.fire('touchmove', [touch(100,50),touch(200,50)]);
assert.equal(map.getTilt(), 15, 'Two-finger up tilts');
div.fire('touchmove', [touch(100,-300),touch(200,-300)]);
assert.equal(map.getTilt(), 60, 'Tilt clamps to 60');
div.fire('touchmove', [touch(100,400),touch(200,400)]);
assert.equal(map.getTilt(), 0, 'Two-finger down flattens');
div.fire('touchend');
const beforeTap = map.getZoom();
div.fire('touchstart', [touch(100,100),touch(200,100)]);
div.fire('touchend', [touch(100,100)]); div.fire('touchend');
assert.equal(map.getZoom(), beforeTap - 1, 'Two-finger tap zooms out');
div.fire('touchstart', [touch(100,100)]); div.fire('touchend');
clock += 150;
div.fire('touchstart', [touch(100,100)]); div.fire('touchend');
assert.equal(map.getZoom(), beforeTap, 'Double tap zooms in');
// A locked active-trip sheet must prevent custom web pan, pinch and zoom,
// not merely disable native Google Maps gesture flags.
api.gestures(7, false);
const lockedZoom = map.getZoom();
const lockedHeading = map.getHeading();
const lockedCenter = JSON.stringify(map.getCenter());
const lockedCallbacks = gestures;
div.fire('pointerdown', [], mouse(100,100));
div.fire('pointermove', [], mouse(160,140));
div.fire('pointerup', [], mouse(160,140));
div.fire('touchstart', [touch(100,100),touch(200,100)]);
div.fire('touchmove', [touch(50,70),touch(260,160)]);
div.fire('touchend');
div.fire('wheel');
assert.equal(map.getZoom(), lockedZoom, 'Locked map ignores two-finger zoom');
assert.equal(map.getHeading(), lockedHeading, 'Locked map ignores rotation');
assert.equal(JSON.stringify(map.getCenter()), lockedCenter,
  'Locked map ignores pointer and touch pan');
assert.equal(gestures, lockedCallbacks,
  'Locked map cannot steal follow-camera ownership');
api.gestures(7, true);
div.fire('touchstart', [touch(100,100),touch(200,100)]);
div.fire('touchmove', [touch(60,100),touch(240,100)]);
assert.ok(map.getZoom() > lockedZoom, 'Re-enabled zoom gesture works');
div.fire('touchend');
const beforeCollapsedPinch = map.getZoom();
div.fire('touchstart', [touch(100,100), touch(200,100)]);
div.fire('touchmove', [touch(100,100), touch(100,100)]);
assert.equal(map.getZoom(), beforeCollapsedPinch,
  'Overlapping touch positions must not snap zoom to minimum');
div.fire('touchend');
const beforeSparsePinch = map.getZoom();
div.fire('touchstart', [touch(100,100), touch(200,100)]);
div.fire('touchmove', [touch(100,100), touch(5000,100)]);
assert.ok(map.getZoom() - beforeSparsePinch <= 0.400001,
  'Sparse pinch events cannot jump multiple zoom levels');
div.fire('touchend');
// Native double-tap / two-finger tap must respect Maps zoom boundaries.
map.moveCamera({zoom: 3});
clock += 500;
div.fire('touchstart', [touch(100,100), touch(200,100)]);
div.fire('touchend');
assert.equal(map.getZoom(), 3, 'Two-finger zoom-out cannot go below level 3');
map.moveCamera({zoom: 21});
clock += 500;
div.fire('touchstart', [touch(100,100)]); div.fire('touchend');
clock += 150;
div.fire('touchstart', [touch(100,100)]); div.fire('touchend');
assert.equal(map.getZoom(), 21, 'Double-tap zoom-in cannot exceed level 21');
api.configure(7, 100, 200, .72);
map.moveCamera({center: {x:0,y:400}}); api.anchor(7);
assert.equal(map.camera.center.y, 224, '72% screen anchor above overlays');
const marker = new maps.Marker({title:'Driver camera vehicle', position:{x:1,y:2},
  icon:{url:'vehicle.png',scaledSize:{width:40,height:40}}, visible:true});
marker.setMap(map); api.vehicle(7,90);
assert.equal(marker.getVisible(), false, 'Rotatable vehicle overlay replaces bitmap');
map.moveCamera({heading:90}); api.vehicle(7,90);
assert.ok(images[0].style.transform.includes('rotate(0deg)'), 'Heading-up car points up');
map.moveCamera({heading:30}); api.vehicle(7,90);
assert.ok(images[0].style.transform.includes('rotate(60deg)'), 'Free rotation preserves real car course');
marker.setMap(null);
remove(); const count = gestures; div.fire('pointerdown', [], mouse(100,100));
div.fire('pointermove', [], mouse(120,100));
assert.equal(gestures,count,'Disposed Flutter listener released');
map.moveCamera({center: {x:0,y:400}, zoom: 16, heading: 12, tilt: 30});
api.claim(7);
map.panTo({x:0,y:400});
queueMicrotask(() => {
  assert.equal(map.camera.center.y, 224, 'Claimed follow pan anchors before paint');
  assert.equal(map.getZoom(), 16);
  assert.equal(map.getHeading(), 12);
  assert.equal(map.getTilt(), 30);
  console.log('PASS: vector palette, tap-safe release, gesture lock, drag, pan, pinch/twist, tilt, taps, anchor and vehicle overlay');
});
