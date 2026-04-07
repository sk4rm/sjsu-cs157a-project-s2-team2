<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>WARP - Camera View</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
    <script src="https://raw.githack.com/AR-js-org/AR.js/master/aframe/build/aframe-ar.js"></script>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            background-color: transparent !important;
            overflow: hidden;
            font-family: system-ui, -apple-system, sans-serif;
            color: white;
        }

        .hud-top {
            position: absolute;
            top: 20px;
            left: 20px;
            right: 20px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
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
        
        .loading-overlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            background: #000;
            z-index: 100;
            transition: opacity 0.5s;
        }
    </style>
</head>
<body>

    <div id="loading" class="loading-overlay">
        <div id="loading-text" style="margin-bottom: 20px; font-size: 1.2rem;">Initializing WARP Engine...</div>
        <div id="loading-sub" style="font-size: 0.8rem; color: #aaa;">Requesting Camera and GPS permissions</div>
        <button id="retry-btn" style="display:none; margin-top:20px; padding:10px 20px; border-radius:999px; border:1px solid white; background:none; color:white;" onclick="location.reload()">Retry</button>
        <button id="skip-btn" style="margin-top:10px; padding:8px 16px; font-size:0.8rem; border-radius:999px; border:1px solid rgba(255,255,255,0.3); background:rgba(255,255,255,0.1); color:rgba(255,255,255,0.7);" onclick="skipGps()">Skip GPS (Dev Mode)</button>
    </div>

    <div class="hud-top">
        <a href="<%= request.getContextPath() %>/" class="hud-btn">← Exit World</a>
        <div class="status">
            <div id="status-location"><strong>Location</strong>: Acquiring...</div>
            <div id="status-objects" style="margin-top: 4px; color: #aaa;">Searching for props...</div>
        </div>
    </div>

    <a-scene
        vr-mode-ui="enabled: false"
        embedded
        arjs="sourceType: webcam; videoTexture: true; debugUIEnabled: false; antialias: true; alpha: true"
        renderer="antialias: true; alpha: true">
        
        <a-camera gps-camera rotation-reader></a-camera>
    </a-scene>

    <div class="hud-bottom">
        <div style="font-size: 0.8rem; text-shadow: 0 2px 4px rgba(0,0,0,0.5);">Tap to drop a prop at your spot</div>
        <div class="action-button" onclick="dropObject()" title="Drop Object">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
        </div>
    </div>

    <script>
        const API_URL = '<%= request.getContextPath() %>/api/objects';
        let currentPosition = null;

        // Initialize location tracking
        window.onload = () => {
            console.log("WARP: Initializing world...");
            const loadingSub = document.getElementById('loading-sub');
            
            if (!navigator.geolocation) {
                showError("Geolocation is not supported by your browser.");
                return;
            }

            loadingSub.innerText = "Waiting for GPS lock...";

             navigator.geolocation.watchPosition(
                (pos) => {
                    if (!currentPosition) {
                        console.log("WARP: First GPS Lock acquired", pos.coords);
                        hideLoading();
                    }
                    currentPosition = pos.coords;
                    document.getElementById('status-location').innerHTML = 
                        `<strong>GPS</strong>: ${pos.coords.latitude.toFixed(5)}, ${pos.coords.longitude.toFixed(5)}`;
                },
                (err) => {
                    console.error("WARP: Location error:", err);
                    if (!currentPosition) {
                        let msg = "Location Error: ";
                        switch(err.code) {
                            case err.PERMISSION_DENIED: msg += "Permission denied. Please enable Location Services."; break;
                            case err.POSITION_UNAVAILABLE: msg += "Position unavailable. Are you indoors?"; break;
                            case err.TIMEOUT: msg += "Location request timed out. Try 'Skip GPS' if indoors."; break;
                            default: msg += err.message;
                        }
                        showError(msg);
                    }
                },
                { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
            );

            loadObjects();
        };

        function skipGps() {
            console.warn("WARP: GPS skipped by user. Using default coordinates.");
            currentPosition = { latitude: 37.3352, longitude: -121.8811 }; // SJSU Default
            document.getElementById('status-location').innerHTML = "<strong>GPS</strong>: Skipped (Dev Mode)";
            hideLoading();
        }

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
                setTimeout(() => { if (loading) loading.remove(); }, 500);
            }
        }

        async function loadObjects() {
            try {
                const response = await fetch(API_URL);
                const objects = await response.json();
                const scene = document.querySelector('a-scene');
                
                document.getElementById('status-objects').innerText = `Found ${objects.length} nearby props`;

                objects.forEach(obj => {
                    // Avoid duplicates if we reload
                    if (document.getElementById('obj-' + obj.id)) return;

                    let entity;
                    if (obj.type === 'signpost') {
                        // Signpost rendering: a floating text plate
                        entity = document.createElement('a-entity');
                        entity.setAttribute('id', 'obj-' + obj.id);
                        entity.setAttribute('gps-entity-place', `latitude: ${obj.latitude}; longitude: ${obj.longitude}`);
                        
                        const text = document.createElement('a-text');
                        text.setAttribute('value', obj.content || 'Empty Signpost');
                        text.setAttribute('align', 'center');
                        text.setAttribute('color', '#ffffff');
                        text.setAttribute('scale', '4 4 4');
                        text.setAttribute('look-at', '[gps-camera]');
                        text.setAttribute('geometry', 'primitive: plane; width: auto; height: 0.3');
                        text.setAttribute('material', 'color: #3f2b32; opacity: 0.8');
                        entity.appendChild(text);
                    } else {
                        // Prop rendering: a 3D box
                        entity = document.createElement('a-box');
                        entity.setAttribute('id', 'obj-' + obj.id);
                        entity.setAttribute('gps-entity-place', `latitude: ${obj.latitude}; longitude: ${obj.longitude}`);
                        entity.setAttribute('material', 'color: #d37f8f; opacity: 0.8');
                        
                        const textLabel = document.createElement('a-text');
                        textLabel.setAttribute('value', obj.fileHash || 'PROP');
                        textLabel.setAttribute('align', 'center');
                        textLabel.setAttribute('position', '0 1.2 0');
                        textLabel.setAttribute('scale', '2 2 2');
                        textLabel.setAttribute('look-at', '[gps-camera]');
                        entity.appendChild(textLabel);
                    }

                    entity.setAttribute('scale', `${obj.scale} ${obj.scale} ${obj.scale}`);
                    // Database uses quaternion "x,y,z,w", A-Frame standard rotation is Euler. 
                    // For now, we'll maintain the orientation logic as a placeholder.
                    
                    scene.appendChild(entity);
                });
            } catch (err) {
                console.error("Failed to load objects:", err);
            }
        }

        async function dropObject() {
            if (!currentPosition) {
                alert("Acquiring GPS location... please wait.");
                return;
            }

            const formData = new URLSearchParams();
            formData.append('latitude', currentPosition.latitude);
            formData.append('longitude', currentPosition.longitude);
            formData.append('type', 'box');

            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: formData
                });

                if (response.ok) {
                    const result = await response.json();
                    console.log("Object dropped!", result);
                    loadObjects(); // Refresh the scene
                } else {
                    const err = await response.json();
                    alert("Failed to drop object: " + (err.error || response.statusText));
                }
            } catch (err) {
                console.error("Drop error:", err);
                alert("Network error while dropping object.");
            }
        }
    </script>

</body>
</html>
