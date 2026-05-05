<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<%--
    world-xr.jsp — alternate AR view that pairs a raw <video> camera background
    with A-Frame's look-controls (DeviceOrientation under the hood). Reads the
    same /api/objects endpoint as world.jsp, but skips AR.js entirely.

    Trade-off vs. AR.js: GPS is consulted *once* at session start to anchor a
    local origin, so the scene doesn't swim with every GPS fix. There is no
    SLAM/VIO — positional tracking is not possible on iOS Safari without a
    commercial WebAR license — so props stay anchored to lat/lon but the
    camera does not follow you as you walk. Rotate to look around.
--%>
<html>

<head>
    <title>WARP — XR</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">

    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/world-xr.css?v=xr4">

    <%-- Mobile dev console: load eruda only when ?debug=1 is in the URL. --%>
    <% if ("1".equals(request.getParameter("debug"))) { %>
    <script src="https://cdn.jsdelivr.net/npm/eruda"></script>
    <script>eruda.init();</script>
    <% } %>

    <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
</head>

<body data-warp-comments="<%= request.getContextPath() %>/api/comments"
      data-warp-votes="<%= request.getContextPath() %>/api/votes">

<%-- Camera background. JS attaches a getUserMedia stream to .srcObject after
     the user taps Start (iOS Safari needs the gesture for sensor permission). --%>
<video id="camera-feed" autoplay playsinline muted></video>

<div id="loading" class="loading-overlay">
    <div id="loading-title" style="margin-bottom: 14px; font-size: 1.2rem;">WARP — XR</div>
    <div id="loading-sub" style="font-size: 0.85rem; color: #aaa; max-width: 280px; text-align: center; line-height: 1.4;">
        Tap below to grant camera, motion, and GPS permissions. iOS won't ask without a tap.
    </div>
    <button id="start-btn" type="button" class="primary-cta">Start AR</button>
    <button id="retry-btn" type="button" class="secondary-cta" style="display:none;" onclick="location.reload()">Retry</button>
</div>

<div id="toast" class="toast"></div>

<div class="hud-top">
    <a href="<%= request.getContextPath() %>/" class="hud-btn">← Exit</a>
    <a href="<%= request.getContextPath() %>/world" class="hud-btn" title="GPS-anchored AR.js view (jitterier, but follows you as you walk)">AR.js mode</a>
    <div class="status">
        <div id="status-tracking"><strong>Tracking</strong>: idle</div>
        <div id="status-location" style="margin-top: 4px; color: #aaa;">GPS: pending</div>
        <div id="status-objects" style="margin-top: 4px; color: #aaa;">Searching for props…</div>
    </div>
</div>

<a-scene
        renderer="colorManagement: true; antialias: true; alpha: true"
        vr-mode-ui="enabled: false"
        embedded>
    <%--
      look-controls drives camera rotation from DeviceOrientation events.
      magicWindowTrackingEnabled keeps it active outside VR mode. touch/mouse
      drag is disabled so HUD taps don't accidentally rotate the view.
    --%>
    <a-camera id="xr-camera"
              look-controls="magicWindowTrackingEnabled: true; touchEnabled: false; mouseEnabled: false"
              wasd-controls="enabled: false"
              position="0 1.5 0">
        <a-cursor color="#d37f8f" fuse="false" raycaster="objects: .clickable"></a-cursor>
    </a-camera>
    <a-light type="ambient" intensity="0.7"></a-light>
    <a-light type="directional" intensity="0.6" position="2 4 1"></a-light>
</a-scene>

<div class="hud-bottom">
    <div class="place-bar">
        <div class="place-modes">
            <button type="button" class="mode-btn on" id="mode-cube" onclick="setPlaceMode('cube')">cube</button>
            <button type="button" class="mode-btn" id="mode-sign" onclick="setPlaceMode('signpost')">signpost</button>
        </div>
        <label for="signpost-text"></label>
        <input id="signpost-text" class="signpost-input" type="text" maxlength="80"
               placeholder="signpost message (signpost mode only)" disabled>
        <select id="layer-picker" class="signpost-input" title="Filter view by layer; also tags new placements" aria-label="Layer filter">
            <option value="">All layers</option>
        </select>
        <select id="asset-picker" class="signpost-input" title="Shape or uploaded model for cube placements">
            <optgroup label="Standard props">
                <option value="preset:cube" selected>Cube</option>
                <option value="preset:bread">Bread</option>
                <option value="preset:stars">Stars</option>
            </optgroup>
            <optgroup label="Your uploads" id="asset-picker-uploads"></optgroup>
        </select>
        <div class="place-hint" id="place-hint">drops at your GPS origin — rotate to look around</div>
    </div>
    <button class="action-button" onclick="placeAtCamera()" aria-label="place">
        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#333" stroke-width="2.4"
             stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
    </button>
</div>

<div id="inspector" class="inspector">
    <div class="inspector-header">
        <span id="inspector-title" class="inspector-title">Object Details</span>
        <button type="button" class="inspector-close" onclick="closeInspector()">×</button>
    </div>
    <div id="inspector-body" class="inspector-body">
        Loading...
    </div>
    <button type="button" id="inspector-delete" class="delete-btn" style="display:none;" onclick="onDeleteClicked()">
        Delete Object
    </button>
    <div id="inspector-confirm" style="display:none; flex-direction:column; gap:6px;">
        <div style="font-size:0.85rem; color:#ff8b8b; text-align:center;">Confirm delete?</div>
        <div style="display:flex; gap:8px;">
            <button type="button" class="delete-btn" style="flex:1; margin:0;" onclick="onDeleteConfirmed()">Yes,
                delete
            </button>
            <button type="button" class="delete-btn" style="flex:1; margin:0; background:#444;"
                    onclick="onDeleteCancelled()">Cancel
            </button>
        </div>
    </div>
    <div id="inspector-social" class="inspector-social"></div>
</div>

<script>
    window.WARP = {
        apiUrl: '<%= request.getContextPath() %>/api/objects',
        assetsUrl: '<%= request.getContextPath() %>/api/assets',
        layersUrl: '<%= request.getContextPath() %>/api/layers',
        commentsUrl: '<%= request.getContextPath() %>/api/comments',
        votesUrl: '<%= request.getContextPath() %>/api/votes',
        userId: <%= (Long) session.getAttribute("userId") %>
    };
    (function () {
        var b = document.body;
        if (!b || !window.WARP) return;
        var c = b.getAttribute('data-warp-comments');
        var v = b.getAttribute('data-warp-votes');
        if (c) window.WARP.commentsUrl = c;
        if (v) window.WARP.votesUrl = v;
    })();
</script>
<script src="<%= request.getContextPath() %>/js/inspector-social.js?v=xr4"></script>
<script src="<%= request.getContextPath() %>/js/world-xr.js?v=xr4"></script>
</body>
</html>
