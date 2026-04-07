package com.skarm.sjsucs157aproject;

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

@WebServlet(name = "objectApiServlet", value = "/api/objects")
public class ObjectApiServlet extends HttpServlet {

    private final VirtualObjectDao objectDao = new VirtualObjectDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json");
        try {
            List<VirtualObject> objects = objectDao.findAll();
            JsonArrayBuilder arrayBuilder = Json.createArrayBuilder();
            for (VirtualObject obj : objects) {
                JsonObjectBuilder objBuilder = Json.createObjectBuilder()
                        .add("id", obj.getId())
                        .add("userId", obj.getUserId())
                        .add("latitude", obj.getLatitude())
                        .add("longitude", obj.getLongitude())
                        .add("rotation", obj.getRotation())
                        .add("scale", obj.getScale());

                if (obj instanceof VirtualProp) {
                    objBuilder.add("type", "prop")
                              .add("fileHash", ((VirtualProp) obj).getFileHash());
                } else if (obj instanceof VirtualSignpost) {
                    objBuilder.add("type", "signpost")
                              .add("content", ((VirtualSignpost) obj).getContent());
                }
                arrayBuilder.add(objBuilder);
            }
            resp.getWriter().write(arrayBuilder.build().toString());
        } catch (SQLException e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"Database error: " + e.getMessage() + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        long userId = (long) session.getAttribute("userId");
        resp.setContentType("application/json");

        try {
            String latParam = req.getParameter("latitude");
            String lngParam = req.getParameter("longitude");
            String typeParam = req.getParameter("type"); // "prop" or "signpost"

            if (latParam == null || lngParam == null) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.getWriter().write("{\"error\": \"Missing latitude or longitude\"}");
                return;
            }

            double lat = Double.parseDouble(latParam);
            double lng = Double.parseDouble(lngParam);

            if ("signpost".equals(typeParam)) {
                VirtualSignpost signpost = new VirtualSignpost();
                signpost.setUserId(userId);
                signpost.setLatitude(lat);
                signpost.setLongitude(lng);
                signpost.setContent(req.getParameter("content") != null ? req.getParameter("content") : "Default Signpost");
                objectDao.createSignpost(signpost);
                resp.getWriter().write(Json.createObjectBuilder().add("status", "success").add("id", signpost.getId()).build().toString());
            } else {
                // Default to Prop
                VirtualProp prop = new VirtualProp();
                prop.setUserId(userId);
                prop.setLatitude(lat);
                prop.setLongitude(lng);
                prop.setFileHash(req.getParameter("fileHash") != null ? req.getParameter("fileHash") : "default_box_hash");
                objectDao.createProp(prop);
                resp.getWriter().write(Json.createObjectBuilder().add("status", "success").add("id", prop.getId()).build().toString());
            }

        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }
}
