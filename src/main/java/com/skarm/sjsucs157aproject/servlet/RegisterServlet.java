package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.UserDao;
import com.skarm.sjsucs157aproject.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "registerServlet", value = "/register")
public class RegisterServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // signup form is on index not here
        resp.sendRedirect(req.getContextPath() + "/");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String displayName = req.getParameter("displayName");
        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String confirmPassword = req.getParameter("confirmPassword");
        String heightStr = req.getParameter("heightMeter");

        if (displayName == null || displayName.isBlank() || username == null || username.isBlank() || password == null || password.isBlank() || confirmPassword == null || confirmPassword.isBlank() || heightStr == null || heightStr.isBlank()) {
            HttpSession session = req.getSession();
            session.setAttribute("registerError", "All fields are required.");
            resp.sendRedirect(req.getContextPath() + "/#join");
            return;
        }

        if (!password.equals(confirmPassword)) {
            HttpSession session = req.getSession();
            session.setAttribute("registerError", "Passwords do not match.");
            resp.sendRedirect(req.getContextPath() + "/#join");
            return;
        }

        double heightMeters;
        try {
            heightMeters = Double.parseDouble(heightStr);
            if (heightMeters <= 0 || heightMeters > 3) {
                throw new NumberFormatException("Height out of range");
            }
        } catch (NumberFormatException e) {
            HttpSession session = req.getSession();
            session.setAttribute("registerError", "Height must be a value in meters (e.g., 1.75).");
            resp.sendRedirect(req.getContextPath() + "/#join");
            return;
        }

        try {
            if (userDao.findByUsername(username) != null) {
                HttpSession session = req.getSession();
                session.setAttribute("registerError", "An account with that username already exists.");
                resp.sendRedirect(req.getContextPath() + "/#join");
                return;
            }

            String passwordHash = PasswordUtil.hashPassword(password);
            long userId = userDao.createUser(displayName, username, passwordHash, heightMeters);

            if (userId <= 0) {
                HttpSession session = req.getSession();
                session.setAttribute("registerError", "Unable to create account. Please try again.");
                resp.sendRedirect(req.getContextPath() + "/#join");
                return;
            }

            resp.sendRedirect(req.getContextPath() + "/login?registered=1");
        } catch (SQLException e) {
            throw new ServletException("Database error during registration", e);
        }
    }
}
