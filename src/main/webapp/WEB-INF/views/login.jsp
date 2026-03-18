<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Login - WARP</title>
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

        .container {
            max-width: 520px;
            margin: 80px auto;
            padding: 32px 32px 30px;
            background: #ffffff;
            border-radius: 24px;
            box-shadow: 0 22px 50px rgba(0,0,0,0.10);
            border: 1px solid var(--border-soft);
        }

        h1 { margin-top: 0; font-size: 1.9rem; color: var(--accent-rose); text-align: center; }

        label { display: block; margin-top: 14px; font-size: 0.95rem; }

        input {
            width: 100%;
            padding: 11px 13px;
            margin-top: 5px;
            border-radius: 999px;
            border: 1px solid var(--border-soft);
            background: #fdfbfb;
            color: var(--text-main);
            font-size: 0.95rem;
        }

        button {
            margin-top: 22px;
            width: 100%;
            padding: 12px 20px;
            border: none;
            border-radius: 999px;
            background: linear-gradient(135deg, var(--accent-rose), var(--accent-rose-soft));
            color: #ffffff;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 10px 22px rgba(196,120,136,0.50);
            font-size: 0.98rem;
        }

        button:hover { box-shadow: 0 10px 22px rgba(196,120,136,0.6); }

        .error {
            margin-top: 12px;
            padding: 10px;
            border-radius: 12px;
            background: rgba(211,127,143,0.08);
            color: #a1354b;
            font-size: 0.9rem;
        }

        .info {
            margin-top: 12px;
            padding: 10px;
            border-radius: 12px;
            background: rgba(224,174,130,0.08);
            color: #8a5d2e;
            font-size: 0.85rem;
        }

        .hint { margin-top: 10px; font-size: 0.8rem; color: var(--text-muted); }

        a { color: var(--accent-rose); text-decoration: none; }
    </style>
</head>
<body>
<div class="container">
    <h1>Welcome back to WARP</h1>
    <%
        String registered = request.getParameter("registered");
        if ("1".equals(registered)) {
    %>
    <div class="info">Registration successful. You can log in now.</div>
    <% } %>
    <%
        String error = (String) request.getAttribute("error");
        if (error != null) {
    %>
    <div class="error"><%= error %></div>
    <% } %>
    <form method="post" action="<%= request.getContextPath() %>/login">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" required>

        <label for="password">Password</label>
        <input type="password" id="password" name="password" required>

        <button type="submit">Log in</button>
    </form>
    <p class="hint">Need an account? <a href="<%= request.getContextPath() %>/#join">Sign up on the landing page</a>.</p>
</div>
</body>
</html>

