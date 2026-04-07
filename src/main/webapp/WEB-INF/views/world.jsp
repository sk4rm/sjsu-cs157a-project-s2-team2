<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>WARP - Camera View</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            background-color: #000; /* Will be transparent in AR */
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
            max-width: 200px;
        }

        .hud-bottom {
            position: absolute;
            bottom: 30px;
            left: 0;
            right: 0;
            display: flex;
            justify-content: center;
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
        }
        
        #ar-canvas-placeholder {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            color: rgba(255,255,255,0.5);
            z-index: 1;
        }
    </style>
</head>
<body>

    <div class="hud-top">
        <a href="<%= request.getContextPath() %>/" class="hud-btn">← Leave World</a>
        <div class="status">
            <div><strong>Location</strong>: Acquiring...</div>
            <div style="margin-top: 4px; color: #aaa;">Looking for nearby objects</div>
        </div>
    </div>

    <!-- The actual WebXR / AR.js canvas will inject here -->
    <div id="ar-canvas-placeholder">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-bottom: 20px;">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"></path>
            <circle cx="12" cy="13" r="4"></circle>
        </svg>
        <span>Loading Camera Environment...</span>
        <span style="font-size: 0.8rem; margin-top: 10px;">(AR Engine not yet implemented)</span>
    </div>

    <div class="hud-bottom">
        <div class="action-button" title="Drop Object"></div>
    </div>

</body>
</html>
