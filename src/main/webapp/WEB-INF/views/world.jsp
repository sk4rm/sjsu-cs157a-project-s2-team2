<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>

<head>
    <title>WARP - Camera View</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
    <script src="https://cdn.jsdelivr.net/gh/AR-js-org/AR.js@3.4.5/aframe/build/aframe-ar.js"></script>
    <style>
        body,
        html {
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
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            margin: 0 !important;
            z-index: 0 !important;
            object-fit: cover;
        }

        .a-canvas,
        a-scene canvas {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            background: transparent !important;
            z-index: 1 !important;
        }

        .hud-top {
            position: absolute;
            top: 20px;
            left: 20px;
            right: 20px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            flex-wrap: wrap;
            gap: 8px;
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
            display: inline-flex;
            align-items: center;
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
            bottom: 30px;
            left: 0;
            right: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
            z-index: 10;
        }

        .action-button {
            width: 70px;
            height: 70px;
            border-radius: 50%;
            background: white;
            border: 4px solid rgba(255, 255, 255, 0.5);
            background-clip: padding-box;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
            transition: transform 0.1s;
        }

        .action-button:active {
            transform: scale(0.9);
        }

        .place-bar {
            width: min(340px, 92vw);
            padding: 10px 12px;
            border-radius: 14px;
            background: rgba(0, 0, 0, 0.55);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(6px);
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .place-modes {
            display: flex;
            gap: 8px;
        }

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

        .signpost-input:disabled {
            opacity: 0.45;
        }

        .place-hint {
            font-size: 0.72rem;
            color: #aaa;
            text-align: center;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6);
        }

        .loading-overlay {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            background: #000;
            z-index: 100;
            transition: opacity 0.5s;
        }

        /* tap-to-prompt: ios needs a real tap before the system location dialog appears */
        .loc-prompt {
            position: fixed;
            top: 72px;
            left: 12px;
            right: 12px;
            z-index: 15;
            padding: 12px 14px;
            border-radius: 14px;
            background: rgba(20, 20, 20, 0.88);
            border: 1px solid rgba(211, 127, 143, 0.45);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45);
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: stretch;
            max-width: 420px;
            margin-left: auto;
            margin-right: auto;
        }

        .loc-prompt p {
            margin: 0;
            font-size: 0.82rem;
            line-height: 1.35;
            color: #e8e0e2;
        }

        .loc-prompt button {
            padding: 11px 16px;
            border-radius: 999px;
            border: none;
            background: linear-gradient(135deg, #d37f8f, #e6a3af);
            color: #fff;
            font-weight: 600;
            font-size: 0.9rem;
            cursor: pointer;
        }

        .loc-prompt button.secondary {
            background: rgba(255, 255, 255, 0.12);
            font-weight: 500;
        }

        .loc-prompt.hidden {
            display: none;
        }
    </style>
</head>

<body>

<div id="loading" class="loading-overlay">
    <div id="loading-text" style="margin-bottom: 20px; font-size: 1.2rem;">Initializing WARP Engine...</div>
    <div id="loading-sub" style="font-size: 0.8rem; color: #aaa;">Requesting Camera and GPS permissions</div>
    <button id="retry-btn"
            style="display:none; margin-top:20px; padding:10px 20px; border-radius:999px; border:1px solid white; background:none; color:white;"
            onclick="location.reload()">Retry
    </button>
</div>

<div class="hud-top">
    <a href="<%= request.getContextPath() %>/" class="hud-btn">← Exit World</a>
    <button type="button" class="hud-btn" onclick="placeWorldSpaceTestCube()" title="Step A: drop test cube in scene world space (not on camera)">
        test world cube
    </button>
    <div class="status">
        <div id="status-location"><strong>Location</strong>: Acquiring...</div>
        <div id="status-objects" style="margin-top: 4px; color: #aaa;">Searching for props...</div>
    </div>
</div>

<div id="loc-prompt" class="loc-prompt" role="dialog" aria-label="location permission">
    <p id="loc-prompt-text">warp uses your gps to place cubes and signposts. if you already tapped allow in settings, we try to pick up coords automatically — or use the buttons below.</p>
    <button type="button" class="loc-allow-btn" onclick="requestLocationPermission()">ask for location / refresh gps</button>
    <button type="button" class="secondary" onclick="dismissLocPrompt()">hide this bar</button>
</div>

<a-scene vr-mode-ui="enabled: false" embedded
         arjs="sourceType: webcam; debugUIEnabled: false; antialias: true; alpha: true"
         renderer="antialias: true; alpha: true">

    <a-camera gps-camera rotation-reader></a-camera>
</a-scene>

<div class="hud-bottom">
    <div class="place-bar">
        <div class="place-modes">
            <button type="button" class="mode-btn on" id="mode-cube" onclick="setPlaceMode('cube')">cube</button>
            <button type="button" class="mode-btn" id="mode-sign" onclick="setPlaceMode('signpost')">signpost</button>
        </div>
        <input type="text" class="signpost-input" id="signpost-text" maxlength="250"
               placeholder="signpost message (only for signpost)" disabled>
        <div class="place-hint" id="place-hint">gps updates from camera, or we ask browser once on place</div>
    </div>
    <div class="action-button" onclick="placeAtGps()" title="place here">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
    </div>
</div>

<script>
    const API_URL = '<%= request.getContextPath() %>/api/objects';
    let currentPosition = null;
    let placeMode = 'cube';

    function setPlaceMode(mode) {
        placeMode = mode;
        document.getElementById('mode-cube').classList.toggle('on', mode === 'cube');
        document.getElementById('mode-sign').classList.toggle('on', mode === 'signpost');
        const inp = document.getElementById('signpost-text');
        inp.disabled = mode !== 'signpost';
        document.getElementById('place-hint').innerText =
            mode === 'cube' ? 'drops a pink-ish cube at your coords' : 'drops a pole + board with your message';
    }

    function readApiError(response) {
        return response.text().then(function (t) {
            return t.slice(0, 120) || response.statusText;
        });
    }

    // remove old placed entities so reload does not stack duplicates
    function clearPlacedFromScene(scene) {
        if (!scene) return;
        scene.querySelectorAll('[id^="obj-"]').forEach(el => el.remove());
    }

    /**
     * Shared world-space target: center-screen ray ∩ plane y=0, else 2m along camera forward.
     * Same math for Step B reticle preview and Step A/C placement.
     */
    function computeWorldPlacementTarget(scene) {
        const THREE = window.THREE;
        const cam = scene.camera;
        const camEl = document.querySelector('a-camera');
        if (!cam || !camEl || !THREE) return null;

        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(new THREE.Vector2(0, 0), cam);

        const groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
        const hitPoint = new THREE.Vector3();
        const planeHit = raycaster.ray.intersectPlane(groundPlane, hitPoint);

        let wx, wy, wz;
        let usedPlane = planeHit !== null;
        if (usedPlane) {
            wx = hitPoint.x;
            wy = hitPoint.y;
            wz = hitPoint.z;
        } else {
            const origin = new THREE.Vector3();
            const dir = new THREE.Vector3();
            camEl.object3D.getWorldPosition(origin);
            camEl.object3D.getWorldDirection(dir);
            const dist = 2;
            wx = origin.x + dir.x * dist;
            wy = origin.y + dir.y * dist;
            wz = origin.z + dir.z * dist;
        }
        return { x: wx, y: wy, z: wz, usedPlane: usedPlane };
    }

    var placementReticleRaf = null;

    function ensurePlacementReticle(scene) {
        var el = document.getElementById('placement-reticle');
        if (el) return el;
        el = document.createElement('a-entity');
        el.setAttribute('id', 'placement-reticle');
        var ring = document.createElement('a-ring');
        ring.setAttribute('radius-inner', '0.11');
        ring.setAttribute('radius-outer', '0.17');
        ring.setAttribute('rotation', '-90 0 0');
        ring.setAttribute('material', 'color: #2ecc71; opacity: 0.72; shader: flat; side: double');
        el.appendChild(ring);
        scene.appendChild(el);
        return el;
    }

    /** Step B: animate reticle at preview position (scene root, not camera). */
    function startPlacementReticleLoop(scene) {
        function tick() {
            var t = computeWorldPlacementTarget(scene);
            var reticle = document.getElementById('placement-reticle');
            if (t && reticle) {
                reticle.setAttribute('position', t.x + ' ' + t.y + ' ' + t.z);
            }
            placementReticleRaf = window.requestAnimationFrame(tick);
        }
        function begin() {
            ensurePlacementReticle(scene);
            if (placementReticleRaf) {
                window.cancelAnimationFrame(placementReticleRaf);
            }
            placementReticleRaf = window.requestAnimationFrame(tick);
        }
        if (scene.hasLoaded) {
            begin();
        } else {
            scene.addEventListener('loaded', begin, { once: true });
        }
    }

    /**
     * Step A: place a single test cube at the current preview target (same as reticle).
     * Entity is a direct child of a-scene — never parented under a-camera.
     */
    function placeWorldSpaceTestCube() {
        const scene = document.querySelector('a-scene');
        if (!scene) {
            console.warn('[ARP] placeWorldSpaceTestCube: no a-scene');
            return;
        }
        const run = function () {
            const THREE = window.THREE;
            const t = computeWorldPlacementTarget(scene);
            if (!t || !THREE) {
                console.warn('[ARP] could not compute placement target');
                return;
            }
            var wx = t.x, wy = t.y, wz = t.z;

            var prev = document.getElementById('world-test-cube');
            if (prev) prev.remove();

            var root = document.createElement('a-entity');
            root.setAttribute('id', 'world-test-cube');
            root.setAttribute('position', wx + ' ' + wy + ' ' + wz);

            var box = document.createElement('a-box');
            box.setAttribute('width', '0.45');
            box.setAttribute('height', '0.45');
            box.setAttribute('depth', '0.45');
            box.setAttribute('position', '0 0.225 0');
            box.setAttribute('material', 'color: #2ecc71; opacity: 0.95; roughness: 0.5');

            root.appendChild(box);
            scene.appendChild(root);

            var p = root.parentEl;
            console.log('[ARP] Step A — plane hit (y=0):', t.usedPlane, 'placement xyz:', wx.toFixed(3), wy.toFixed(3), wz.toFixed(3));
            console.log('[ARP] parent tag:', p && p.tagName, 'is scene root:', p === scene);
            scene.object3D.updateMatrixWorld(true);
            var wpos = new THREE.Vector3();
            root.object3D.getWorldPosition(wpos);
            console.log('[ARP] placed entity world position:', wpos.x.toFixed(3), wpos.y.toFixed(3), wpos.z.toFixed(3));
        };

        if (scene.hasLoaded) {
            run();
        } else {
            scene.addEventListener('loaded', run, { once: true });
        }
    }

    // map geolocation error codes to a short hint (ios needs "allow" on first tap)
    function geoFailMessage(err) {
        if (!err || err.code === undefined) return 'gps error — try again outside or allow location';
        if (err.code === 1) return 'location blocked — tap allow, or settings > safari > location > while using';
        if (err.code === 2) return 'position unavailable — move outdoors or wait for gps';
        if (err.code === 3) return 'gps timed out — try again in open sky';
        return 'gps error';
    }

    function dismissLocPrompt() {
        var el = document.getElementById('loc-prompt');
        if (el) el.classList.add('hidden');
    }

    function maybeHideLocPrompt() {
        if (currentPosition && typeof currentPosition.latitude === 'number') {
            dismissLocPrompt();
        }
    }

    // after permission is already granted, this often works without a tap (safari skips permissions.query sometimes)
    function trySilentLocationRead() {
        if (!navigator.geolocation) return;
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                currentPosition = {
                    latitude: pos.coords.latitude,
                    longitude: pos.coords.longitude
                };
                var el = document.getElementById('status-location');
                if (el) {
                    el.innerHTML = '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5);
                }
                dismissLocPrompt();
            },
            function () { /* still blocked or needs tap — banner stays */ },
            { enableHighAccuracy: false, timeout: 15000, maximumAge: 300000 }
        );
    }

    // must run from a button tap so safari shows the system location dialog
    function requestLocationPermission() {
        var box = document.getElementById('loc-prompt');
        if (box) box.classList.remove('denied');
        if (!navigator.geolocation) {
            var t0 = document.getElementById('loc-prompt-text');
            if (t0) t0.innerText = 'this browser does not support geolocation.';
            return;
        }
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                currentPosition = {
                    latitude: pos.coords.latitude,
                    longitude: pos.coords.longitude
                };
                var st = document.getElementById('status-location');
                if (st) {
                    st.innerHTML = '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5);
                }
                dismissLocPrompt();
            },
            function (err) {
                var box = document.getElementById('loc-prompt');
                var t = document.getElementById('loc-prompt-text');
                if (!t || !box) return;
                if (err.code === 1) {
                    box.classList.add('denied');
                    t.innerText = 'location was blocked. on iphone: settings → privacy → location services → safari → while using. then reload this page.';
                } else {
                    t.innerText = geoFailMessage(err);
                }
            },
            { enableHighAccuracy: true, timeout: 25000, maximumAge: 10000 }
        );
    }

    function submitPlace(lat, lng) {
        const formData = new URLSearchParams();
        formData.append('latitude', String(lat));
        formData.append('longitude', String(lng));
        if (placeMode === 'signpost') {
            formData.append('type', 'signpost');
            const txt = document.getElementById('signpost-text').value.trim();
            if (txt.length > 0) formData.append('content', txt);
        } else {
            formData.append('type', 'prop');
            formData.append('fileHash', 'demo_cube');
        }

        fetch(API_URL, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: formData
        })
            .then(function (response) {
                if (response.ok) {
                    return response.json().then(function () {
                        showMessage(placeMode === 'signpost' ? 'signpost placed' : 'cube placed');
                        return loadObjects();
                    });
                }
                return readApiError(response).then(function (msg) {
                    showMessage('place failed: ' + msg, true);
                });
            })
            .catch(function () {
                showMessage('network error on place', true);
            });
    }

    // on iphone, geolocation works best if started from the same tap as the + button
    function placeAtGps() {
        if (currentPosition && typeof currentPosition.latitude === 'number') {
            submitPlace(currentPosition.latitude, currentPosition.longitude);
            return;
        }
        if (!navigator.geolocation) {
            showMessage('this browser has no geolocation', true);
            return;
        }
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                submitPlace(pos.coords.latitude, pos.coords.longitude);
            },
            function (err) {
                if (err.code === 3 || err.code === 2) {
                    navigator.geolocation.getCurrentPosition(
                        function (pos2) {
                            submitPlace(pos2.coords.latitude, pos2.coords.longitude);
                        },
                        function () {
                            showMessage(geoFailMessage(err), true);
                        },
                        { enableHighAccuracy: false, timeout: 20000, maximumAge: 300000 }
                    );
                    return;
                }
                showMessage(geoFailMessage(err), true);
            },
            { enableHighAccuracy: true, timeout: 25000, maximumAge: 10000 }
        );
    }

    function attachCubeGps(scene, obj) {
        var anchor = document.createElement('a-entity');
        anchor.setAttribute('id', 'obj-' + obj.id);
        anchor.setAttribute('gps-entity-place', 'latitude: ' + obj.latitude + '; longitude: ' + obj.longitude);
        anchor.setAttribute('scale', '1 1 1');
        var inner = document.createElement('a-entity');
        if (obj.arYawDeg != null && !isNaN(obj.arYawDeg)) {
            inner.setAttribute('rotation', '0 ' + (-obj.arYawDeg) + ' 0');
        }
        inner.setAttribute('position', '0 0.25 0');
        var s = obj.scale || 1;
        inner.setAttribute('scale', s + ' ' + s + ' ' + s);
        var box = document.createElement('a-box');
        box.setAttribute('width', '0.5');
        box.setAttribute('height', '0.5');
        box.setAttribute('depth', '0.5');
        box.setAttribute('position', '0 0 0');
        box.setAttribute('material', 'color: #d37f8f; opacity: 0.92; roughness: 0.6');
        inner.appendChild(box);
        var tag = document.createElement('a-text');
        tag.setAttribute('value', (obj.fileHash || 'cube').slice(0, 20));
        tag.setAttribute('align', 'center');
        tag.setAttribute('position', '0 0.45 0');
        tag.setAttribute('scale', '0.7 0.7 0.7');
        tag.setAttribute('color', '#ffffff');
        inner.appendChild(tag);
        anchor.appendChild(inner);
        scene.appendChild(anchor);
        return true;
    }

    function attachSignpostGps(scene, obj) {
        var anchor = document.createElement('a-entity');
        anchor.setAttribute('id', 'obj-' + obj.id);
        anchor.setAttribute('gps-entity-place', 'latitude: ' + obj.latitude + '; longitude: ' + obj.longitude);
        anchor.setAttribute('scale', '1 1 1');
        var inner = document.createElement('a-entity');
        if (obj.arYawDeg != null && !isNaN(obj.arYawDeg)) {
            inner.setAttribute('rotation', '0 ' + (-obj.arYawDeg) + ' 0');
        }
        inner.setAttribute('position', '0 0 0');
        var s = obj.scale || 1;
        inner.setAttribute('scale', s + ' ' + s + ' ' + s);
        var pole = document.createElement('a-cylinder');
        pole.setAttribute('radius', '0.04');
        pole.setAttribute('height', '1.1');
        pole.setAttribute('position', '0 0.55 0');
        pole.setAttribute('material', 'color: #5c4033; roughness: 0.9');
        inner.appendChild(pole);
        var board = document.createElement('a-plane');
        board.setAttribute('width', '1.4');
        board.setAttribute('height', '0.42');
        board.setAttribute('position', '0 1.22 0.02');
        board.setAttribute('material', 'color: #f4e8dc; opacity: 0.95; side: double');
        inner.appendChild(board);
        var msg = (obj.content || 'signpost').slice(0, 80);
        var text = document.createElement('a-text');
        text.setAttribute('value', msg);
        text.setAttribute('align', 'center');
        text.setAttribute('position', '0 1.22 0.06');
        text.setAttribute('color', '#2a1a22');
        text.setAttribute('width', '1.25');
        inner.appendChild(text);
        anchor.appendChild(inner);
        scene.appendChild(anchor);
        return true;
    }

    function placeObjectsInScene(scene, list) {
        if (!scene) return;
        function run() {
            list.forEach(function (obj) {
                if (document.getElementById('obj-' + obj.id)) return;
                if (obj.type === 'signpost') {
                    attachSignpostGps(scene, obj);
                } else {
                    attachCubeGps(scene, obj);
                }
            });
        }
        if (scene.hasLoaded) {
            run();
        } else {
            scene.addEventListener('loaded', run, { once: true });
        }
    }

    window.onload = () => {
        const loadingSub = document.getElementById('loading-sub');

        if (!navigator.geolocation) {
            showError("Geolocation is not supported by your browser.");
            return;
        }

        loadingSub.innerText = "Starting camera...";

        // if browser exposes permission state, react; safari often omits this api
        if (navigator.permissions && navigator.permissions.query) {
            navigator.permissions.query({ name: 'geolocation' }).then(function (r) {
                if (r.state === 'granted') {
                    trySilentLocationRead();
                }
                if (r.state === 'denied') {
                    var box = document.getElementById('loc-prompt');
                    var t = document.getElementById('loc-prompt-text');
                    if (box && t) {
                        box.classList.add('denied');
                        t.innerText = 'location is denied for this site. change it in browser settings, then reload.';
                    }
                }
                r.addEventListener('change', function () {
                    if (r.state === 'granted') {
                        trySilentLocationRead();
                    }
                });
            }).catch(function () {});
        }

        setTimeout(trySilentLocationRead, 500);

        document.addEventListener('arjs-video-loaded', () => {
            hideLoading();
        });
        const scene = document.querySelector('a-scene');
        if (scene) {
            function onSceneReady() {
                hideLoading();
                startPlacementReticleLoop(scene);
            }
            if (scene.hasLoaded) {
                onSceneReady();
            } else {
                scene.addEventListener('loaded', onSceneReady);
            }
        }
        setTimeout(() => {
            if (document.getElementById('loading')) {
                hideLoading();
            }
        }, 8000);

        window.addEventListener('gps-camera-update-position', e => {
            currentPosition = {
                latitude: e.detail.position.latitude,
                longitude: e.detail.position.longitude
            };
            document.getElementById('status-location').innerHTML =
                '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5);
            maybeHideLocPrompt();
        });

        if (navigator.geolocation) {
            navigator.geolocation.watchPosition(
                function (pos) {
                    currentPosition = {
                        latitude: pos.coords.latitude,
                        longitude: pos.coords.longitude
                    };
                    var el = document.getElementById('status-location');
                    if (el) {
                        el.innerHTML = '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5);
                    }
                    maybeHideLocPrompt();
                },
                function () { /* silent — use allow location button or + to prompt */ },
                { enableHighAccuracy: true, maximumAge: 5000, timeout: 60000 }
            );
        }

        window.addEventListener('orientationchange', () => {
            setTimeout(() => window.dispatchEvent(new Event('resize')), 200);
        });

        loadObjects();
    };

    function showError(msg) {
        const loadingText = document.getElementById('loading-text');
        const loadingSub = document.getElementById('loading-sub');
        const retryBtn = document.getElementById('retry-btn');

        if (loadingText) loadingText.innerText = "Initialization Failed";
        if (loadingSub) {
            loadingSub.innerText = msg;
            loadingSub.style.color = "#ff6b6b";
        }
        if (retryBtn) retryBtn.style.display = "block";

        document.getElementById('status-location').innerText = msg;
    }

    function hideLoading() {
        const loading = document.getElementById('loading');
        if (loading) {
            loading.style.opacity = '0';
            setTimeout(() => {
                if (loading) loading.remove();
            }, 500);
        }
    }

    function showMessage(msg, isError = false) {
        const statusObj = document.getElementById('status-objects');
        if (!statusObj) return;
        const originalText = statusObj.getAttribute('data-original') || statusObj.innerText;
        if (!statusObj.hasAttribute('data-original')) {
            statusObj.setAttribute('data-original', originalText);
        }
        statusObj.style.color = isError ? '#ff6b6b' : '#4ecd96';
        statusObj.innerText = msg;

        if (window.msgTimeout) clearTimeout(window.msgTimeout);
        window.msgTimeout = setTimeout(() => {
            statusObj.style.color = '#aaa';
            statusObj.innerText = statusObj.getAttribute('data-original');
            window.msgTimeout = null;
        }, 3500);
    }

    async function loadObjects() {
        const scene = document.querySelector('a-scene');
        const statusObj = document.getElementById('status-objects');
        if (!scene) return;
        try {
            const response = await fetch(API_URL, { credentials: 'same-origin' });
            if (!response.ok) {
                showMessage('could not load objects: ' + await readApiError(response), true);
                return;
            }
            const objects = await response.json();
            clearPlacedFromScene(scene);

            statusObj.setAttribute('data-original', 'loaded ' + objects.length + ' things');
            if (!window.msgTimeout) {
                statusObj.innerText = 'loaded ' + objects.length + ' things';
                statusObj.style.color = '#aaa';
            }

            placeObjectsInScene(scene, objects);
        } catch (err) {
            if (statusObj) showMessage('load failed (network?)', true);
        }
    }

</script>

</body>

</html>