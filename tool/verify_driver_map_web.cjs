// Contract tests for our JS adapter, not a replacement for real Maps/device QA.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
let clock = 1000;
class Element {
  constructor(id = '') { this.id = id; this.style = {}; this.handlers = {}; this.clientHeight = 800; this.isConnected = true; }
  addEventListener(name, callback) { this.handlers[name] = callback; }
  fire(name, touches = []) { this.handlers[name]?.({type: name, touches,
    preventDefault() {}, stopImmediatePropagation() {}}); }
  appendChild() {} remove() {}
}
class MapMock {
  constructor(div, options) { this.div = div; this.options = options;
    this.camera = {center: {x: 0, y: 0}, zoom: 16, heading: 0, tilt: 0}; }
  moveCamera(camera) { Object.assign(this.camera, camera); }
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
  Point: class {constructor(x,y) {this.x=x;this.y=y;}}, RenderingType: {VECTOR: 'VECTOR'}};
const images = [];
const context = {google: {maps}, performance: {now: () => clock},
  queueMicrotask,
  document: {body: new Element(), createElement: () => {
    const image = new Element(); images.push(image); return image;
  }},
  MutationObserver: class {observe() {} disconnect() {}}};
vm.runInNewContext(fs.readFileSync('web/driver_map_camera.js', 'utf8'), context);
const div = new Element('plugins.flutter.io/google_maps_7');
const style = [{featureType: 'water'}];
const map = new maps.Map(div, {styles: style});
assert.equal(map.options.renderingType, 'VECTOR');
assert.equal(map.options.styles, style, 'Preserve exact inline map palette');
assert.equal(map.options.headingInteractionEnabled, true);
const api = context.driverMapCamera;
let gestures = 0;
const remove = api.listen(7, () => gestures++);
div.fire('pointerdown'); assert.equal(gestures, 1, 'Release on first touch');
const touch = (x, y) => ({clientX: x, clientY: y});
div.fire('touchstart', [touch(100,100)]);
div.fire('touchmove', [touch(130,120)]);
assert.equal(map.camera.center.x, -30, 'One-finger pan');
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
remove(); const count = gestures; div.fire('pointerdown');
assert.equal(gestures,count,'Disposed Flutter listener released');
map.moveCamera({center: {x:0,y:400}, zoom: 16, heading: 12, tilt: 30});
api.claim(7);
map.panTo({x:0,y:400});
queueMicrotask(() => {
  assert.equal(map.camera.center.y, 224, 'Claimed follow pan anchors before paint');
  assert.equal(map.getZoom(), 16);
  assert.equal(map.getHeading(), 12);
  assert.equal(map.getTilt(), 30);
  console.log('PASS: vector palette, immediate release, pan, combined pinch/twist, tilt, taps, anchor and vehicle overlay');
});
