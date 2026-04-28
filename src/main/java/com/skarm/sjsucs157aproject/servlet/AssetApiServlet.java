package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.AssetDao;
import com.skarm.sjsucs157aproject.model.Asset;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObjectBuilder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.SQLException;
import java.util.List;

@WebServlet(name = "assetApiServlet", urlPatterns = {"/api/assets", "/api/assets/*"})
@MultipartConfig(
        maxFileSize = 8 * 1024 * 1024,        // 8 MB per file
        maxRequestSize = 9 * 1024 * 1024,     // a little headroom for form fields
        fileSizeThreshold = 1024 * 1024       // buffer first 1 MB in memory
)
public class AssetApiServlet extends HttpServlet {

    private static final long MAX_BYTES = 8L * 1024 * 1024;
    private final AssetDao assetDao = new AssetDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;

        Long id = parseIdFromPath(req);
        try {
            if (id == null) {
                resp.setContentType("application/json");
                List<Asset> all = assetDao.listAll();
                JsonArrayBuilder arr = Json.createArrayBuilder();
                for (Asset a : all) arr.add(toJson(a));
                resp.getWriter().write(arr.build().toString());
                return;
            }

            Asset meta = assetDao.findMetadata(id);
            if (meta == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Asset not found");
                return;
            }
            byte[] bytes = assetDao.readBytes(id);
            if (bytes == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Asset bytes missing");
                return;
            }
            resp.setContentType(meta.getMimeType());
            resp.setContentLength(bytes.length);
            // immutable per id — safe to cache aggressively
            resp.setHeader("Cache-Control", "public, max-age=31536000, immutable");
            try (OutputStream os = resp.getOutputStream()) {
                os.write(bytes);
            }
        } catch (SQLException e) {
            getServletContext().log("GET /api/assets failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;

        if (!isMultipart(req)) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Expected multipart/form-data");
            return;
        }

        try {
            Part filePart = req.getPart("file");
            if (filePart == null || filePart.getSize() == 0) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing file part");
                return;
            }
            if (filePart.getSize() > MAX_BYTES) {
                sendError(resp, HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE,
                        "File too large (max " + (MAX_BYTES / 1024 / 1024) + " MB)");
                return;
            }

            String submittedName = filePart.getSubmittedFileName();
            if (submittedName == null) submittedName = "model.glb";
            String lower = submittedName.toLowerCase();
            // .gltf is the JSON variant that references external .bin + texture
            // files as siblings — incompatible with single-file upload because
            // the loader would try to fetch /api/assets/textures/foo.png etc.
            // Only the self-contained binary variant (.glb) is accepted.
            if (!lower.endsWith(".glb")) {
                sendError(resp, HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE,
                        "Only .glb (self-contained binary glTF) is accepted. " +
                                "Convert .gltf folders to .glb first — e.g. import in Blender and re-export as .glb.");
                return;
            }

            String displayName = req.getParameter("displayName");
            if (displayName == null || displayName.isBlank()) {
                displayName = stripExtension(submittedName);
            }
            if (displayName.length() > 100) displayName = displayName.substring(0, 100);

            String mimeType = "model/gltf-binary";

            byte[] bytes;
            try (InputStream in = filePart.getInputStream()) {
                bytes = in.readAllBytes();
            }
            if (bytes.length == 0) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Empty file");
                return;
            }

            Asset created = assetDao.create(userId, displayName, mimeType, bytes);
            resp.setStatus(HttpServletResponse.SC_CREATED);
            resp.setContentType("application/json");
            resp.getWriter().write(toJson(created).build().toString());
        } catch (SQLException e) {
            getServletContext().log("POST /api/assets failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Long userId = requireAuth(req, resp);
        if (userId == null) return;

        Long id = parseIdFromPath(req);
        if (id == null) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Missing asset id");
            return;
        }

        try {
            Asset meta = assetDao.findMetadata(id);
            if (meta == null) {
                sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Asset not found");
                return;
            }
            if (meta.getUploaderId() != userId) {
                sendError(resp, HttpServletResponse.SC_FORBIDDEN, "Not your asset");
                return;
            }
            assetDao.delete(id);
            resp.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            getServletContext().log("DELETE /api/assets failed", e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal error");
        }
    }

    private boolean isMultipart(HttpServletRequest req) {
        String ct = req.getContentType();
        return ct != null && ct.toLowerCase().startsWith("multipart/");
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
        String pi = req.getPathInfo();
        if (pi == null || pi.length() <= 1) return null;
        try {
            return Long.parseLong(pi.substring(1));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String stripExtension(String name) {
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    private void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.getWriter().write(Json.createObjectBuilder().add("error", message).build().toString());
    }

    private JsonObjectBuilder toJson(Asset a) {
        return Json.createObjectBuilder()
                .add("id", a.getId())
                .add("uploaderId", a.getUploaderId())
                .add("displayName", a.getDisplayName())
                .add("fileHash", a.getFileHash())
                .add("mimeType", a.getMimeType())
                .add("byteSize", a.getByteSize());
    }
}
