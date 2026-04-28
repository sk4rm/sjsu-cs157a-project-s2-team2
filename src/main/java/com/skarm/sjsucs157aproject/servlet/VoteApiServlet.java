package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.VirtualObjectDao;
import com.skarm.sjsucs157aproject.dao.VoteDao;
import jakarta.json.Json;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "voteApiServlet", urlPatterns = {"/api/votes"})
public class VoteApiServlet extends HttpServlet {

    private final VoteDao voteDao = new VoteDao();
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
            VoteDao.Tally t = voteDao.tallyForObject(objectId);
            var b = Json.createObjectBuilder()
                    .add("objectId", objectId)
                    .add("up", t.up())
                    .add("down", t.down());

            HttpSession session = req.getSession(false);
            if (session != null && session.getAttribute("userId") != null) {
                long uid = (Long) session.getAttribute("userId");
                Integer mine = voteDao.findVote(uid, objectId);
                if (mine != null) {
                    b.add("yours", mine);
                }
            }

            resp.getWriter().write(b.build().toString());
        } catch (SQLException e) {
            getServletContext().log("GET /api/votes failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendError(resp, HttpServletResponse.SC_UNAUTHORIZED, "not logged in");
            return;
        }
        long userId = (Long) session.getAttribute("userId");

        Long objectId = parseLongParam(req.getParameter("objectId"));
        if (objectId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing objectId");
            return;
        }

        String typeRaw = req.getParameter("type");
        if (typeRaw == null || typeRaw.isBlank()) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing vote type");
            return;
        }
        int type;
        try {
            type = Integer.parseInt(typeRaw.trim());
        } catch (NumberFormatException e) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid vote type");
            return;
        }
        if (type != 1 && type != -1) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "type must be 1 or -1");
            return;
        }

        resp.setContentType("application/json");
        try {
            if (objectDao.findById(objectId) == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            voteDao.upsert(userId, objectId, type);
            VoteDao.Tally t = voteDao.tallyForObject(objectId);
            resp.getWriter().write(Json.createObjectBuilder()
                    .add("objectId", objectId)
                    .add("up", t.up())
                    .add("down", t.down())
                    .add("yours", type)
                    .build()
                    .toString());
        } catch (SQLException e) {
            getServletContext().log("POST /api/votes failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
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
}
