/* Driver-only Google Maps adapter for google_maps_flutter_web 0.5.14+2.
 * That version does not expose vector rendering, padding, touch rotation/tilt
 * or bitmap marker rotation. Keep these SDK gaps out of the Dart policy.
 * Uses public Maps JS APIs. Styled vector maps require a configured cloud map ID.
 */
(() => {
  'use strict';
  const sdk = globalThis.google?.maps;
  if (!sdk) throw new Error('Load Maps JavaScript before driver_map_camera.js');
  const states = new Map();
  const byMap = new WeakMap();
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
  const delta = (a, b) => ((b - a + 540) % 360) - 180;
  const touchPose = touches => {
    const a = touches[0], b = touches[1] || a;
    return {x: (a.clientX + b.clientX) / 2,
      y: (a.clientY + b.clientY) / 2,
      span: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY),
      angle: Math.atan2(b.clientY - a.clientY, b.clientX - a.clientX) * 180 / Math.PI};
  };
  function shiftToAnchor(state, nativeMove) {
    const projection = state.overlay.getProjection();
    const height = state.div.clientHeight;
    if (!projection || !height) return;
    const available = Math.max(0, height - state.top - state.bottom);
    if (!available) return;
    const margin = Math.min(24, available / 2);
    const desiredY = state.anchor === .5 ? state.top + available / 2 :
      clamp(height * state.anchor, state.top + margin,
        height - state.bottom - margin);
    const center = projection.fromLatLngToContainerPixel(state.map.getCenter());
    if (!center) return;
    const dy = desiredY - height / 2;
    if (Math.abs(dy) < 0.5) return;
    const target = projection.fromContainerPixelToLatLng(
      new sdk.Point(center.x, center.y - dy));
    if (!target) return;
    // Re-assert zoom/heading/tilt so a property write cannot keep animating.
    nativeMove({
      center: target,
      zoom: state.map.getZoom(),
      heading: state.map.getHeading() || 0,
      tilt: state.map.getTilt() || 0,
    });
  }
  function pan(state, dx, dy) {
    const projection = state.overlay.getProjection();
    if (!projection) return;
    const center = projection.fromLatLngToContainerPixel(state.map.getCenter());
    const target = projection.fromContainerPixelToLatLng(
      new sdk.Point(center.x - dx, center.y - dy));
    if (target) state.map.moveCamera({center: target});
  }
  function install(map, div, id) {
    const state = {map, div, top: 0, bottom: 0, anchor: .5,
      callbacks: new Set(), rendererCallbacks: new Set(), heading: 0, car: null, claim: false, anchorToken: 0,
      gesturesEnabled: true};
    const rendererListener = map.addListener?.('renderingtype_changed', () => {
      state.rendererCallbacks.forEach(callback => callback());
    });
    const supports3D = () => map.getRenderingType?.() === sdk.RenderingType.VECTOR;
    const overlay = new sdk.OverlayView();
    overlay.onAdd = () => {};
    overlay.draw = () => {};
    overlay.onRemove = () => {};
    overlay.setMap(map);
    state.overlay = overlay;
    states.set(id, state);
    byMap.set(map, state);
    const nativeMove = map.moveCamera.bind(map);
    const nativePanTo = typeof map.panTo === 'function'
      ? map.panTo.bind(map)
      : latLng => nativeMove({center: latLng});
    // Flutter web applies a camera update with panTo, which animates. A follow
    // frame claims the next pan so it is instant and anchored before paint.
    map.panTo = latLng => {
      if (!state.claim) {
        nativePanTo(latLng);
        return;
      }
      state.claim = false;
      nativeMove({center: latLng});
      const token = ++state.anchorToken;
      queueMicrotask(() => {
        if (token !== state.anchorToken) return;
        shiftToAnchor(state, nativeMove);
      });
    };
    let previous, travel = 0, startedAt = 0, maxTouches = 0, lastTap = -Infinity;
    let touchReleased = false;
    let pointerOrigin = null;
    let pointerReleased = false;
    state.setGesturesEnabled = enabled => {
      state.gesturesEnabled = !!enabled;
      if (!enabled) {
        previous = null; pointerOrigin = null;
        touchReleased = false; pointerReleased = false;
      }
    };
    const release = () => {
      if (!state.gesturesEnabled) return;
      state.claim = false;
      state.anchorToken++;
      state.callbacks.forEach(callback => callback());
    };
    const releaseTouch = () => {
      if (!touchReleased) { touchReleased = true; release(); }
    };
    div.style.touchAction = 'none';
    // A tap (including marker selection) is not a map pan. Ignore pointer
    // events from touch here; the custom touch path below owns their geometry.
    div.addEventListener('pointerdown', event => {
      if (!state.gesturesEnabled || event.pointerType === 'touch') return;
      pointerOrigin = {x: event.clientX, y: event.clientY};
      pointerReleased = false;
    }, {capture: true});
    div.addEventListener('pointermove', event => {
      if (!state.gesturesEnabled || !pointerOrigin || pointerReleased) return;
      if (Math.hypot(event.clientX - pointerOrigin.x,
          event.clientY - pointerOrigin.y) >= 6) {
        pointerReleased = true;
        release();
      }
    }, {capture: true});
    const clearPointer = () => { pointerOrigin = null; pointerReleased = false; };
    div.addEventListener('pointerup', clearPointer, {capture: true});
    div.addEventListener('pointercancel', clearPointer, {capture: true});
    div.addEventListener('dblclick', release, {capture: true});
    div.addEventListener('wheel', release, {capture: true, passive: true});
    // Own touch geometry so zoom + rotate can happen in the same gesture.
    // Mouse/keyboard gestures stay with Google Maps.
    div.addEventListener('touchstart', event => {
      if (!state.gesturesEnabled) return;
      event.preventDefault(); event.stopImmediatePropagation();
      if (!previous) {
        startedAt = performance.now(); maxTouches = 0;
        travel = 0; touchReleased = false;
      }
      maxTouches = Math.max(maxTouches, event.touches.length);
      if (event.touches.length > 1) releaseTouch();
      previous = {...touchPose(event.touches), count: event.touches.length};
    }, {capture: true, passive: false});
    div.addEventListener('touchmove', event => {
      if (!state.gesturesEnabled) return;
      event.preventDefault(); event.stopImmediatePropagation();
      const next = {...touchPose(event.touches), count: event.touches.length};
      if (!previous || previous.count !== next.count) { previous = next; return; }
      travel += Math.hypot(next.x - previous.x, next.y - previous.y) +
          Math.abs(next.span - previous.span);
      if (next.count > 1 || travel >= 6) releaseTouch();
      if (!touchReleased) { previous = next; return; }
      if (next.count > 1) {
        const twist = delta(previous.angle, next.angle);
        // Overlapping touch coordinates can briefly report a zero span,
        // making log2(0) infinite and snapping the entire map to minimum
        // zoom. Bound the zoom delta per event so sparse touch frames cannot
        // leap several levels either.
        const ratio = previous.span >= 5 && next.span >= 5
          ? next.span / previous.span : 1;
        const zoomDelta = clamp(Math.log2(ratio), -0.4, 0.4);
        const vertical = next.y - previous.y;
        const tilting = Math.abs(vertical) > Math.abs(next.x - previous.x) &&
          Math.abs(twist) < 2 && Math.abs(zoomDelta) < .03;
        map.moveCamera({zoom: clamp(map.getZoom() + zoomDelta, 3, 21),
          ...(supports3D() ? {
            heading: ((map.getHeading() || 0) - twist + 360) % 360,
            tilt: clamp((map.getTilt() || 0) - (tilting ? vertical * .3 : 0), 0, 60)
          } : {})});
        if (!tilting) pan(state, next.x - previous.x, next.y - previous.y);
      } else pan(state, next.x - previous.x, next.y - previous.y);
      previous = next;
    }, {capture: true, passive: false});
    const end = event => {
      if (!state.gesturesEnabled) { previous = null; return; }
      event.preventDefault(); event.stopImmediatePropagation();
      if (event.touches.length) { previous = {...touchPose(event.touches), count: event.touches.length}; return; }
      if (event.type !== 'touchcancel' && previous &&
          performance.now() - startedAt < 300 &&
          travel < 8) {
        if (maxTouches > 1) {
          releaseTouch();
          lastTap = -Infinity;
          map.moveCamera({zoom: clamp(map.getZoom() - 1, 3, 21)});
        } else {
          const now = performance.now();
          if (now - lastTap < 300) {
            releaseTouch();
            map.moveCamera({zoom: clamp(map.getZoom() + 1, 3, 21)});
            lastTap = -Infinity;
          } else lastTap = now;
        }
      }
      previous = null;
      touchReleased = false;
    };
    div.addEventListener('touchend', end, {capture: true, passive: false});
    div.addEventListener('touchcancel', end, {capture: true, passive: false});
    // Mounted Flutter platform views are removed at dispose. Release JS state.
    let wasConnected = div.isConnected;
    const observer = new MutationObserver(() => {
      wasConnected ||= div.isConnected;
      if (wasConnected && !div.isConnected) {
        state.car?.setMap(null); overlay.setMap(null);
        state.callbacks.clear(); state.rendererCallbacks.clear(); rendererListener?.remove(); states.delete(id); observer.disconnect();
      }
    });
    observer.observe(document.body, {childList: true, subtree: true});
  }
  const NativeMap = sdk.Map;
  sdk.Map = new Proxy(NativeMap, {
    construct(target, args) {
      const [div, options = {}] = args;
      const match = /^plugins\.flutter\.io\/google_maps_(\d+)$/.exec(div.id);
      const configuredId = globalThis.document?.querySelector?.('meta[name="movera-google-map-id"]')?.content?.trim();
      let driverOptions = options;
      if (match) {
        if (configuredId && configuredId !== 'DRIVER_GOOGLE_MAP_ID') {
          const {styles, ...cloudOptions} = options;
          driverOptions = {...cloudOptions, mapId: configuredId,
            renderingType: sdk.RenderingType.VECTOR,
            headingInteractionEnabled: true, tiltInteractionEnabled: true};
        } else {
          // Explicit 2D preview preserves the approved inline palette. Styled
          // vector navigation stays gated until its cloud style is configured.
          driverOptions = {...options, renderingType: sdk.RenderingType.RASTER};
        }
      }
      const map = Reflect.construct(target, [div, driverOptions]);
      if (match) install(map, div, Number(match[1]));
      return map;
    }
  });
  const NativeMarker = sdk.Marker;
  sdk.Marker = class extends NativeMarker {
    constructor(options) {
      super(options);
      if (options.title !== 'Driver camera vehicle' || !options.icon?.url) return;
      const marker = this;
      let state;
      const car = new sdk.OverlayView();
      const image = document.createElement('img');
      image.src = options.icon.url;
      image.style.cssText = 'position:absolute;pointer-events:none;transform-origin:50% 50%;';
      const size = options.icon.scaledSize || options.icon.size;
      if (size) { image.style.width = `${size.width}px`; image.style.height = `${size.height}px`; }
      car.onAdd = () => car.getPanes().overlayLayer.appendChild(image);
      car.draw = () => {
        const pixel = car.getProjection()?.fromLatLngToDivPixel(marker.getPosition());
        if (!pixel) return;
        image.style.left = `${pixel.x}px`; image.style.top = `${pixel.y}px`;
        image.style.transform = `translate(-50%,-50%) rotateX(${state.map.getTilt() || 0}deg) rotate(${state.heading - (state.map.getHeading() || 0)}deg)`;
      };
      car.onRemove = () => image.remove();
      this.addListener('position_changed', () => car.draw());
      this.addListener('icon_changed', () => { image.src = this.getIcon().url; });
      const attach = () => {
        car.setMap(null);
        state = byMap.get(this.getMap());
        if (!state) return;
        state.car?.setMap(null); state.car = car;
        car.setMap(this.getMap());
      };
      this.addListener('map_changed', attach);
      this.addListener('visible_changed', () => {
        if (this.getVisible()) this.setVisible(false);
      });
      attach();
      this.setVisible(false);
    }
  };
  globalThis.driverMapCamera = {
    supports3D(id) {
      return states.get(id)?.map.getRenderingType?.() === sdk.RenderingType.VECTOR;
    },
    listenRenderer(id, callback) {
      const state = states.get(id); state?.rendererCallbacks.add(callback);
      return () => state?.rendererCallbacks.delete(callback);
    },
    configure(id, top, bottom, anchor) {
      const state = states.get(id); if (!state) return;
      Object.assign(state, {top, bottom, anchor});
    },
    gestures(id, enabled) {
      states.get(id)?.setGesturesEnabled(enabled);
    },
    listen(id, callback) {
      const state = states.get(id); state?.callbacks.add(callback);
      return () => state?.callbacks.delete(callback);
    },
    vehicle(id, heading) {
      const state = states.get(id); if (!state) return;
      state.heading = heading; state.car?.draw();
    },
    anchor(id) {
      const state = states.get(id); if (!state) return;
      const nativeMove = state.map.moveCamera.bind(state.map);
      shiftToAnchor(state, nativeMove);
    },
    claim(id) {
      const state = states.get(id); if (!state) return;
      state.claim = true;
    },
  };
})();
