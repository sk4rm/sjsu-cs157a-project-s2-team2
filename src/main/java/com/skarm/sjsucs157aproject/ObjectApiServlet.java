package com.skarm.sjsucs157aproject;

import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonObject;
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
                arrayBuilder.add(Json.createObjectBuilder()
                        .add("id", obj.getId())
                        .add("userId", obj.getUserId())
                        .add("latitude", obj.getLatitude())
                        .add("longitude", obj.getLongitude())
                        .add("rotation", obj.getRotation())
                        .add("scale", obj.getScale())
                        .add("type", obj.getType()));
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
            // Simple parsing of parameters for "dropping" an object
            String latParam = req.getParameter("latitude");
            String lngParam = req.getParameter("longitude");
            String typeParam = req.getParameter("type");

            if (latParam == null || lngParam == null) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                resp.getWriter().write("{\"error\": \"Missing latitude or longitude\"}");
                return;
            }

            VirtualObject obj = new VirtualObject();
            obj.setUserId(userId);
            obj.setLatitude(Double.parseDouble(latParam));
            obj.setLongitude(Double.parseDouble(lngParam));
            obj.setType(typeParam != null ? typeParam : "box");
            obj.setRotation("0 0 0");
            obj.setScale(1.0);

            objectDao.createWithoutSpecifiedId(obj);

            JsonObject responseJson = Json.createObjectBuilder()
                    .add("status", "success")
                    .add("id", obj.getId())
                    .build();
            resp.getWriter().write(responseJson.toString());

        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }
}
