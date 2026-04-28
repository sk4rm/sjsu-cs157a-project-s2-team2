<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>

<head>
    <title>WARP - Camera View</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/world.css">
    <%-- Mobile dev console: load eruda only when ?debug=1 is in the URL. --%>
    <% if ("1".equals(request.getParameter("debug"))) { %>
    <script src="https://cdn.jsdelivr.net/npm/eruda"></script>
    <script>eruda.init();</script>
    <% } %>
    <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
    <script src="https://cdn.jsdelivr.net/gh/AR-js-org/AR.js@3.4.5/aframe/build/aframe-ar.js"></script>
</head>

<body data-warp-comments="<%= request.getContextPath() %>/api/comments"
      data-warp-votes="<%= request.getContextPath() %>/api/votes">

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
    <a href="<%= request.getContextPath() %>/world-xr" class="hud-btn"
       title="alternate: 8th Wall SLAM tracking (better on iPhone, needs static/xr setup)">XR mode</a>
    <button type="button" class="hud-btn" onclick="placeWorldSpaceTestCube()"
            title="dev: green cube on the ring, not glued to camera">
        test world cube
    </button>
    <div class="status">
        <div id="status-location"><strong>Location</strong>: Acquiring...</div>
        <div id="status-objects" style="margin-top: 4px; color: #aaa;">Searching for props...</div>
    </div>
</div>

<div id="loc-prompt" class="loc-prompt" role="dialog" aria-label="location permission">
    <p id="loc-prompt-text">warp uses your gps to place cubes and signposts. if you already tapped allow in settings, we
        try to pick up coords automatically — or use the buttons below.</p>
    <button type="button" class="loc-allow-btn" onclick="requestLocationPermission()">ask for location / refresh gps
    </button>
    <button type="button" class="secondary" onclick="dismissLocPrompt()">hide this bar</button>
</div>

<a-scene vr-mode-ui="enabled: false" embedded
         arjs="sourceType: webcam; debugUIEnabled: false; antialias: true; alpha: true"
         renderer="antialias: true; alpha: true">

    <a-camera gps-camera="gpsMinDistance: 0.5; positionMinAccuracy: 20; minDistance: 0.1; gpsTimeInterval: 500"
              gps-smoother="durationMs: 300"
              rotation-reader>
        <a-cursor color="#d37f8f" fuse="false" raycaster="objects: .clickable"></a-cursor>
    </a-camera>
</a-scene>

<div class="hud-bottom">
    <div class="place-bar">
        <div class="place-modes">
            <button type="button" class="mode-btn on" id="mode-cube" onclick="setPlaceMode('cube')">cube</button>
            <button type="button" class="mode-btn" id="mode-sign" onclick="setPlaceMode('signpost')">signpost</button>
        </div>
        <div class="place-modes">
            <button type="button" class="mode-btn on" id="space-gps" onclick="setPlaceSpace('gps')">GPS</button>
            <button type="button" class="mode-btn" id="space-world" onclick="setPlaceSpace('world')">world</button>
        </div>
        <input type="text" class="signpost-input" id="signpost-text" maxlength="250"
               placeholder="signpost message (only for signpost)" disabled>
        <select id="asset-picker" class="signpost-input" title="3D model for cube placements">
            <option value="">default cube</option>
        </select>
        <div class="place-hint" id="place-hint">gps updates from camera, or we ask browser once on place</div>
    </div>
    <div class="action-button" onclick="onPlaceButton()" title="place here (GPS or world)">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
    </div>
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
            <button type="button" class="delete-btn" style="flex:1; margin:0;" onclick="onDeleteConfirmed()">Yes, delete</button>
            <button type="button" class="delete-btn" style="flex:1; margin:0; background:#444;" onclick="onDeleteCancelled()">Cancel</button>
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
<script src="<%= request.getContextPath() %>/js/inspector-social.js?v=ar2"></script>
<script src="<%= request.getContextPath() %>/js/world.js"></script>

</body>

</html>
