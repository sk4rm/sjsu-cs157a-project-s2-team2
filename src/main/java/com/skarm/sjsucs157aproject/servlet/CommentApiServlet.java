package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.CommentDao;
import com.skarm.sjsucs157aproject.dao.VirtualObjectDao;
import com.skarm.sjsucs157aproject.model.Comment;
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

@WebServlet(name = "commentApiServlet", urlPatterns = {"/api/comments"})
public class CommentApiServlet extends HttpServlet {

    private final CommentDao commentDao = new CommentDao();
    private final VirtualObjectDao objectDao = new VirtualObjectDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long objectId = parseLongParam(req.getParameter("objectId"));
        if (objectId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing objectId");
            return;
        }

        resp.setContentType("application/json");
        try {
            if (objectDao.findById(objectId) == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            List<Comment> comments = commentDao.findByObjectId(objectId);
            JsonArrayBuilder arr = Json.createArrayBuilder();
            for (Comment c : comments) {
                arr.add(toJson(c));
            }
            resp.getWriter().write(arr.build().toString());
        } catch (SQLException e) {
            getServletContext().log("GET /api/comments failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) {
            return;
        }

        Long objectId = parseLongParam(req.getParameter("objectId"));
        if (objectId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing objectId");
            return;
        }

        String raw = req.getParameter("text");
        String text = raw == null ? "" : raw.trim();
        if (text.isEmpty()) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing comment text");
            return;
        }
        if (text.length() > 255) {
            text = text.substring(0, 255);
        }

        resp.setContentType("application/json");
        try {
            if (objectDao.findById(objectId) == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            Comment created = commentDao.create(userId, objectId, text);
            resp.setStatus(HttpServletResponse.SC_CREATED);
            resp.getWriter().write(toJson(created).build().toString());
        } catch (SQLException e) {
            getServletContext().log("POST /api/comments failed", e);
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

    private static Long parseLongParam(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
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

    private static JsonObjectBuilder toJson(Comment c) {
        JsonObjectBuilder b = Json.createObjectBuilder()
                .add("id", c.getId())
                .add("commenterId", c.getCommenterId())
                .add("objectId", c.getObjectId())
                .add("text", c.getTextContent());
        if (c.getCreatedAt() != null) {
            b.add("createdAt", c.getCreatedAt().getTime());
        }
        return b;
    }
}
