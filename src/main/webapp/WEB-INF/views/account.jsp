<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.skarm.sjsucs157aproject.model.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Account - WARP</title>
    <style>
        :root {
            --bg-soft: #e9dddd;
            --bg-soft-alt: #e4cbdc;
            --accent-rose: #d37f8f;
            --accent-rose-soft: #e6a3af;
            --accent-gold: #e0ae82;
            --text-main: #3f2b32;
            --text-muted: #7c5e66;
            --border-soft: #e4cbdc;
        }

        body {
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            margin: 0;
            padding: 0;
            background: radial-gradient(circle at top, var(--bg-soft) 0, var(--bg-soft-alt) 55%, var(--bg-soft) 100%);
            color: var(--text-main);
        }

        header {
            padding: 16px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(0, 0, 0, 0.04);
            background: rgba(255, 255, 255, 0.95);
        }

        .logo {
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            font-size: 0.85rem;
            color: var(--text-main);
        }

        .logo span {
            color: var(--accent-rose);
        }

        .nav-links a {
            margin-left: 16px;
            font-size: 0.85rem;
            color: var(--text-main);
            text-decoration: none;
            opacity: 0.8;
        }

        .nav-links a:hover {
            opacity: 1;
        }

        .container {
            max-width: 640px;
            margin: 32px auto;
            padding: 24px;
            background: #ffffff;
            border-radius: 20px;
            box-shadow: 0 18px 40px rgba(0, 0, 0, 0.08);
            border: 1px solid var(--border-soft);
        }

        h1 {
            margin-top: 0;
            font-size: 1.6rem;
            color: var(--accent-rose);
        }

        label {
            display: block;
            margin-top: 12px;
            font-size: 0.9rem;
        }

        input {
            width: 100%;
            padding: 9px 11px;
            margin-top: 4px;
            border-radius: 999px;
            border: 1px solid var(--border-soft);
            background: #fdfbfb;
            color: var(--text-main);
        }

        .readonly {
            background: #f5edef;
            opacity: 0.8;
        }

        button {
            margin-top: 18px;
            padding: 9px 18px;
            border: none;
            border-radius: 999px;
            background: linear-gradient(135deg, var(--accent-rose), var(--accent-rose-soft));
            color: #ffffff;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 8px 18px rgba(196, 120, 136, 0.45);
        }

        button:hover {
            box-shadow: 0 10px 22px rgba(196, 120, 136, 0.6);
        }

        .error {
            margin-top: 12px;
            padding: 10px;
            border-radius: 12px;
            background: rgba(211, 127, 143, 0.08);
            color: #a1354b;
            font-size: 0.9rem;
        }

        .info {
            margin-top: 12px;
            padding: 10px;
            border-radius: 12px;
            background: rgba(224, 174, 130, 0.08);
            color: #8a5d2e;
            font-size: 0.85rem;
        }

        .danger-zone {
            margin-top: 32px;
            padding-top: 16px;
            border-top: 1px dashed var(--border-soft);
            font-size: 0.9rem;
        }

        form.inline {
            display: inline;
            margin: 0;
        }

        .signout-small {
            background: transparent;
            border-radius: 999px;
            border: 1px solid #1f2937;
            padding: 6px 14px;
            font-size: 0.8rem;
        }

        .danger-zone h2 {
            margin: 0 0 8px;
            font-size: 1rem;
            color: #a1354b;
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }

        .danger-zone p {
            color: var(--text-muted);
            font-size: 0.85rem;
            margin: 4px 0 12px;
        }

        .danger-zone button {
            background: linear-gradient(135deg, #a1354b, #d37f8f);
            box-shadow: 0 8px 18px rgba(161, 53, 75, 0.4);
        }

        .danger-zone button:hover {
            box-shadow: 0 10px 22px rgba(161, 53, 75, 0.55);
        }

        .asset-zone {
            margin-top: 32px;
            padding-top: 16px;
            border-top: 1px dashed var(--border-soft);
        }

        .asset-zone h2 {
            margin: 0 0 8px;
            font-size: 1rem;
            color: var(--accent-rose);
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }

        .asset-zone p {
            color: var(--text-muted);
            font-size: 0.85rem;
            margin: 4px 0 12px;
        }

        .asset-list {
            list-style: none;
            padding: 0;
            margin: 12px 0 0;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .asset-list li {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 12px;
            background: #fdfbfb;
            border: 1px solid var(--border-soft);
            border-radius: 12px;
            font-size: 0.85rem;
        }

        .asset-list .meta {
            color: var(--text-muted);
            font-size: 0.75rem;
            margin-left: 8px;
        }

        .asset-list .del {
            background: transparent;
            color: #a1354b;
            border: 1px solid rgba(161, 53, 75, 0.4);
            border-radius: 999px;
            font-size: 0.75rem;
            padding: 4px 10px;
            margin: 0;
            box-shadow: none;
            cursor: pointer;
        }

        .asset-list .empty {
            color: var(--text-muted);
            font-size: 0.85rem;
            font-style: italic;
        }

        .upload-status {
            margin-top: 8px;
            font-size: 0.85rem;
            min-height: 1.1em;
        }

        .upload-status.ok { color: #2f7a3a; }
        .upload-status.err { color: #a1354b; }
    </style>
</head>
<body>
<header>
    <div class="logo">W<span>ARP</span> Studio</div>
    <div class="nav-links">
        <a href="<%= request.getContextPath() %>/">Home</a>
        <form class="inline" method="post" action="<%= request.getContextPath() %>/logout">
            <button type="submit" class="signout-small">Sign out</button>
        </form>
    </div>
</header>
<%
    User user = (User) request.getAttribute("user");
%>
<div class="container">
    <h1>Account</h1>
    <%
        String updated = request.getParameter("updated");
        if ("1".equals(updated)) {
    %>
    <div class="info">Profile updated.</div>
    <% } %>
    <%
        String error = (String) request.getAttribute("error");
        if (error != null) {
    %>
    <div class="error"><%= error %>
    </div>
    <% } %>
    <form method="post" action="<%= request.getContextPath() %>/account">
        <label for="username">Username</label>
        <input class="readonly" type="text" id="username" name="username"
               value="<%= user != null ? user.getUsername() : "" %>" readonly>

        <label for="displayName">Display name</label>
        <input type="text" id="displayName" name="displayName" maxlength="64"
               value="<%= user != null ? user.getDisplayName() : "" %>" required>

        <label for="heightMeter">Height (meters)</label>
        <input type="number" step="0.01" min="0.5" max="2.5" id="heightMeter" name="heightMeter"
               value="<%= user != null ? user.getHeightMeter() : 1.75 %>" required>

        <button type="submit">Save changes</button>
    </form>

    <div class="asset-zone">
        <h2>3D Model Library</h2>
        <p>Upload a glTF/GLB model (max 8 MB). Uploaded models become available as props in any world view.</p>

        <form id="asset-upload-form" enctype="multipart/form-data">
            <label for="assetDisplayName">Display name (optional)</label>
            <input type="text" id="assetDisplayName" name="displayName" maxlength="100"
                   placeholder="e.g. red bench">

            <label for="assetFile">Model file (.glb or .gltf)</label>
            <input type="file" id="assetFile" name="file" accept=".glb,.gltf" required>

            <button type="submit">Upload model</button>
            <div id="upload-status" class="upload-status"></div>
        </form>

        <ul id="asset-list" class="asset-list">
            <li class="empty">Loading library…</li>
        </ul>
    </div>

    <script>
        (function () {
            const ctx = '<%= request.getContextPath() %>';
            const myId = <%= user != null ? user.getUserId() : "null" %>;
            const listEl = document.getElementById('asset-list');
            const form = document.getElementById('asset-upload-form');
            const statusEl = document.getElementById('upload-status');

            function setStatus(msg, kind) {
                statusEl.textContent = msg || '';
                statusEl.className = 'upload-status' + (kind ? ' ' + kind : '');
            }

            function fmtBytes(n) {
                if (n < 1024) return n + ' B';
                if (n < 1024 * 1024) return (n / 1024).toFixed(1) + ' KB';
                return (n / 1024 / 1024).toFixed(2) + ' MB';
            }

            function refreshList() {
                fetch(ctx + '/api/assets', { credentials: 'same-origin' })
                    .then(function (r) { return r.ok ? r.json() : []; })
                    .then(function (assets) {
                        if (!assets.length) {
                            listEl.innerHTML = '<li class="empty">No models uploaded yet.</li>';
                            return;
                        }
                        listEl.innerHTML = '';
                        assets.forEach(function (a) {
                            const li = document.createElement('li');
                            const left = document.createElement('span');
                            left.textContent = a.displayName;
                            const meta = document.createElement('span');
                            meta.className = 'meta';
                            meta.textContent = '#' + a.id + ' · ' + fmtBytes(a.byteSize);
                            left.appendChild(meta);
                            li.appendChild(left);
                            if (a.uploaderId === myId) {
                                const btn = document.createElement('button');
                                btn.type = 'button';
                                btn.className = 'del';
                                btn.textContent = 'Delete';
                                btn.onclick = function () { onDelete(a.id, a.displayName); };
                                li.appendChild(btn);
                            }
                            listEl.appendChild(li);
                        });
                    })
                    .catch(function () {
                        listEl.innerHTML = '<li class="empty">Could not load library.</li>';
                    });
            }

            function onDelete(id, name) {
                if (!confirm('Delete "' + name + '"? Existing props using this model will fall back to a default cube.')) return;
                fetch(ctx + '/api/assets/' + id, {
                    method: 'DELETE',
                    credentials: 'same-origin'
                }).then(function (r) {
                    if (r.ok || r.status === 204) {
                        setStatus('Deleted "' + name + '"', 'ok');
                        refreshList();
                    } else {
                        setStatus('Delete failed (' + r.status + ')', 'err');
                    }
                }).catch(function () { setStatus('Network error on delete', 'err'); });
            }

            form.addEventListener('submit', function (e) {
                e.preventDefault();
                const file = document.getElementById('assetFile').files[0];
                if (!file) { setStatus('Choose a file first', 'err'); return; }
                if (file.size > 8 * 1024 * 1024) { setStatus('File too large (max 8 MB)', 'err'); return; }

                const fd = new FormData();
                fd.append('file', file);
                const dn = document.getElementById('assetDisplayName').value.trim();
                if (dn) fd.append('displayName', dn);

                setStatus('Uploading…');
                fetch(ctx + '/api/assets', {
                    method: 'POST',
                    credentials: 'same-origin',
                    body: fd
                }).then(function (r) {
                    if (!r.ok) {
                        return r.json().then(function (j) {
                            setStatus(j.error || ('Upload failed (' + r.status + ')'), 'err');
                        }).catch(function () { setStatus('Upload failed (' + r.status + ')', 'err'); });
                    }
                    return r.json().then(function (a) {
                        setStatus('Uploaded "' + a.displayName + '"', 'ok');
                        form.reset();
                        refreshList();
                    });
                }).catch(function () { setStatus('Network error', 'err'); });
            });

            refreshList();
        })();
    </script>

    <div class="danger-zone">
        <h2>Danger zone</h2>
        <p>Permanently delete your account and every virtual object, vote, comment, and friendship attached to it. This
            cannot be undone.</p>
        <%
            String deleteError = (String) request.getAttribute("deleteError");
            if (deleteError != null) {
        %>
        <div class="error"><%= deleteError %>
        </div>
        <% } %>
        <form method="post" action="<%= request.getContextPath() %>/account"
              onsubmit="return confirm('Delete your account permanently? This cannot be undone.');">
            <input type="hidden" name="action" value="delete">

            <label for="deletePassword">Confirm password</label>
            <input type="password" id="deletePassword" name="deletePassword" autocomplete="current-password" required>

            <label for="deleteConfirmation">Type DELETE to confirm</label>
            <input type="text" id="deleteConfirmation" name="deleteConfirmation" pattern="DELETE"
                   autocomplete="off" required>

            <button type="submit">Delete my account</button>
        </form>
    </div>
</div>
</body>
</html>

