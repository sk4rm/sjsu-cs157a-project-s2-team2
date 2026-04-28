const API_URL = window.WARP.apiUrl;
const ASSETS_URL = window.WARP.assetsUrl;
const sessionUserId = window.WARP.userId;
let selectedObjectId = null;

// fileHash convention: "asset:<id>" → uploaded glTF, anything else → default cube.
function parseAssetId(fileHash) {
    if (!fileHash || typeof fileHash !== 'string') return null;
    const m = fileHash.match(/^asset:(\d+)$/);
    return m ? m[1] : null;
}

function selectedAssetHash() {
    const sel = document.getElementById('asset-picker');
    if (!sel || !sel.value) return 'demo_cube';
    return 'asset:' + sel.value;
}

function loadAssetPicker() {
    const sel = document.getElementById('asset-picker');
    if (!sel) return;
    fetch(ASSETS_URL, {credentials: 'same-origin'})
        .then(function (r) { return r.ok ? r.json() : []; })
        .then(function (assets) {
            assets.forEach(function (a) {
                const opt = document.createElement('option');
                opt.value = a.id;
                opt.textContent = a.displayName + ' (#' + a.id + ')';
                sel.appendChild(opt);
            });
        })
        .catch(function () { /* leave default option only */ });
}

function openInspector(obj) {
    selectedObjectId = obj.id;
    document.getElementById('inspector-title').innerText = obj.type === 'signpost' ? 'Signpost' : 'Prop';

    let bodyHtml = '<strong>ID:</strong> ' + obj.id + '<br>';
    if (obj.type === 'signpost') {
        bodyHtml += '<strong>Message:</strong> ' + (obj.content || '') + '<br>';
    } else {
        bodyHtml += '<strong>Hash:</strong> ' + (obj.fileHash || 'default') + '<br>';
    }
    bodyHtml += '<strong>Lat:</strong> ' + obj.latitude.toFixed(6) + '<br>';
    bodyHtml += '<strong>Lng:</strong> ' + obj.longitude.toFixed(6);

    document.getElementById('inspector-body').innerHTML = bodyHtml;

    const deleteBtn = document.getElementById('inspector-delete');
    if (obj.userId === sessionUserId) {
        deleteBtn.style.display = 'block';
    } else {
        deleteBtn.style.display = 'none';
    }

    hideDeleteConfirm();
    document.getElementById('inspector').classList.add('show');
}

function closeInspector() {
    document.getElementById('inspector').classList.remove('show');
    selectedObjectId = null;
    hideDeleteConfirm();
}

// native confirm() can pause the camera MediaStreamTrack on iOS Safari
// (same family of bug as XR view). use inline two-step instead.
function hideDeleteConfirm() {
    const conf = document.getElementById('inspector-confirm');
    if (conf) conf.style.display = 'none';
}

function onDeleteClicked() {
    if (!selectedObjectId) return;
    document.getElementById('inspector-delete').style.display = 'none';
    document.getElementById('inspector-confirm').style.display = 'flex';
}

function onDeleteCancelled() {
    document.getElementById('inspector-confirm').style.display = 'none';
    document.getElementById('inspector-delete').style.display = 'block';
}

function onDeleteConfirmed() {
    if (!selectedObjectId) return;
    const id = selectedObjectId;
    document.getElementById('inspector-confirm').style.display = 'none';
    fetch(API_URL + '/' + id, {
        method: 'DELETE', credentials: 'same-origin'
    }).then(function (resp) {
        if (resp.ok) {
            showMessage('Object deleted');
            const el = document.getElementById('obj-' + id);
            if (el) el.remove();
            closeInspector();
        } else {
            return readApiError(resp).then(function (msg) {
                showMessage('Delete failed: ' + msg, true);
                onDeleteCancelled();
            });
        }
    }).catch(function (err) {
        showMessage('Network error on delete', true);
        onDeleteCancelled();
    });
}

function setupObjectClick(el, obj) {
    el.classList.add('clickable');
    el.addEventListener('click', function (evt) {
        // Prevent multiple objects from triggering at once if they overlap
        evt.stopPropagation();
        openInspector(obj);
    });
}

let currentPosition = null;
let lastGpsAccuracy = null;
let placeMode = 'cube';
// gps = post lat/lng, world = drop where the ring is (scene root)
let placeSpace = 'gps';

// smooth the camera between AR.js GPS fixes — without this the scene
// snaps every ~1s when watchPosition delivers a new sample.
if (window.AFRAME && !AFRAME.components['gps-smoother']) {
    AFRAME.registerComponent('gps-smoother', {
        schema: {durationMs: {default: 300}}, init: function () {
            this.target = new THREE.Vector3();
            this.displayed = new THREE.Vector3();
            this.haveTarget = false;
            var self = this;
            this._onFix = function () {
                // wait one tick so AR.js has applied the new camera pos
                setTimeout(function () {
                    self.target.copy(self.el.object3D.position);
                    if (!self.haveTarget) {
                        self.displayed.copy(self.target);
                        self.haveTarget = true;
                    }
                }, 0);
            };
            window.addEventListener('gps-camera-update-position', this._onFix);
        }, remove: function () {
            window.removeEventListener('gps-camera-update-position', this._onFix);
        }, tick: function (time, dt) {
            if (!this.haveTarget) return;
            var dur = this.data.durationMs || 300;
            var alpha = Math.min(1, dt / dur);
            this.displayed.lerp(this.target, alpha);
            this.el.object3D.position.copy(this.displayed);
        }
    });
}

function setPlaceMode(mode) {
    placeMode = mode;
    document.getElementById('mode-cube').classList.toggle('on', mode === 'cube');
    document.getElementById('mode-sign').classList.toggle('on', mode === 'signpost');
    const inp = document.getElementById('signpost-text');
    inp.disabled = mode !== 'signpost';
    syncPlaceHint();
}

function setPlaceSpace(space) {
    placeSpace = space;
    document.getElementById('space-gps').classList.toggle('on', space === 'gps');
    document.getElementById('space-world').classList.toggle('on', space === 'world');
    syncPlaceHint();
}

function syncPlaceHint() {
    const el = document.getElementById('place-hint');
    if (!el) return;
    if (placeSpace === 'world') {
        if (placeMode === 'signpost') {
            el.innerText = 'aim the ring, type message, tap + — signpost stays in world space';
        } else {
            el.innerText = 'aim the green ring, then tap + — cube stays put as you move';
        }
    } else {
        el.innerText = placeMode === 'cube' ? 'drops a pink-ish cube at your coords' : 'drops a pole + board with your message';
    }
}

function readApiError(response) {
    return response.text().then(function (t) {
        return t.slice(0, 120) || response.statusText;
    });
}

// clear server-spawned stuff before we redraw (obj-* ids)
function clearPlacedFromScene(scene) {
    if (!scene) return;
    scene.querySelectorAll('[id^="obj-"]').forEach(el => el.remove());
}

// localStorage for world mode only; db props still come from /api
var WORLD_SESSION_KEY = 'warp-world-placements-v1';

function appendWorldPlacementSession(rec) {
    try {
        var list = JSON.parse(localStorage.getItem(WORLD_SESSION_KEY) || '[]');
        if (!Array.isArray(list)) list = [];
        list.push(rec);
        localStorage.setItem(WORLD_SESSION_KEY, JSON.stringify(list));
        console.log('[ARP] session saved:', rec.kind, rec.id);
    } catch (e) {
        console.warn('[ARP] session save failed', e);
    }
}

function spawnWorldCubeEntity(scene, id, wx, wy, wz, fileHash) {
    var root = document.createElement('a-entity');
    root.setAttribute('id', id);
    root.setAttribute('position', wx + ' ' + wy + ' ' + wz);
    var inner = document.createElement('a-entity');
    inner.setAttribute('position', '0 0.25 0');
    appendPropBody(inner, {fileHash: fileHash});
    root.appendChild(inner);
    scene.appendChild(root);
}

function spawnWorldSignpostEntity(scene, id, wx, wy, wz, msg) {
    var root = document.createElement('a-entity');
    root.setAttribute('id', id);
    root.setAttribute('position', wx + ' ' + wy + ' ' + wz);
    var inner = document.createElement('a-entity');
    inner.setAttribute('position', '0 0 0');
    fillSignpostInner(inner, msg);
    root.appendChild(inner);
    scene.appendChild(root);
}

function restoreWorldPlacementsFromSession(scene) {
    function run() {
        var list = [];
        try {
            list = JSON.parse(localStorage.getItem(WORLD_SESSION_KEY) || '[]');
        } catch (e) {
            return;
        }
        if (!Array.isArray(list)) return;
        var n = 0;
        list.forEach(function (rec) {
            if (!rec || !rec.id || document.getElementById(rec.id)) return;
            if (rec.kind === 'cube' && rec.x != null && rec.y != null && rec.z != null) {
                spawnWorldCubeEntity(scene, rec.id, rec.x, rec.y, rec.z, rec.fileHash);
                n++;
            } else if (rec.kind === 'signpost' && rec.content != null && rec.x != null && rec.y != null && rec.z != null) {
                spawnWorldSignpostEntity(scene, rec.id, rec.x, rec.y, rec.z, rec.content);
                n++;
            }
        });
        if (n > 0) console.log('[ARP] restored', n, 'world placements from localStorage');
    }

    if (scene.hasLoaded) {
        run();
    } else {
        scene.addEventListener('loaded', run, {once: true});
    }
}

// middle of screen ray -> y=0 floor, else 2m in front of you
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
    return {x: wx, y: wy, z: wz, usedPlane: usedPlane};
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

// ring chases that hit point every frame
function startPlacementReticleLoop(scene) {
    function tick() {
        var t = computeWorldPlacementTarget(scene);
        var reticle = document.getElementById('placement-reticle');
        if (placeSpace === 'world' && t && reticle) {
            reticle.setAttribute('visible', true);
            reticle.setAttribute('position', t.x + ' ' + t.y + ' ' + t.z);
        } else if (reticle) {
            reticle.setAttribute('visible', false);
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
        scene.addEventListener('loaded', begin, {once: true});
    }
}

// scratch green cube to sanity-check placement
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
        console.log('[ARP] test cube hit floor?', t.usedPlane, 'xyz', wx.toFixed(3), wy.toFixed(3), wz.toFixed(3));
        console.log('[ARP] parent tag:', p && p.tagName, 'is scene root:', p === scene);
        scene.object3D.updateMatrixWorld(true);
        var wpos = new THREE.Vector3();
        root.object3D.getWorldPosition(wpos);
        console.log('[ARP] placed entity world position:', wpos.x.toFixed(3), wpos.y.toFixed(3), wpos.z.toFixed(3));
    };

    if (scene.hasLoaded) {
        run();
    } else {
        scene.addEventListener('loaded', run, {once: true});
    }
}

// ring position -> try api (gps + ar xyz), else localStorage fallback
function placeWorldSpacePermanentCube() {
    const scene = document.querySelector('a-scene');
    if (!scene) return;
    const run = function () {
        const THREE = window.THREE;
        const t = computeWorldPlacementTarget(scene);
        if (!t || !THREE) {
            showMessage('could not place — wait for scene', true);
            return;
        }
        var wx = t.x, wy = t.y, wz = t.z;
        resolveLatLngThen(function (lat, lng) {
            function offlineDrop() {
                var id = 'world-placed-' + Date.now();
                var hash = selectedAssetHash();
                spawnWorldCubeEntity(scene, id, wx, wy, wz, hash);
                appendWorldPlacementSession({kind: 'cube', id: id, x: wx, y: wy, z: wz, fileHash: hash, savedAt: Date.now()});
                showMessage('no gps / server — saved local only', true);
            }

            if (lat == null || lng == null) {
                offlineDrop();
                return;
            }
            submitWorldPlaceWithAr(lat, lng, wx, wy, wz, false)
                .then(function (response) {
                    if (response.ok) {
                        return response.json().then(function () {
                            showMessage('cube saved');
                            return loadObjects();
                        });
                    }
                    return readApiError(response).then(function (msg) {
                        showMessage('save failed: ' + msg, true);
                        offlineDrop();
                    });
                })
                .catch(function () {
                    showMessage('network bust — local copy kept', true);
                    offlineDrop();
                });
        });
    };
    if (scene.hasLoaded) {
        run();
    } else {
        scene.addEventListener('loaded', run, {once: true});
    }
}

// plain text, no look-at (that messes with staying put)
function fillSignpostInner(inner, contentSlice) {
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
    var text = document.createElement('a-text');
    text.setAttribute('value', contentSlice);
    text.setAttribute('align', 'center');
    text.setAttribute('position', '0 1.22 0.06');
    text.setAttribute('color', '#2a1a22');
    text.setAttribute('width', '1.25');
    inner.appendChild(text);
}

// same as cube but signpost type + text field
function placeWorldSpacePermanentSignpost() {
    const scene = document.querySelector('a-scene');
    if (!scene) return;
    const run = function () {
        const THREE = window.THREE;
        const t = computeWorldPlacementTarget(scene);
        if (!t || !THREE) {
            showMessage('could not place — wait for scene', true);
            return;
        }
        var wx = t.x, wy = t.y, wz = t.z;
        var raw = document.getElementById('signpost-text').value.trim();
        var msg = (raw.length > 0 ? raw : 'signpost').slice(0, 80);
        resolveLatLngThen(function (lat, lng) {
            function offlineDrop() {
                var id = 'world-signpost-' + Date.now();
                spawnWorldSignpostEntity(scene, id, wx, wy, wz, msg);
                appendWorldPlacementSession({
                    kind: 'signpost', id: id, x: wx, y: wy, z: wz, content: msg, savedAt: Date.now()
                });
                showMessage('no gps / server — saved local only', true);
            }

            if (lat == null || lng == null) {
                offlineDrop();
                return;
            }
            submitWorldPlaceWithAr(lat, lng, wx, wy, wz, true)
                .then(function (response) {
                    if (response.ok) {
                        return response.json().then(function () {
                            showMessage('signpost saved');
                            return loadObjects();
                        });
                    }
                    return readApiError(response).then(function (errMsg) {
                        showMessage('save failed: ' + errMsg, true);
                        offlineDrop();
                    });
                })
                .catch(function () {
                    showMessage('network bust — local copy kept', true);
                    offlineDrop();
                });
        });
    };
    if (scene.hasLoaded) {
        run();
    } else {
        scene.addEventListener('loaded', run, {once: true});
    }
}

function onPlaceButton() {
    if (placeSpace === 'world') {
        if (placeMode === 'signpost') {
            placeWorldSpacePermanentSignpost();
            return;
        }
        placeWorldSpacePermanentCube();
        return;
    }
    placeAtGps();
}

// turn geo error codes into something readable
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

// ios wants a real button press before the location popup
function requestLocationPermission() {
    var box = document.getElementById('loc-prompt');
    if (box) box.classList.remove('denied');
    // ios safari ≥13: orientation events are gated behind a user-gesture permission
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
        DeviceOrientationEvent.requestPermission().catch(function () {
        });
    }
    if (!navigator.geolocation) {
        var t0 = document.getElementById('loc-prompt-text');
        if (t0) t0.innerText = 'this browser does not support geolocation.';
        return;
    }
    navigator.geolocation.getCurrentPosition(function (pos) {
        currentPosition = {
            latitude: pos.coords.latitude, longitude: pos.coords.longitude
        };
        var st = document.getElementById('status-location');
        if (st) {
            st.innerHTML = '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5);
        }
        dismissLocPrompt();
    }, function (err) {
        var box = document.getElementById('loc-prompt');
        var t = document.getElementById('loc-prompt-text');
        if (!t || !box) return;
        if (err.code === 1) {
            box.classList.add('denied');
            t.innerText = 'location was blocked. on iphone: settings → privacy → location services → safari → while using. then reload this page.';
        } else {
            t.innerText = geoFailMessage(err);
        }
    }, {enableHighAccuracy: true, timeout: 25000, maximumAge: 10000});
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
        formData.append('fileHash', selectedAssetHash());
    }

    fetch(API_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
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

// gps tag + a-frame xyz for world drops (api already stores ar_x etc)
function submitWorldPlaceWithAr(lat, lng, wx, wy, wz, isSignpost) {
    const formData = new URLSearchParams();
    formData.append('latitude', String(lat));
    formData.append('longitude', String(lng));
    formData.append('arX', String(wx));
    formData.append('arY', String(wy));
    formData.append('arZ', String(wz));
    if (isSignpost) {
        formData.append('type', 'signpost');
        const txt = document.getElementById('signpost-text').value.trim();
        if (txt.length > 0) formData.append('content', txt);
    } else {
        formData.append('type', 'prop');
        formData.append('fileHash', selectedAssetHash());
    }
    return fetch(API_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData
    });
}

// placement-time gps: never trust a cached fix, never accept a coarse one
const PLACEMENT_ACCURACY_GATE_M = 20;   // reject fixes worse than this
const PLACEMENT_SAMPLE_WINDOW_MS = 4000; // watchPosition burst length
const PLACEMENT_EARLY_EXIT_M = 8;        // settle immediately on a fix this good
const PLACEMENT_HARD_TIMEOUT_MS = 25000;

// runs a short watchPosition burst and picks the most-accurate sample.
// ok(lat, lng, accM) on a fix within the gate; fail(reason, bestSeenAccM) otherwise.
function acquireBestFix(ok, fail) {
    if (!navigator.geolocation) {
        fail('no-geo', null);
        return;
    }
    let best = null;
    let watchId = null;
    let settled = false;
    let windowTimer = null;

    function clearWatch() {
        if (watchId != null) {
            try {
                navigator.geolocation.clearWatch(watchId);
            } catch (e) {
            }
            watchId = null;
        }
        if (windowTimer != null) {
            clearTimeout(windowTimer);
            windowTimer = null;
        }
    }

    function settle() {
        if (settled) return;
        settled = true;
        clearWatch();
        if (!best) {
            fail('no-fix', null);
            return;
        }
        if (best.acc > PLACEMENT_ACCURACY_GATE_M) {
            fail('weak', best.acc);
            return;
        }
        currentPosition = {latitude: best.lat, longitude: best.lng};
        var st = document.getElementById('status-location');
        if (st) {
            st.innerHTML = '<strong>GPS</strong>: ' + best.lat.toFixed(5) + ', ' + best.lng.toFixed(5) + ' (±' + Math.round(best.acc) + 'm)';
        }
        ok(best.lat, best.lng, best.acc);
    }

    try {
        watchId = navigator.geolocation.watchPosition(function (pos) {
            var acc = pos.coords.accuracy;
            if (best === null || acc < best.acc) {
                best = {lat: pos.coords.latitude, lng: pos.coords.longitude, acc: acc};
            }
            if (acc <= PLACEMENT_EARLY_EXIT_M) settle();
        }, function (err) {
            // surface only if we never got a single sample
            if (!best && (err.code === 1 || err.code === 2)) {
                if (settled) return;
                settled = true;
                clearWatch();
                fail(err.code === 1 ? 'denied' : 'unavailable', null);
            }
        }, {enableHighAccuracy: true, timeout: PLACEMENT_HARD_TIMEOUT_MS, maximumAge: 0});
    } catch (e) {
        fail('exception', null);
        return;
    }

    windowTimer = setTimeout(settle, PLACEMENT_SAMPLE_WINDOW_MS);
}

function gpsFailToast(reason, bestAcc) {
    if (reason === 'weak' && bestAcc != null) {
        showMessage('gps too weak (±' + Math.round(bestAcc) + 'm). step outside or wait, then retry', true);
    } else if (reason === 'denied') {
        showMessage('location was blocked. enable it in settings, then reload', true);
    } else if (reason === 'no-geo') {
        showMessage('this browser has no geolocation', true);
    } else if (reason === 'no-fix') {
        showMessage('no gps fix yet. step outside or wait, then retry', true);
    } else {
        showMessage('gps unavailable. try again outdoors', true);
    }
}

function resolveLatLngThen(callback) {
    acquireBestFix(function (lat, lng) {
        callback(lat, lng);
    }, function (reason, bestAcc) {
        gpsFailToast(reason, bestAcc);
        callback(null, null);
    });
}

// same tap as + helps gps on iphone
function placeAtGps() {
    showMessage('locking gps…');
    acquireBestFix(function (lat, lng) {
        submitPlace(lat, lng);
    }, function (reason, bestAcc) {
        gpsFailToast(reason, bestAcc);
    });
}

// shared cube/asset body — sized 0.5m default cube, or a-gltf-model if fileHash is "asset:N".
// returns the array of clickable elements added.
function appendPropBody(parent, obj) {
    var assetId = parseAssetId(obj.fileHash);
    var clickables = [];
    if (assetId) {
        var model = document.createElement('a-gltf-model');
        model.setAttribute('src', ASSETS_URL + '/' + assetId);
        model.setAttribute('position', '0 0 0');
        parent.appendChild(model);
        clickables.push(model);
    } else {
        var box = document.createElement('a-box');
        box.setAttribute('width', '0.5');
        box.setAttribute('height', '0.5');
        box.setAttribute('depth', '0.5');
        box.setAttribute('position', '0 0 0');
        box.setAttribute('material', 'color: #d37f8f; opacity: 0.92; roughness: 0.6');
        parent.appendChild(box);
        clickables.push(box);
        var tag = document.createElement('a-text');
        tag.setAttribute('value', (obj.fileHash || 'cube').slice(0, 20));
        tag.setAttribute('align', 'center');
        tag.setAttribute('position', '0 0.45 0');
        tag.setAttribute('scale', '0.7 0.7 0.7');
        tag.setAttribute('color', '#ffffff');
        parent.appendChild(tag);
        clickables.push(tag);
    }
    return clickables;
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
    appendPropBody(inner, obj).forEach(function (el) { setupObjectClick(el, obj); });
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
    var msg = (obj.content || 'signpost').slice(0, 80);
    fillSignpostInner(inner, msg);
    anchor.appendChild(inner);
    scene.appendChild(anchor);

    inner.querySelectorAll('a-cylinder, a-plane, a-text').forEach(function (el) {
        setupObjectClick(el, obj);
    });
    return true;
}

function objectHasWorldAnchor(obj) {
    return obj && typeof obj.arX === 'number' && typeof obj.arY === 'number' && typeof obj.arZ === 'number' && !isNaN(obj.arX) && !isNaN(obj.arY) && !isNaN(obj.arZ);
}

function attachCubeWorld(scene, obj) {
    var root = document.createElement('a-entity');
    root.setAttribute('id', 'obj-' + obj.id);
    root.setAttribute('position', obj.arX + ' ' + obj.arY + ' ' + obj.arZ);
    var inner = document.createElement('a-entity');
    if (obj.arYawDeg != null && !isNaN(obj.arYawDeg)) {
        inner.setAttribute('rotation', '0 ' + (-obj.arYawDeg) + ' 0');
    }
    inner.setAttribute('position', '0 0.25 0');
    var s = obj.scale || 1;
    inner.setAttribute('scale', s + ' ' + s + ' ' + s);
    appendPropBody(inner, obj).forEach(function (el) { setupObjectClick(el, obj); });
    root.appendChild(inner);
    scene.appendChild(root);
    return true;
}

function attachSignpostWorld(scene, obj) {
    var root = document.createElement('a-entity');
    root.setAttribute('id', 'obj-' + obj.id);
    root.setAttribute('position', obj.arX + ' ' + obj.arY + ' ' + obj.arZ);
    var inner = document.createElement('a-entity');
    if (obj.arYawDeg != null && !isNaN(obj.arYawDeg)) {
        inner.setAttribute('rotation', '0 ' + (-obj.arYawDeg) + ' 0');
    }
    inner.setAttribute('position', '0 0 0');
    var s = obj.scale || 1;
    inner.setAttribute('scale', s + ' ' + s + ' ' + s);
    var msg = (obj.content || 'signpost').slice(0, 80);
    fillSignpostInner(inner, msg);
    root.appendChild(inner);
    scene.appendChild(root);

    inner.querySelectorAll('a-cylinder, a-plane, a-text').forEach(function (el) {
        setupObjectClick(el, obj);
    });
    return true;
}

function placeObjectsInScene(scene, list) {
    if (!scene) return;

    function run() {
        list.forEach(function (obj) {
            if (document.getElementById('obj-' + obj.id)) return;
            if (objectHasWorldAnchor(obj)) {
                if (obj.type === 'signpost') {
                    attachSignpostWorld(scene, obj);
                } else {
                    attachCubeWorld(scene, obj);
                }
            } else if (obj.type === 'signpost') {
                attachSignpostGps(scene, obj);
            } else {
                attachCubeGps(scene, obj);
            }
        });
    }

    if (scene.hasLoaded) {
        run();
    } else {
        scene.addEventListener('loaded', run, {once: true});
    }
}

window.onload = () => {
    const loadingSub = document.getElementById('loading-sub');

    if (!navigator.geolocation) {
        showError("Geolocation is not supported by your browser.");
        return;
    }

    loadingSub.innerText = "Starting camera...";

    // surface "denied" state in the prompt; AR.js owns the actual GPS subscription
    if (navigator.permissions && navigator.permissions.query) {
        navigator.permissions.query({name: 'geolocation'}).then(function (r) {
            if (r.state === 'denied') {
                var box = document.getElementById('loc-prompt');
                var t = document.getElementById('loc-prompt-text');
                if (box && t) {
                    box.classList.add('denied');
                    t.innerText = 'location is denied for this site. change it in browser settings, then reload.';
                }
            }
        }).catch(function () {
        });
    }

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
            latitude: e.detail.position.latitude, longitude: e.detail.position.longitude
        };
        var acc = e.detail.position.accuracy;
        lastGpsAccuracy = (typeof acc === 'number') ? acc : null;
        console.log('[gps]', e.detail.position.latitude.toFixed(6), e.detail.position.longitude.toFixed(6), 'acc=', acc);
        var accLabel = (lastGpsAccuracy != null) ? ' (±' + Math.round(lastGpsAccuracy) + 'm)' : '';
        var quality = '';
        if (lastGpsAccuracy != null) {
            if (lastGpsAccuracy <= 10) quality = ' · good'; else if (lastGpsAccuracy <= 20) quality = ' · ok'; else quality = ' · weak';
        }
        document.getElementById('status-location').innerHTML = '<strong>GPS</strong>: ' + currentPosition.latitude.toFixed(5) + ', ' + currentPosition.longitude.toFixed(5) + accLabel + quality;
        maybeHideLocPrompt();
    });

    window.addEventListener('orientationchange', () => {
        setTimeout(() => window.dispatchEvent(new Event('resize')), 200);
    });

    syncPlaceHint();
    loadAssetPicker();
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
        const response = await fetch(API_URL, {credentials: 'same-origin'});
        if (!response.ok) {
            showMessage('could not load objects: ' + await readApiError(response), true);
            restoreWorldPlacementsFromSession(scene);
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
        restoreWorldPlacementsFromSession(scene);
    } catch (err) {
        if (statusObj) showMessage('load failed (network?)', true);
        restoreWorldPlacementsFromSession(scene);
    }
}
