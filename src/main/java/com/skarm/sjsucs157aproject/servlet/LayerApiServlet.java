package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.LayerDao;
import com.skarm.sjsucs157aproject.dao.VirtualObjectDao;
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
    private final VirtualObjectDao objectDao = new VirtualObjectDao();

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

        // POST /api/layers/<layerId>/objects → add membership
        long[] nested = parseLayerObjectsPath(req);
        if (nested != null) {
            handleAddMembership(req, resp, nested[0]);
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

    private void handleAddMembership(HttpServletRequest req, HttpServletResponse resp, long layerId) throws IOException {
        String rawObj = req.getParameter("objectId");
        Long objectId = parseLong(rawObj);
        if (objectId == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing objectId");
            return;
        }
        try {
            if (!layerDao.exists(layerId)) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Layer not found");
                return;
            }
            if (objectDao.findById(objectId) == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            layerDao.addObjectToLayer(layerId, objectId);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("POST /api/layers/<id>/objects failed", e);
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

        // DELETE /api/layers/<layerId>/objects/<objectId> → remove membership
        long[] nested = parseLayerObjectsPath(req);
        if (nested != null) {
            if (nested.length < 2) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing objectId in path");
                return;
            }
            try {
                layerDao.removeObjectFromLayer(nested[0], nested[1]);
                // Idempotent: 204 even if no row was matched.
                resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
            } catch (SQLException e) {
                getServletContext().log("DELETE /api/layers/<id>/objects/<oid> failed", e);
                sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
            }
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
        // Only treat as a "layer id" path if it's a single segment of digits;
        // nested /<id>/objects[/<oid>] paths are handled separately.
        String trimmed = pathInfo.substring(1);
        if (trimmed.indexOf('/') >= 0) {
            return null;
        }
        try {
            return Long.parseLong(trimmed);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Parses /<layerId>/objects[/<objectId>] from pathInfo.
     * Returns null if not a layer-objects path.
     * Returns [layerId] for the collection path, [layerId, objectId] for the item path.
     */
    private long[] parseLayerObjectsPath(HttpServletRequest req) {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() <= 1) {
            return null;
        }
        String[] parts = pathInfo.substring(1).split("/");
        if (parts.length < 2 || !"objects".equals(parts[1])) {
            return null;
        }
        try {
            long layerId = Long.parseLong(parts[0]);
            if (parts.length == 2) {
                return new long[]{layerId};
            }
            long objectId = Long.parseLong(parts[2]);
            return new long[]{layerId, objectId};
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parseLong(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(raw.trim());
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
