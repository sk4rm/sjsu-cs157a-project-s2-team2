package com.skarm.sjsucs157aproject.servlet;

import com.skarm.sjsucs157aproject.dao.UserDao;
import com.skarm.sjsucs157aproject.model.User;
import com.skarm.sjsucs157aproject.util.PasswordUtil;
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

        if ("delete".equals(req.getParameter("action"))) {
            handleDelete(req, resp, session);
            return;
        }

        String displayName = req.getParameter("displayName");
        String heightStr = req.getParameter("heightMeter");

        if (displayName == null || displayName.isBlank() || heightStr == null || heightStr.isBlank()) {
            req.setAttribute("error", "Display name and height are required.");
            doGet(req, resp);
            return;
        }

        double heightMeter;
        try {
            heightMeter = Double.parseDouble(heightStr);
            if (heightMeter <= 0 || heightMeter > 3) {
                throw new NumberFormatException("Height out of range");
            }
        } catch (NumberFormatException e) {
            req.setAttribute("error", "Height must be a value in meters (e.g., 1.75).");
            doGet(req, resp);
            return;
        }

        long userId = (Long) session.getAttribute("userId");
        try {
            userDao.updateProfile(userId, displayName, heightMeter);
            session.setAttribute("userDisplayName", displayName);
            resp.sendRedirect(req.getContextPath() + "/account?updated=1");
        } catch (SQLException e) {
            throw new ServletException("Database error updating account", e);
        }
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, HttpSession session) throws ServletException, IOException {
        String password = req.getParameter("deletePassword");
        String confirmation = req.getParameter("deleteConfirmation");

        if (password == null || password.isBlank()) {
            req.setAttribute("deleteError", "Password is required to delete your account.");
            doGet(req, resp);
            return;
        }
        if (!"DELETE".equals(confirmation)) {
            req.setAttribute("deleteError", "Type DELETE exactly to confirm.");
            doGet(req, resp);
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
            if (!PasswordUtil.verifyPassword(user.getPasswordHash(), password)) {
                req.setAttribute("deleteError", "Incorrect password.");
                doGet(req, resp);
                return;
            }
            userDao.deleteById(userId);
            session.invalidate();
            resp.sendRedirect(req.getContextPath() + "/?deleted=1");
        } catch (SQLException e) {
            throw new ServletException("Database error deleting account", e);
        }
    }
}
