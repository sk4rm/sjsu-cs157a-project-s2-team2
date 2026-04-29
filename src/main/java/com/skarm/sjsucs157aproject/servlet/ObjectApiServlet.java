package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.LayerDao;
import com.skarm.sjsucs157aproject.dao.VirtualObjectDao;
import com.skarm.sjsucs157aproject.model.VirtualObject;
import com.skarm.sjsucs157aproject.model.VirtualProp;
import com.skarm.sjsucs157aproject.model.VirtualSignpost;
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

@WebServlet(name = "objectApiServlet", urlPatterns = {"/api/objects", "/api/objects/*"})
public class ObjectApiServlet extends HttpServlet {

    private final VirtualObjectDao objectDao = new VirtualObjectDao();
    private final LayerDao layerDao = new LayerDao();

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            doPatch(req, resp);
        } else {
            super.service(req, resp);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;
        resp.setContentType("application/json");

        try {
            Long id = parseIdFromPath(req);
            if (id == null) {
                List<VirtualObject> objects = objectDao.findAll();
                JsonArrayBuilder arrayBuilder = Json.createArrayBuilder();
                for (VirtualObject obj : objects) {
                    arrayBuilder.add(toJson(obj));
                }
                resp.getWriter().write(arrayBuilder.build().toString());
            } else {
                VirtualObject obj = objectDao.findById(id);
                if (obj == null) {
                    sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                    return;
                }
                resp.getWriter().write(toJson(obj).build().toString());
            }
        } catch (SQLException e) {
            getServletContext().log("GET /api/objects failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;

        String pi = req.getPathInfo();
        if (pi != null && pi.length() > 1) {
            resp.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }
        resp.setContentType("application/json");

        try {
            String latParam = req.getParameter("latitude");
            String lngParam = req.getParameter("longitude");
            String typeParam = req.getParameter("type");

            if (latParam == null || lngParam == null) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing latitude or longitude");
                return;
            }

            double lat = Double.parseDouble(latParam);
            double lng = Double.parseDouble(lngParam);

            Double arX = parseOptionalDouble(req.getParameter("arX"));
            Double arY = parseOptionalDouble(req.getParameter("arY"));
            Double arZ = parseOptionalDouble(req.getParameter("arZ"));
            Double arYawDeg = parseOptionalDouble(req.getParameter("arYawDeg"));

            if ("signpost".equals(typeParam)) {
                VirtualSignpost signpost = new VirtualSignpost();
                signpost.setUserId(userId);
                signpost.setLatitude(lat);
                signpost.setLongitude(lng);
                applyArAnchor(signpost, arX, arY, arZ, arYawDeg);
                String raw = req.getParameter("content");
                String msg = raw == null ? "" : raw.trim();
                if (msg.isEmpty()) {
                    msg = "signpost";
                }
                if (msg.length() > 250) {
                    msg = msg.substring(0, 250);
                }
                signpost.setContent(msg);
                objectDao.create(signpost);
                linkLayerIfRequested(req, signpost);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(toJson(signpost).build().toString());
            } else {
                VirtualProp prop = new VirtualProp();
                prop.setUserId(userId);
                prop.setLatitude(lat);
                prop.setLongitude(lng);
                applyArAnchor(prop, arX, arY, arZ, arYawDeg);
                prop.setFileHash(req.getParameter("fileHash") != null ? req.getParameter("fileHash") : "preset:cube");
                objectDao.create(prop);
                linkLayerIfRequested(req, prop);
                resp.setStatus(HttpServletResponse.SC_CREATED);
                resp.getWriter().write(toJson(prop).build().toString());
            }
        } catch (NumberFormatException e) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid latitude or longitude");
        } catch (SQLException e) {
            getServletContext().log("POST /api/objects failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    protected void doPatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;
        resp.setContentType("application/json");

        Long id = parseIdFromPath(req);
        if (id == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing object id");
            return;
        }

        try {
            VirtualObject obj = objectDao.findById(id);
            if (obj == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            if (obj.getUserId() != userId) {
                sendError(resp, HttpServletResponse.SC_FORBIDDEN, "Not your object");
                return;
            }

            String rotation = req.getParameter("rotation");
            String scaleStr = req.getParameter("scale");
            String fileHash = req.getParameter("fileHash");
            String content = req.getParameter("content");

            if (rotation != null) obj.setRotation(rotation);
            if (scaleStr != null) {
                try {
                    obj.setScale(Double.parseDouble(scaleStr));
                } catch (NumberFormatException e) {
                    sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid scale");
                    return;
                }
            }
            if (obj instanceof VirtualProp prop && fileHash != null) {
                prop.setFileHash(fileHash);
            }
            if (obj instanceof VirtualSignpost signpost && content != null) {
                signpost.setContent(content);
            }

            objectDao.update(obj);
            resp.getWriter().write(toJson(obj).build().toString());
        } catch (SQLException e) {
            getServletContext().log("PATCH /api/objects failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;

        Long id = parseIdFromPath(req);
        if (id == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing object id");
            return;
        }

        try {
            VirtualObject obj = objectDao.findById(id);
            if (obj == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Object not found");
                return;
            }
            if (obj.getUserId() != userId) {
                sendError(resp, HttpServletResponse.SC_FORBIDDEN, "Not your object");
                return;
            }
            objectDao.delete(id);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("DELETE /api/objects failed", e);
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

    private Long parseIdFromPath(HttpServletRequest req) {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.length() <= 1) return null;
        try {
            return Long.parseLong(pathInfo.substring(1));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Double parseOptionalDouble(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Double.parseDouble(raw.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static void applyArAnchor(VirtualObject obj, Double arX, Double arY, Double arZ, Double arYawDeg) {
        obj.setArX(arX);
        obj.setArY(arY);
        obj.setArZ(arZ);
        obj.setArYawDeg(arYawDeg);
    }

    private void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write(Json.createObjectBuilder().add("error", message).build().toString());
    }

    private void linkLayerIfRequested(HttpServletRequest req, VirtualObject created) {
        String raw = req.getParameter("layerId");
        if (raw == null || raw.isBlank()) {
            return;
        }
        try {
            long layerId = Long.parseLong(raw.trim());
            layerDao.addObjectToLayer(layerId, created.getId());
            created.getLayerIds().add(layerId);
        } catch (NumberFormatException ex) {
            getServletContext().log("Ignoring invalid layerId: " + raw, ex);
        } catch (SQLException ex) {
            getServletContext().log("Optional layer link failed for object " + created.getId(), ex);
        }
    }

    private JsonObjectBuilder toJson(VirtualObject obj) {
        JsonArrayBuilder layerArr = Json.createArrayBuilder();
        for (Long lid : obj.getLayerIds()) {
            layerArr.add(lid);
        }
        JsonObjectBuilder b = Json.createObjectBuilder()
                .add("id", obj.getId())
                .add("userId", obj.getUserId())
                .add("latitude", obj.getLatitude())
                .add("longitude", obj.getLongitude())
                .add("rotation", obj.getRotation())
                .add("scale", obj.getScale())
                .add("layerIds", layerArr);
        if (obj.getArX() != null) {
            b.add("arX", obj.getArX());
        }
        if (obj.getArY() != null) {
            b.add("arY", obj.getArY());
        }
        if (obj.getArZ() != null) {
            b.add("arZ", obj.getArZ());
        }
        if (obj.getArYawDeg() != null) {
            b.add("arYawDeg", obj.getArYawDeg());
        }
        if (obj instanceof VirtualProp prop) {
            b.add("type", "prop").add("fileHash", prop.getFileHash());
        } else if (obj instanceof VirtualSignpost signpost) {
            b.add("type", "signpost").add("content", signpost.getContent());
        }
        return b;
    }
}
