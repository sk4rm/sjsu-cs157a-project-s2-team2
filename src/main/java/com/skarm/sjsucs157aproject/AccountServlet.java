package com.skarm.sjsucs157aproject;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "accountServlet", value = "/account")
public class AccountServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        long userId = (Long) session.getAttribute("userId");
        try {
            User user = userDao.findById(userId);
            if (user == null) {
                session.invalidate();
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            req.setAttribute("user", user);
            req.getRequestDispatcher("/WEB-INF/views/account.jsp").forward(req, resp);
        } catch (SQLException e) {
            throw new ServletException("Database error loading account", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String displayName = req.getParameter("displayName");
        String heightStr = req.getParameter("heightMeters");

        if (displayName == null || displayName.isBlank() || heightStr == null || heightStr.isBlank()) {
            req.setAttribute("error", "Display name and height are required.");
            doGet(req, resp);
            return;
        }

        double heightMeters;
        try {
            heightMeters = Double.parseDouble(heightStr);
            if (heightMeters <= 0 || heightMeters > 3) {
                throw new NumberFormatException("Height out of range");
            }
        } catch (NumberFormatException e) {
            req.setAttribute("error", "Height must be a value in meters (e.g., 1.75).");
            doGet(req, resp);
            return;
        }

        long userId = (Long) session.getAttribute("userId");
        try {
            userDao.updateProfile(userId, displayName, heightMeters);
            session.setAttribute("userDisplayName", displayName);
            resp.sendRedirect(req.getContextPath() + "/account?updated=1");
        } catch (SQLException e) {
            throw new ServletException("Database error updating account", e);
        }
    }
}

