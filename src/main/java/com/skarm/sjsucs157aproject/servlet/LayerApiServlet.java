package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.LayerDao;
import com.skarm.sjsucs157aproject.model.Layer;
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

@WebServlet(name = "layerApiServlet", urlPatterns = {"/api/layers", "/api/layers/*"})
public class LayerApiServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            doPatch(req, resp);
            return;
        }
        super.service(req, resp);
    }


    private final LayerDao layerDao = new LayerDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!isAuthenticated(req, resp)) {
            return;
        }

        resp.setContentType("application/json");
        try {
            List<Layer> layers = layerDao.findAll();
            JsonArrayBuilder arrayBuilder = Json.createArrayBuilder();
            for (Layer layer : layers) {
                arrayBuilder.add(Json.createObjectBuilder()
                        .add("layerId", layer.getLayerId())
                        .add("name", layer.getName()));
            }
            resp.getWriter().write(arrayBuilder.build().toString());
        } catch (SQLException e) {
            getServletContext().log("GET /api/layers failed", e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write(Json.createObjectBuilder()
                    .add("error", "Internal error")
                    .build()
                    .toString());
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!isAuthenticated(req, resp)) {
            return;
        }

        String rawName = req.getParameter("name");
        String name = rawName == null ? "" : rawName.trim();
        if (name.isEmpty()) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing layer name");
            return;
        }
        if (name.length() > 45) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Layer name too long");
            return;
        }

        resp.setContentType("application/json");
        try {
            Layer created = layerDao.create(name);
            resp.setStatus(HttpServletResponse.SC_CREATED);
            resp.getWriter().write(Json.createObjectBuilder()
                    .add("layerId", created.getLayerId())
                    .add("name", created.getName())
                    .build()
                    .toString());
        } catch (SQLException e) {
            getServletContext().log("POST /api/layers failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    protected void doPatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!isAuthenticated(req, resp)) {
            return;
        }

        Long layerId = parseIdFromPath(req);
        if (layerId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing layer id");
            return;
        }

        String rawName = req.getParameter("name");
        String name = rawName == null ? "" : rawName.trim();
        if (name.isEmpty()) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing layer name");
            return;
        }
        if (name.length() > 45) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Layer name too long");
            return;
        }

        resp.setContentType("application/json");
        try {
            boolean updated = layerDao.rename(layerId, name);
            if (!updated) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Layer not found");
                return;
            }

            resp.getWriter().write(Json.createObjectBuilder()
                    .add("layerId", layerId)
                    .add("name", name)
                    .build()
                    .toString());
        } catch (SQLException e) {
            getServletContext().log("PATCH /api/layers failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!isAuthenticated(req, resp)) {
            return;
        }

        Long layerId = parseIdFromPath(req);
        if (layerId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing layer id");
            return;
        }

        try {
            boolean deleted = layerDao.delete(layerId);
            if (!deleted) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Layer not found");
                return;
            }
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("DELETE /api/layers failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    private boolean isAuthenticated(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendError(resp, HttpServletResponse.SC_UNAUTHORIZED, "not logged in");
            return false;
        }
        return true;
    }

    private Long parseIdFromPath(HttpServletRequest req) {
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

    private void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write(Json.createObjectBuilder()
                .add("error", message)
                .build()
                .toString());
    }
}
