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

