const API_URL = window.WARP.apiUrl;
const sessionUserId = window.WARP.userId;
let selectedObjectId = null;

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

    document.getElementById('inspector').classList.add('show');
}

function closeInspector() {
    document.getElementById('inspector').classList.remove('show');
    selectedObjectId = null;
}

function onDeleteClicked() {
    if (!selectedObjectId) return;
    if (!confirm('Are you sure you want to delete this object?')) return;

    const id = selectedObjectId;
    fetch(API_URL + '/' + id, {
        method: 'DELETE', credentials: 'same-origin'
    }).then(function (resp) {
        if (resp.ok) {
            showToast('Object deleted');
            const el = document.getElementById('obj-' + id);
            if (el) el.remove();
            closeInspector();
        } else {
            return resp.text().then(function (msg) {
                showToast('Delete failed: ' + msg.slice(0, 50), true);
            });
        }
    }).catch(function (err) {
        showToast('Network error on delete', true);
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

// (Existing helper functions remain until factories)

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
                try {
                    navigator.geolocation.clearWatch(watchId);
                } catch (e) {
                }
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
                        try {
                            navigator.geolocation.clearWatch(watchId);
                        } catch (e) {
                        }
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

// ---- entity factories (mirror world.jsp's visual style, minus gps-entity-place) ----

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
    const box = document.createElement('a-box');
    box.setAttribute('width', '0.5');
    box.setAttribute('height', '0.5');
    box.setAttribute('depth', '0.5');
    box.setAttribute('material', 'color: #d37f8f; metalness: 0.1; roughness: 0.7');
    inner.appendChild(box);
    root.appendChild(inner);
    setupObjectClick(box, obj);
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
        fd.append('fileHash', 'demo_cube');
    }
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

// ---- engine boot ----

function reportFatal(msg) {
    const sub = document.getElementById('loading-sub');
    const retry = document.getElementById('retry-btn');
    if (sub) {
        sub.innerText = msg;
        sub.style.color = '#ff8b8b';
    }
    if (retry) retry.style.display = 'block';
}

// Wait for XR8 (engine) to attach to window. If the binary isn't installed,
// give up after a few seconds with a clear error pointing at the README.
function whenXr8Ready(cb, deadlineMs) {
    const start = Date.now();
    (function tick() {
        if (window.XR8) {
            cb();
            return;
        }
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
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
        DeviceOrientationEvent.requestPermission().catch(function () {
        });
    }

    setStatus('status-tracking', '<strong>Tracking</strong>: locking GPS origin…');
    lockOriginGps()
        .then(function (best) {
            originLat = best.lat;
            originLon = best.lon;
            originAcc = best.acc;
            setStatus('status-location', '<strong>GPS origin</strong>: ' + best.lat.toFixed(5) + ', ' + best.lon.toFixed(5) + ' (±' + Math.round(best.acc) + 'm)');
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

                if (scene && scene.hasLoaded) onReady(); else if (scene) scene.addEventListener('loaded', onReady, {once: true});
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
