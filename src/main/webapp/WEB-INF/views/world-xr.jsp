<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<%--
    world-xr.jsp — alternate AR view using 8th Wall's open-source XR Engine.
    Reads the *same* /api/objects endpoint as world.jsp, but replaces AR.js's
    GPS-driven camera with 8th Wall's SLAM/VIO. GPS is consulted *once* at
    session start to anchor a local origin; everything afterward is visual
    tracking, which is why this view feels stable while the user walks.

    Engine is loaded from jsDelivr (npm: @8thwall/engine-binary). No local
    binary install required.
--%>
<html>

<head>
    <title>WARP — XR (beta tracking)</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">

    <%-- A-Frame is already used by /world; reuse the same version. --%>
    <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>

    <%--
      8th Wall XR Engine, served from jsDelivr's mirror of the official
      @8thwall/engine-binary npm package. data-preload-chunks="slam" tells
      the engine to fetch the SLAM WASM blob upfront so world tracking is
      ready when the scene starts. This script registers the global XR8
      object and the <a-scene xrweb> component.
    --%>
    <script async
            src="https://cdn.jsdelivr.net/npm/@8thwall/engine-binary@1/dist/xr.js"
            crossorigin="anonymous"
            data-preload-chunks="slam"></script>

    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            background-color: #000;
            overflow: hidden;
            font-family: system-ui, -apple-system, sans-serif;
            color: white;
        }
        video {
            position: fixed !important;
            top: 0 !important; left: 0 !important;
            width: 100vw !important; height: 100vh !important;
            margin: 0 !important;
            z-index: 0 !important;
            object-fit: cover;
        }
        .a-canvas, a-scene canvas {
            position: fixed !important;
            top: 0 !important; left: 0 !important;
            width: 100vw !important; height: 100vh !important;
            background: transparent !important;
            z-index: 1 !important;
        }
        .hud-top {
            position: absolute;
            top: 20px; left: 20px; right: 20px;
            display: flex; justify-content: space-between; align-items: flex-start;
            flex-wrap: wrap; gap: 8px;
            z-index: 10;
        }
        .hud-btn {
            background: rgba(0, 0, 0, 0.4);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: white;
            padding: 10px 16px;
            border-radius: 999px;
            backdrop-filter: blur(8px);
            text-decoration: none;
            font-size: 0.9rem;
            display: inline-flex; align-items: center;
        }
        .status {
            background: rgba(0, 0, 0, 0.6);
            padding: 10px 16px;
            border-radius: 12px;
            font-size: 0.85rem;
            max-width: 250px;
            backdrop-filter: blur(4px);
        }
        .hud-bottom {
            position: absolute;
            bottom: 30px; left: 0; right: 0;
            display: flex; flex-direction: column; align-items: center; gap: 12px;
            z-index: 10;
        }
        .place-bar {
            width: min(340px, 92vw);
            padding: 10px 12px;
            border-radius: 14px;
            background: rgba(0, 0, 0, 0.55);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(6px);
            display: flex; flex-direction: column; gap: 8px;
        }
        .place-modes { display: flex; gap: 8px; }
        .mode-btn {
            flex: 1;
            padding: 8px 10px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.25);
            background: rgba(40, 40, 40, 0.9);
            color: #ddd;
            font-size: 0.82rem;
            cursor: pointer;
        }
        .mode-btn.on {
            background: rgba(211, 127, 143, 0.55);
            color: #fff;
            border-color: rgba(255, 255, 255, 0.45);
        }
        .signpost-input {
            width: 100%;
            padding: 8px 10px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            background: rgba(30, 30, 30, 0.95);
            color: #fff;
            font-size: 0.85rem;
            box-sizing: border-box;
        }
        .signpost-input:disabled { opacity: 0.45; }
        .place-hint {
            font-size: 0.72rem;
            color: #aaa;
            text-align: center;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6);
        }
        .action-button {
            width: 70px; height: 70px;
            border-radius: 50%;
            background: white;
            border: 4px solid rgba(255, 255, 255, 0.5);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            color: #333;
            transition: transform 0.1s;
        }
        .action-button:active { transform: scale(0.9); }
        .loading-overlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            display: flex; align-items: center; justify-content: center; flex-direction: column;
            background: #000;
            z-index: 100;
            transition: opacity 0.5s;
        }
        .toast {
            position: absolute;
            top: 80px; left: 50%; transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.75);
            padding: 8px 14px;
            border-radius: 999px;
            font-size: 0.82rem;
            z-index: 20;
            opacity: 0;
            transition: opacity 0.2s;
            pointer-events: none;
        }
        .toast.show { opacity: 1; }
        .toast.err { border: 1px solid rgba(255, 90, 90, 0.6); }

        /*
          iOS Safari + 8th Wall: rotating to landscape kills the camera
          MediaStreamTrack and the SLAM engine can't recover in place. We
          block landscape with this overlay; the hud + scene are hidden
          underneath. The companion JS forces a reload when the user
          rotates back to portrait, which gives us a fresh stream.
        */
        .landscape-block {
            display: none;
            position: fixed;
            inset: 0;
            background: #0a0a0a;
            z-index: 200;
            align-items: center;
            justify-content: center;
            padding: 24px;
            text-align: center;
        }
        .lb-card {
            max-width: 320px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .lb-emoji {
            font-size: 2.4rem;
            color: #d37f8f;
        }
        .lb-title {
            font-size: 1.05rem;
            font-weight: 600;
        }
        .lb-sub {
            font-size: 0.85rem;
            color: #aaa;
            line-height: 1.4;
        }
        @media (orientation: landscape) and (max-height: 600px) {
            .landscape-block { display: flex; }
            .hud-top, .hud-bottom, a-scene, #toast { visibility: hidden; }
        }
    </style>
</head>

<body>

<div id="loading" class="loading-overlay">
    <div style="margin-bottom: 16px; font-size: 1.15rem;">Starting XR engine…</div>
    <div id="loading-sub" style="font-size: 0.8rem; color: #aaa;">Loading SLAM, requesting camera + GPS</div>
    <button id="retry-btn"
            style="display:none; margin-top:20px; padding:10px 20px; border-radius:999px; border:1px solid white; background:none; color:white;"
            onclick="location.reload()">Retry
    </button>
</div>

<div id="toast" class="toast"></div>

<div class="landscape-block" role="alertdialog" aria-label="please rotate to portrait">
    <div class="lb-card">
        <div class="lb-emoji">⟳</div>
        <div class="lb-title">Please use portrait mode</div>
        <div class="lb-sub">iOS Safari drops the camera stream when this view rotates. Hold your phone upright to keep tracking alive.</div>
    </div>
</div>

<div class="hud-top">
    <a href="<%= request.getContextPath() %>/" class="hud-btn">← Exit</a>
    <a href="<%= request.getContextPath() %>/world" class="hud-btn" title="fall back to AR.js GPS view">AR.js mode</a>
    <div class="status">
        <div id="status-tracking"><strong>Tracking</strong>: starting…</div>
        <div id="status-location" style="margin-top: 4px; color: #aaa;">GPS: pending</div>
        <div id="status-objects" style="margin-top: 4px; color: #aaa;">Searching for props…</div>
    </div>
</div>

<a-scene
        xrweb="allowedDevices: any; disableWorldTracking: false"
        renderer="colorManagement: true; antialias: true; alpha: true"
        vr-mode-ui="enabled: false"
        embedded>
    <%--
      look-controls is disabled because 8th Wall's xrweb writes a full 6-DoF
      SLAM pose into the camera each frame; A-Frame's default look-controls
      *also* writes rotation from deviceorientation, and the two fight on
      every rotate, especially landscape↔portrait swings.
    --%>
    <a-camera id="xr-camera"
              look-controls="enabled: false"
              wasd-controls="enabled: false"
              position="0 1.5 0"></a-camera>
    <a-light type="ambient" intensity="0.7"></a-light>
    <a-light type="directional" intensity="0.6" position="2 4 1"></a-light>
</a-scene>

<div class="hud-bottom">
    <div class="place-bar">
        <div class="place-modes">
            <button type="button" class="mode-btn on" id="mode-cube" onclick="setPlaceMode('cube')">cube</button>
            <button type="button" class="mode-btn" id="mode-sign" onclick="setPlaceMode('signpost')">signpost</button>
        </div>
        <input id="signpost-text" class="signpost-input" type="text" maxlength="80"
               placeholder="signpost message (signpost mode only)" disabled>
        <div class="place-hint" id="place-hint">drops where you're standing — XR tracking, no GPS jitter</div>
    </div>
    <button class="action-button" onclick="placeAtCamera()" aria-label="place">
        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#333" stroke-width="2.4"
             stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"/>
            <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
    </button>
</div>

<script>
    const API_URL = '<%= request.getContextPath() %>/api/objects';
    let placeMode = 'cube';

    // GPS-anchored origin: lat/lon at session start. Everything else is local meters.
    let originLat = null, originLon = null, originAcc = null;
    const M_PER_DEG_LAT = 111320; // close enough for short distances
    let placedIds = new Set();

    function setPlaceMode(mode) {
        placeMode = mode;
        document.getElementById('mode-cube').classList.toggle('on', mode === 'cube');
        document.getElementById('mode-sign').classList.toggle('on', mode === 'signpost');
        document.getElementById('signpost-text').disabled = (mode !== 'signpost');
    }

    function showToast(msg, isErr) {
        const t = document.getElementById('toast');
        t.textContent = msg;
        t.classList.toggle('err', !!isErr);
        t.classList.add('show');
        clearTimeout(t._h);
        t._h = setTimeout(() => t.classList.remove('show'), 2500);
    }

    function setStatus(id, html) {
        const el = document.getElementById(id);
        if (el) el.innerHTML = html;
    }

    function hideLoading() {
        const el = document.getElementById('loading');
        if (!el) return;
        el.style.opacity = '0';
        setTimeout(() => el.remove(), 500);
    }

    // lat/lon → local meters (equirectangular, valid for sub-km distances)
    function latLonToLocal(lat, lon) {
        if (originLat == null) return null;
        const dLat = lat - originLat;
        const dLon = lon - originLon;
        const x = dLon * Math.cos(originLat * Math.PI / 180) * M_PER_DEG_LAT;
        const z = -dLat * M_PER_DEG_LAT; // -Z is "north" by convention here
        return { x: x, z: z };
    }

    function localToLatLon(x, z) {
        if (originLat == null) return null;
        const dLat = -z / M_PER_DEG_LAT;
        const dLon = x / (Math.cos(originLat * Math.PI / 180) * M_PER_DEG_LAT);
        return { lat: originLat + dLat, lon: originLon + dLon };
    }

    // sample-and-pick GPS burst — same approach as world.jsp's acquireBestFix
    function lockOriginGps() {
        return new Promise(function (resolve, reject) {
            if (!navigator.geolocation) { reject(new Error('no-geo')); return; }
            let best = null;
            let watchId = null;
            let settled = false;
            const GATE = 25;       // meters: accept if best fix is within this
            const WINDOW = 4500;   // ms: sampling burst
            const EARLY = 8;       // meters: settle immediately on a fix this good

            function settle() {
                if (settled) return;
                settled = true;
                if (watchId != null) {
                    try { navigator.geolocation.clearWatch(watchId); } catch (e) {}
                }
                if (!best) { reject(new Error('no-fix')); return; }
                if (best.acc > GATE) { reject(new Error('weak:' + Math.round(best.acc))); return; }
                resolve(best);
            }

            try {
                watchId = navigator.geolocation.watchPosition(
                    function (pos) {
                        const acc = pos.coords.accuracy;
                        if (best === null || acc < best.acc) {
                            best = { lat: pos.coords.latitude, lon: pos.coords.longitude, acc: acc };
                        }
                        if (acc <= EARLY) settle();
                    },
                    function (err) {
                        if (!best && (err.code === 1 || err.code === 2)) {
                            settled = true;
                            if (watchId != null) {
                                try { navigator.geolocation.clearWatch(watchId); } catch (e) {}
                            }
                            reject(new Error(err.code === 1 ? 'denied' : 'unavailable'));
                        }
                    },
                    { enableHighAccuracy: true, timeout: 25000, maximumAge: 0 }
                );
            } catch (e) {
                reject(e);
                return;
            }
            setTimeout(settle, WINDOW);
        });
    }

    // ---- entity factories (mirror world.jsp's visual style, minus gps-entity-place) ----

    function buildCubeEntity(id, x, z, scale, yawDeg) {
        const root = document.createElement('a-entity');
        root.setAttribute('id', 'obj-' + id);
        root.setAttribute('position', x + ' 0 ' + z);
        const inner = document.createElement('a-entity');
        if (yawDeg != null && !isNaN(yawDeg)) {
            inner.setAttribute('rotation', '0 ' + (-yawDeg) + ' 0');
        }
        const s = scale || 1;
        inner.setAttribute('scale', s + ' ' + s + ' ' + s);
        inner.setAttribute('position', '0 0.25 0');
        const box = document.createElement('a-box');
        box.setAttribute('width', '0.5');
        box.setAttribute('height', '0.5');
        box.setAttribute('depth', '0.5');
        box.setAttribute('material', 'color: #d37f8f; metalness: 0.1; roughness: 0.7');
        inner.appendChild(box);
        root.appendChild(inner);
        return root;
    }

    function buildSignpostEntity(id, x, z, scale, yawDeg, text) {
        const root = document.createElement('a-entity');
        root.setAttribute('id', 'obj-' + id);
        root.setAttribute('position', x + ' 0 ' + z);
        const inner = document.createElement('a-entity');
        if (yawDeg != null && !isNaN(yawDeg)) {
            inner.setAttribute('rotation', '0 ' + (-yawDeg) + ' 0');
        }
        const s = scale || 1;
        inner.setAttribute('scale', s + ' ' + s + ' ' + s);
        const pole = document.createElement('a-cylinder');
        pole.setAttribute('radius', '0.04');
        pole.setAttribute('height', '1.1');
        pole.setAttribute('position', '0 0.55 0');
        pole.setAttribute('material', 'color: #5c4033; roughness: 0.9');
        inner.appendChild(pole);
        const board = document.createElement('a-plane');
        board.setAttribute('width', '1.4');
        board.setAttribute('height', '0.42');
        board.setAttribute('position', '0 1.22 0.02');
        board.setAttribute('material', 'color: #f4e8dc; opacity: 0.95; side: double');
        inner.appendChild(board);
        const txt = document.createElement('a-text');
        txt.setAttribute('value', (text || 'signpost').slice(0, 80));
        txt.setAttribute('align', 'center');
        txt.setAttribute('position', '0 1.22 0.06');
        txt.setAttribute('color', '#2a1a22');
        txt.setAttribute('width', '1.25');
        inner.appendChild(txt);
        root.appendChild(inner);
        return root;
    }

    function placeObjectInScene(scene, obj) {
        if (placedIds.has(obj.id)) return;
        if (typeof obj.latitude !== 'number' || typeof obj.longitude !== 'number') return;
        const local = latLonToLocal(obj.latitude, obj.longitude);
        if (!local) return;
        // skip distant objects to keep the scene light
        const dist = Math.hypot(local.x, local.z);
        if (dist > 200) return;
        const entity = (obj.type === 'signpost')
            ? buildSignpostEntity(obj.id, local.x, local.z, obj.scale, obj.arYawDeg, obj.content)
            : buildCubeEntity(obj.id, local.x, local.z, obj.scale, obj.arYawDeg);
        scene.appendChild(entity);
        placedIds.add(obj.id);
    }

    function loadObjects() {
        const scene = document.querySelector('a-scene');
        if (!scene) return;
        return fetch(API_URL, { credentials: 'same-origin' })
            .then(function (r) { return r.ok ? r.json() : []; })
            .then(function (list) {
                if (!Array.isArray(list)) list = (list && list.objects) || [];
                let drawn = 0;
                list.forEach(function (obj) {
                    const before = placedIds.size;
                    placeObjectInScene(scene, obj);
                    if (placedIds.size > before) drawn++;
                });
                setStatus('status-objects', '<strong>Props</strong>: ' + placedIds.size + ' nearby');
                return list;
            })
            .catch(function () {
                setStatus('status-objects', '<strong>Props</strong>: load failed');
            });
    }

    function placeAtCamera() {
        if (originLat == null) {
            showToast('GPS origin not locked yet', true);
            return;
        }
        const camEl = document.getElementById('xr-camera');
        if (!camEl || !camEl.object3D) {
            showToast('camera not ready', true);
            return;
        }
        // 8th Wall world-tracking puts the camera in local meters
        const p = camEl.object3D.position;
        const ll = localToLatLon(p.x, p.z);
        if (!ll) { showToast('cannot project to lat/lon', true); return; }

        const fd = new URLSearchParams();
        fd.append('latitude', String(ll.lat));
        fd.append('longitude', String(ll.lon));
        if (placeMode === 'signpost') {
            fd.append('type', 'signpost');
            const txt = document.getElementById('signpost-text').value.trim();
            if (txt.length > 0) fd.append('content', txt);
        } else {
            fd.append('type', 'prop');
            fd.append('fileHash', 'demo_cube');
        }
        fetch(API_URL, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: fd
        })
            .then(function (r) {
                if (!r.ok) { showToast('place failed (' + r.status + ')', true); return; }
                showToast(placeMode === 'signpost' ? 'signpost placed' : 'cube placed');
                return loadObjects();
            })
            .catch(function () { showToast('network error', true); });
    }

    // ---- engine boot ----

    function reportFatal(msg) {
        const sub = document.getElementById('loading-sub');
        const retry = document.getElementById('retry-btn');
        if (sub) { sub.innerText = msg; sub.style.color = '#ff8b8b'; }
        if (retry) retry.style.display = 'block';
    }

    // Wait for XR8 (engine) to attach to window. If the binary isn't installed,
    // give up after a few seconds with a clear error pointing at the README.
    function whenXr8Ready(cb, deadlineMs) {
        const start = Date.now();
        (function tick() {
            if (window.XR8) { cb(); return; }
            if (Date.now() - start > (deadlineMs || 8000)) {
                reportFatal('XR engine failed to load from CDN. Check network / cdn.jsdelivr.net.');
                return;
            }
            setTimeout(tick, 100);
        })();
    }

    // Boot order: lock GPS origin → wait for XR engine → wait for scene loaded → fetch props
    document.addEventListener('DOMContentLoaded', function () {
        // iOS Safari ≥13: gyro permission gate — must run on a user gesture for the
        // permission popup to appear, but harmless to try here as a no-op fallback.
        if (typeof DeviceOrientationEvent !== 'undefined' &&
            typeof DeviceOrientationEvent.requestPermission === 'function') {
            DeviceOrientationEvent.requestPermission().catch(function () {});
        }

        setStatus('status-tracking', '<strong>Tracking</strong>: locking GPS origin…');
        lockOriginGps()
            .then(function (best) {
                originLat = best.lat;
                originLon = best.lon;
                originAcc = best.acc;
                setStatus('status-location',
                    '<strong>GPS origin</strong>: ' + best.lat.toFixed(5) + ', ' + best.lon.toFixed(5) +
                    ' (±' + Math.round(best.acc) + 'm)');
            })
            .catch(function (err) {
                const code = (err && err.message) || 'fail';
                setStatus('status-location', '<strong>GPS origin</strong>: ' + code + ' — placement disabled');
                showToast('GPS lock failed: ' + code, true);
            })
            .finally(function () {
                whenXr8Ready(function () {
                    setStatus('status-tracking', '<strong>Tracking</strong>: 8th Wall SLAM');
                    const scene = document.querySelector('a-scene');
                    function onReady() {
                        hideLoading();
                        if (originLat != null) loadObjects();
                    }
                    if (scene && scene.hasLoaded) onReady();
                    else if (scene) scene.addEventListener('loaded', onReady, { once: true });
                });
            });
    });

    // iOS Safari + 8th Wall: when the user rotates to landscape the
    // camera MediaStreamTrack is paused by the OS and never resumes
    // cleanly — black screen until manual refresh. We don't try to
    // revive in place (XR8.pause/resume doesn't recover a dead track).
    // Strategy: if we ever observe landscape, force a reload when the
    // page returns to portrait. That gets a fresh getUserMedia stream
    // and a fresh SLAM session.
    let xrEverLandscape = false;
    function xrCheckOrientation() {
        const isLandscape = window.matchMedia('(orientation: landscape)').matches;
        if (isLandscape) {
            xrEverLandscape = true;
            return;
        }
        if (xrEverLandscape) {
            // returned to portrait after a rotation — stream is dead, refresh
            location.reload();
        }
    }
    window.addEventListener('orientationchange', function () {
        setTimeout(xrCheckOrientation, 300);
    });
    window.addEventListener('resize', xrCheckOrientation);
</script>
</script>
</body>
</html>
