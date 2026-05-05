const API_URL = window.WARP.apiUrl;
const ASSETS_URL = window.WARP.assetsUrl;
const sessionUserId = window.WARP.userId;
const LAYER_FILTER_KEY = 'warp-active-layer-id';
let selectedObjectId = null;

// fileHash convention: "asset:<id>" → uploaded glTF; "preset:*" → built-in shape; legacy hashes → cube.
function parseAssetId(fileHash) {
    if (!fileHash || typeof fileHash !== 'string') return null;
    const m = fileHash.match(/^asset:(\d+)$/);
    return m ? m[1] : null;
}

/** @returns {'cube'|'bread'|'stars'|null} null = legacy / unknown (render as labeled cube) */
function parsePresetKind(fileHash) {
    if (!fileHash || typeof fileHash !== 'string') return 'cube';
    if (fileHash.startsWith('preset:')) {
        const p = fileHash.slice(7);
        if (p === 'bread' || p === 'stars' || p === 'cube') return p;
        return 'cube';
    }
    if (fileHash === 'demo_cube' || fileHash === 'default_box_hash') return 'cube';
    return null;
}

function selectedPropHash() {
    const sel = document.getElementById('asset-picker');
    if (!sel || !sel.value) return 'preset:cube';
    const v = sel.value;
    if (typeof v === 'string' && v.startsWith('preset:')) return v;
    return 'asset:' + v;
}

function loadAssetPicker() {
    const uploads = document.getElementById('asset-picker-uploads');
    const sel = document.getElementById('asset-picker');
    const parent = uploads || sel;
    if (!parent || !ASSETS_URL) return;
    fetch(ASSETS_URL, {credentials: 'same-origin'})
        .then(function (r) { return r.ok ? r.json() : []; })
        .then(function (assets) {
            assets.forEach(function (a) {
                const opt = document.createElement('option');
                opt.value = a.id;
                opt.textContent = a.displayName + ' (#' + a.id + ')';
                if (uploads) uploads.appendChild(opt);
                else sel.appendChild(opt);
            });
        })
        .catch(function () { /* leave presets only */ });
}

function loadLayerPicker() {
    const sel = document.getElementById('layer-picker');
    const url = window.WARP && window.WARP.layersUrl;
    if (!sel || !url) return;
    fetch(url, {credentials: 'same-origin'})
        .then(function (r) { return r.ok ? r.json() : []; })
        .then(function (layers) {
            while (sel.options.length > 1) sel.remove(1);
            layers.forEach(function (L) {
                const opt = document.createElement('option');
                opt.value = String(L.layerId);
                opt.textContent = L.name;
                sel.appendChild(opt);
            });
            const saved = localStorage.getItem(LAYER_FILTER_KEY);
            if (saved && Array.prototype.some.call(sel.options, function (o) { return o.value === saved; })) {
                sel.value = saved;
            }
            if (originLat != null) loadObjects();
        })
        .catch(function () { /* All layers only */ });
    sel.addEventListener('change', function () {
        localStorage.setItem(LAYER_FILTER_KEY, sel.value || '');
        loadObjects();
    });
}

function filterObjectsByLayer(list) {
    const sel = document.getElementById('layer-picker');
    if (!sel || !sel.value) return list;
    const lid = Number(sel.value);
    if (isNaN(lid)) return list;
    return list.filter(function (obj) {
        const lids = obj.layerIds;
        if (!lids || !lids.length) return false;
        return lids.some(function (x) { return Number(x) === lid; });
    });
}

function clearPlacedObjects(scene) {
    if (!scene) return;
    scene.querySelectorAll('[id^="obj-"]').forEach(function (el) { el.remove(); });
    placedIds.clear();
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
    if (obj.layerIds && obj.layerIds.length) {
        bodyHtml += '<br><strong>Layers:</strong> #' + obj.layerIds.join(', #');
    }

    document.getElementById('inspector-body').innerHTML = bodyHtml;

    const deleteBtn = document.getElementById('inspector-delete');
    if (obj.userId === sessionUserId) {
        deleteBtn.style.display = 'block';
    } else {
        deleteBtn.style.display = 'none';
    }

    resetDeleteConfirm();
    document.getElementById('inspector').classList.add('show');
    if (typeof loadInspectorSocial === 'function') {
        loadInspectorSocial(obj.id);
    }
}

function closeInspector() {
    document.getElementById('inspector').classList.remove('show');
    selectedObjectId = null;
    resetDeleteConfirm();
    if (typeof clearInspectorSocial === 'function') {
        clearInspectorSocial();
    }
}

// inline two-step confirm: native confirm() can pause the camera
// MediaStreamTrack on iOS Safari, which causes a brief black-frame flicker.
function resetDeleteConfirm() {
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
            showToast('Object deleted');
            const el = document.getElementById('obj-' + id);
            if (el) el.remove();
            placedIds.delete(id);
            closeInspector();
        } else {
            return resp.text().then(function (msg) {
                showToast('Delete failed: ' + msg.slice(0, 50), true);
                onDeleteCancelled();
            });
        }
    }).catch(function () {
        showToast('Network error on delete', true);
        onDeleteCancelled();
    });
}

function setupObjectClick(el, obj) {
    el.classList.add('clickable');
    el.addEventListener('click', function (evt) {
        evt.stopPropagation();
        openInspector(obj);
    });
}

let placeMode = 'cube';

// GPS-anchored origin: lat/lon at session start. Everything else is local meters.
let originLat = null, originLon = null, originAcc = null;
const M_PER_DEG_LAT = 111320; // close enough for short distances
let placedIds = new Set();
let cameraStream = null;

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

function showFatal(msg) {
    const sub = document.getElementById('loading-sub');
    const start = document.getElementById('start-btn');
    const retry = document.getElementById('retry-btn');
    if (sub) {
        sub.innerText = msg;
        sub.style.color = '#ff8b8b';
    }
    if (start) start.style.display = 'none';
    if (retry) retry.style.display = 'inline-block';
}

// lat/lon → local meters (equirectangular, valid for sub-km distances)
function latLonToLocal(lat, lon) {
    if (originLat == null) return null;
    const dLat = lat - originLat;
    const dLon = lon - originLon;
    const x = dLon * Math.cos(originLat * Math.PI / 180) * M_PER_DEG_LAT;
    const z = -dLat * M_PER_DEG_LAT; // -Z is "north" by convention here
    return {x: x, z: z};
}

function localToLatLon(x, z) {
    if (originLat == null) return null;
    const dLat = -z / M_PER_DEG_LAT;
    const dLon = x / (Math.cos(originLat * Math.PI / 180) * M_PER_DEG_LAT);
    return {lat: originLat + dLat, lon: originLon + dLon};
}

// sample-and-pick GPS burst — same approach as world.jsp's acquireBestFix
function lockOriginGps() {
    return new Promise(function (resolve, reject) {
        if (!navigator.geolocation) {
            reject(new Error('no-geo'));
            return;
        }
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
            if (!best) {
                reject(new Error('no-fix'));
                return;
            }
            if (best.acc > GATE) {
                reject(new Error('weak:' + Math.round(best.acc)));
                return;
            }
            resolve(best);
        }

        try {
            watchId = navigator.geolocation.watchPosition(function (pos) {
                const acc = pos.coords.accuracy;
                if (best === null || acc < best.acc) {
                    best = {lat: pos.coords.latitude, lon: pos.coords.longitude, acc: acc};
                }
                if (acc <= EARLY) settle();
            }, function (err) {
                if (!best && (err.code === 1 || err.code === 2)) {
                    settled = true;
                    if (watchId != null) {
                        try { navigator.geolocation.clearWatch(watchId); } catch (e) {}
                    }
                    reject(new Error(err.code === 1 ? 'denied' : 'unavailable'));
                }
            }, {enableHighAccuracy: true, timeout: 25000, maximumAge: 0});
        } catch (e) {
            reject(e);
            return;
        }
        setTimeout(settle, WINDOW);
    });
}

// iOS Safari ≥13 gates DeviceOrientationEvent behind a per-origin permission
// that *must* be requested from inside a user-gesture handler. Android Chrome
// has no such gate — it returns true immediately. Resolves true on grant or
// when the API isn't gated; false if the user denied.
function requestOrientationPermission() {
    return new Promise(function (resolve) {
        if (typeof DeviceOrientationEvent === 'undefined' ||
            typeof DeviceOrientationEvent.requestPermission !== 'function') {
            resolve(true);
            return;
        }
        DeviceOrientationEvent.requestPermission()
            .then(function (state) { resolve(state === 'granted'); })
            .catch(function () { resolve(false); });
    });
}

// rear-facing camera, sized to fill the viewport. We don't constrain
// resolution — the browser picks a sensible default and the <video> element's
// CSS object-fit: cover handles aspect.
function startCamera() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        return Promise.reject(new Error('getUserMedia not supported'));
    }
    const constraints = {
        video: {facingMode: {ideal: 'environment'}},
        audio: false
    };
    return navigator.mediaDevices.getUserMedia(constraints)
        .then(function (stream) {
            cameraStream = stream;
            const video = document.getElementById('camera-feed');
            video.srcObject = stream;
            // playsinline + muted are already in the markup; play() returns a
            // Promise that rejects on iOS if the call wasn't from a gesture,
            // but we *are* in the Start handler so it works.
            return video.play().catch(function () { /* autoplay race; harmless */ });
        });
}

// ---- entity factories (mirror world.jsp's visual style, minus gps-entity-place) ----

function appendPresetShapes(inner, kind, obj) {
    if (kind === 'bread') {
        const loaf = document.createElement('a-box');
        loaf.setAttribute('width', '0.5');
        loaf.setAttribute('height', '0.28');
        loaf.setAttribute('depth', '0.72');
        loaf.setAttribute('position', '0 0.14 0');
        loaf.setAttribute('material', 'color: #c9a227; roughness: 0.78; metalness: 0.06');
        inner.appendChild(loaf);
        setupObjectClick(loaf, obj);
        const dome = document.createElement('a-sphere');
        dome.setAttribute('radius', '0.16');
        dome.setAttribute('position', '0 0.38 0.12');
        dome.setAttribute('scale', '1 0.55 1');
        dome.setAttribute('material', 'color: #e8d4a8; roughness: 0.82');
        inner.appendChild(dome);
        setupObjectClick(dome, obj);
        return;
    }
    if (kind === 'stars') {
        const grp = document.createElement('a-entity');
        grp.setAttribute('position', '0 0.35 0');
        const colors = ['#ffe082', '#fff9c4', '#ffecb3'];
        for (let i = 0; i < 5; i++) {
            const spike = document.createElement('a-tetrahedron');
            const ang = (i / 5) * Math.PI * 2;
            const r = 0.22;
            spike.setAttribute('radius', '0.12');
            spike.setAttribute('position', (Math.cos(ang) * r) + ' 0 ' + (Math.sin(ang) * r));
            spike.setAttribute('rotation', (i * 31) + ' ' + (i * 17) + ' 0');
            spike.setAttribute('material', 'color: ' + colors[i % colors.length] +
                '; emissive: #b8860b; emissiveIntensity: 0.45; metalness: 0.22; roughness: 0.38');
            grp.appendChild(spike);
            setupObjectClick(spike, obj);
        }
        const core = document.createElement('a-octahedron');
        core.setAttribute('radius', '0.1');
        core.setAttribute('material', 'color: #fffde7; emissive: #ffc107; emissiveIntensity: 0.55; metalness: 0.28; roughness: 0.22');
        grp.appendChild(core);
        setupObjectClick(core, obj);
        inner.appendChild(grp);
        return;
    }
    const box = document.createElement('a-box');
    box.setAttribute('width', '0.5');
    box.setAttribute('height', '0.5');
    box.setAttribute('depth', '0.5');
    box.setAttribute('material', 'color: #d37f8f; metalness: 0.1; roughness: 0.7');
    inner.appendChild(box);
    setupObjectClick(box, obj);
}

function buildCubeEntity(obj, x, z) {
    const id = obj.id;
    const scale = obj.scale;
    const yawDeg = obj.arYawDeg;
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
    const assetId = parseAssetId(obj.fileHash);
    if (assetId) {
        // a-frame core has no <a-gltf-model> primitive — use the gltf-model
        // component on a plain entity, with the url() wrapper it requires for
        // direct (non-asset) URLs.
        const model = document.createElement('a-entity');
        model.setAttribute('gltf-model', 'url(' + ASSETS_URL + '/' + assetId + ')');
        inner.appendChild(model);
        setupObjectClick(model, obj);
    } else {
        const preset = parsePresetKind(obj.fileHash);
        if (preset != null) {
            appendPresetShapes(inner, preset, obj);
        } else {
            const box = document.createElement('a-box');
            box.setAttribute('width', '0.5');
            box.setAttribute('height', '0.5');
            box.setAttribute('depth', '0.5');
            box.setAttribute('material', 'color: #d37f8f; metalness: 0.1; roughness: 0.7');
            inner.appendChild(box);
            setupObjectClick(box, obj);
        }
    }
    root.appendChild(inner);
    return root;
}

function buildSignpostEntity(obj, x, z) {
    const id = obj.id;
    const scale = obj.scale;
    const yawDeg = obj.arYawDeg;
    const text = obj.content;
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

    [pole, board, txt].forEach(el => setupObjectClick(el, obj));
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
    const entity = (obj.type === 'signpost') ? buildSignpostEntity(obj, local.x, local.z) : buildCubeEntity(obj, local.x, local.z);
    scene.appendChild(entity);
    placedIds.add(obj.id);
}

function loadObjects() {
    const scene = document.querySelector('a-scene');
    if (!scene) return;
    return fetch(API_URL, {credentials: 'same-origin'})
        .then(function (r) {
            return r.ok ? r.json() : [];
        })
        .then(function (list) {
            if (!Array.isArray(list)) list = (list && list.objects) || [];
            list = filterObjectsByLayer(list);
            clearPlacedObjects(scene);
            list.forEach(function (obj) {
                placeObjectInScene(scene, obj);
            });
            const sel = document.getElementById('layer-picker');
            const layerNote = (sel && sel.value) ? ' (layer filter)' : '';
            setStatus('status-objects', '<strong>Props</strong>: ' + placedIds.size + ' nearby' + layerNote);
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
    // Without SLAM the camera object3D stays at its origin (0, 1.5, 0). That
    // means "place at camera" effectively drops at the GPS origin, which is
    // the right behavior here — the user is standing at the origin point.
    const p = camEl.object3D.position;
    const ll = localToLatLon(p.x, p.z);
    if (!ll) {
        showToast('cannot project to lat/lon', true);
        return;
    }

    const fd = new URLSearchParams();
    fd.append('latitude', String(ll.lat));
    fd.append('longitude', String(ll.lon));
    if (placeMode === 'signpost') {
        fd.append('type', 'signpost');
        const txt = document.getElementById('signpost-text').value.trim();
        if (txt.length > 0) fd.append('content', txt);
    } else {
        fd.append('type', 'prop');
        fd.append('fileHash', selectedPropHash());
    }
    const lp = document.getElementById('layer-picker');
    if (lp && lp.value) fd.append('layerId', lp.value);
    fetch(API_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: fd
    })
        .then(function (r) {
            if (!r.ok) {
                showToast('place failed (' + r.status + ')', true);
                return;
            }
            showToast(placeMode === 'signpost' ? 'signpost placed' : 'cube placed');
            return loadObjects();
        })
        .catch(function () {
            showToast('network error', true);
        });
}

// ---- boot ----

// Run permission requests in series so the user only sees one prompt at a
// time (browsers queue them, but the UX is clearer this way) and so a denial
// at any step gives a precise error message.
function bootAR() {
    setStatus('status-tracking', '<strong>Tracking</strong>: requesting motion…');
    return requestOrientationPermission()
        .then(function (granted) {
            if (!granted) {
                // Not fatal on Android (granted=true via the no-API path) — only
                // hits here if iOS user tapped Deny. Scene still renders, but
                // camera rotation won't follow the device.
                showToast('Motion access denied — rotation tracking off', true);
            }
            setStatus('status-tracking', '<strong>Tracking</strong>: requesting camera…');
            return startCamera();
        })
        .then(function () {
            setStatus('status-tracking', '<strong>Tracking</strong>: device orientation');
            setStatus('status-location', '<strong>GPS origin</strong>: locking…');
            return lockOriginGps();
        })
        .then(function (best) {
            originLat = best.lat;
            originLon = best.lon;
            originAcc = best.acc;
            setStatus('status-location',
                '<strong>GPS origin</strong>: ' + best.lat.toFixed(5) + ', ' + best.lon.toFixed(5) +
                ' (±' + Math.round(best.acc) + 'm)');
            const scene = document.querySelector('a-scene');
            const onReady = function () {
                hideLoading();
                loadObjects();
            };
            if (scene && scene.hasLoaded) onReady();
            else if (scene) scene.addEventListener('loaded', onReady, {once: true});
        })
        .catch(function (err) {
            const msg = (err && err.message) || String(err);
            if (msg === 'no-geo') {
                showFatal('Geolocation not supported in this browser.');
            } else if (msg === 'denied') {
                showFatal('Location access was denied. Enable it in browser settings and tap Retry.');
            } else if (msg === 'unavailable' || msg === 'no-fix') {
                showFatal('No GPS fix. Step outdoors and tap Retry.');
            } else if (msg.indexOf('weak:') === 0) {
                showFatal('GPS too weak (±' + msg.slice(5) + 'm). Move to open sky and tap Retry.');
            } else if (msg.indexOf('getUserMedia') === 0) {
                showFatal('Camera API unavailable. Try a different browser.');
            } else if (err && err.name === 'NotAllowedError') {
                showFatal('Camera access was denied. Enable it in browser settings and tap Retry.');
            } else if (err && err.name === 'NotFoundError') {
                showFatal('No camera found on this device.');
            } else {
                showFatal('Startup failed: ' + msg);
            }
        });
}

document.addEventListener('DOMContentLoaded', function () {
    loadAssetPicker();
    loadLayerPicker();

    const startBtn = document.getElementById('start-btn');
    if (startBtn) {
        startBtn.addEventListener('click', function () {
            startBtn.disabled = true;
            startBtn.textContent = 'Starting…';
            bootAR().finally(function () {
                // re-enable in case showFatal was called and the user wants to
                // retry without a full reload (though Retry button does reload).
                startBtn.disabled = false;
                startBtn.textContent = 'Start AR';
            });
        });
    }
});
