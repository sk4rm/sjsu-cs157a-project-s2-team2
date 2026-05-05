package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.FriendDao;
import com.skarm.sjsucs157aproject.dao.UserDao;
import com.skarm.sjsucs157aproject.model.User;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "friendApiServlet", urlPatterns = {"/api/friends", "/api/friends/*"})
public class FriendApiServlet extends HttpServlet {

    private final FriendDao friendDao = new FriendDao();
    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long me = requireAuth(req, resp);
        if (me == null) return;
        resp.setContentType("application/json");
        try {
            List<User> friends = friendDao.findFriendsOf(me);
            JsonArrayBuilder arr = Json.createArrayBuilder();
            for (User u : friends) {
                arr.add(toJson(u));
            }
            resp.getWriter().write(arr.build().toString());
        } catch (SQLException e) {
            getServletContext().log("GET /api/friends failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long me = requireAuth(req, resp);
        if (me == null) return;

        Long otherId = parseLong(req.getParameter("userId"));
        if (otherId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing userId");
            return;
        }
        if (otherId.equals(me)) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Cannot befriend yourself");
            return;
        }

        try {
            User other = userDao.findById(otherId);
            if (other == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "User not found");
                return;
            }
            friendDao.addFriend(me, otherId);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("POST /api/friends failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Long me = requireAuth(req, resp);
        if (me == null) return;

        Long otherId = parseIdFromPath(req);
        if (otherId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing user id in path");
            return;
        }

        try {
            // Idempotent — 204 even if no friendship existed.
            friendDao.removeFriend(me, otherId);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("DELETE /api/friends failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    private static JsonObjectBuilder toJson(User u) {
        return Json.createObjectBuilder()
                .add("userId", u.getUserId())
                .add("displayName", u.getDisplayName() == null ? "" : u.getDisplayName())
                .add("username", u.getUsername() == null ? "" : u.getUsername());
    }

    private Long requireAuth(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendError(resp, HttpServletResponse.SC_UNAUTHORIZED, "not logged in");
            return null;
        }
        return (Long) session.getAttribute("userId");
    }

    private static Long parseIdFromPath(HttpServletRequest req) {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() <= 1) {
            return null;
        }
        try {
            return Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Long parseLong(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return Long.parseLong(raw.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write(Json.createObjectBuilder().add("error", message).build().toString());
    }
}
