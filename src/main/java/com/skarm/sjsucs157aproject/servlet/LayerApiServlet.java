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

@WebServlet(name = "layerApiServlet", urlPatterns = {"/api/layers"})
public class LayerApiServlet extends HttpServlet {

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

    private boolean isAuthenticated(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.setContentType("application/json");
            resp.getWriter().write(Json.createObjectBuilder()
                    .add("error", "not logged in")
                    .build()
                    .toString());
            return false;
        }
        return true;
    }
}
