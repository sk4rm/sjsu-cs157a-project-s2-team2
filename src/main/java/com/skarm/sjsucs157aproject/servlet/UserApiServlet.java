package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.UserDao;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Read-only user lookup, currently used by the friends UI to find people to
 * befriend. Each result includes whether the requester is already friends
 * with that user, so the UI can render Add vs Remove without a second call.
 */
@WebServlet(name = "userApiServlet", urlPatterns = {"/api/users"})
public class UserApiServlet extends HttpServlet {

    private static final int MAX_RESULTS = 20;

    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long me = requireAuth(req, resp);
        if (me == null) return;

        String raw = req.getParameter("q");
        String query = raw == null ? "" : raw.trim();
        resp.setContentType("application/json");

        if (query.isEmpty()) {
            // Empty query → empty array. Keeps the UI simple (no "type
            // something" affordance needed for the API).
            resp.getWriter().write("[]");
            return;
        }

        try {
            List<UserDao.UserSearchResult> results = userDao.searchByQuery(query, me, MAX_RESULTS);
            JsonArrayBuilder arr = Json.createArrayBuilder();
            for (UserDao.UserSearchResult r : results) {
                arr.add(Json.createObjectBuilder()
                        .add("userId", r.userId)
                        .add("displayName", r.displayName == null ? "" : r.displayName)
                        .add("username", r.username == null ? "" : r.username)
                        .add("isFriend", r.isFriend));
            }
            resp.getWriter().write(arr.build().toString());
        } catch (SQLException e) {
            getServletContext().log("GET /api/users failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    private Long requireAuth(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendError(resp, HttpServletResponse.SC_UNAUTHORIZED, "not logged in");
            return null;
        }
        return (Long) session.getAttribute("userId");
    }

    private static void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write(Json.createObjectBuilder().add("error", message).build().toString());
    }
}
