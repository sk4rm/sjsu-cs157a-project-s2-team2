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

    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/world-xr.css">

    <%-- Mobile dev console: load eruda only when ?debug=1 is in the URL. --%>
    <% if ("1".equals(request.getParameter("debug"))) { %>
    <script src="https://cdn.jsdelivr.net/npm/eruda"></script>
    <script>eruda.init();</script>
    <% } %>

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
</head>

<body data-warp-comments="<%= request.getContextPath() %>/api/comments"
      data-warp-votes="<%= request.getContextPath() %>/api/votes">

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
        <div class="lb-sub">iOS Safari drops the camera stream when this view rotates. Hold your phone upright to keep
            tracking alive.
        </div>
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
        <select id="asset-picker" class="signpost-input" title="3D model for cube placements">
            <option value="">default cube</option>
        </select>
        <div class="place-hint" id="place-hint">drops where you're standing — XR tracking, no GPS jitter</div>
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
<script src="<%= request.getContextPath() %>/js/inspector-social.js?v=xr2"></script>
<script src="<%= request.getContextPath() %>/js/world-xr.js"></script>
</body>
</html>
