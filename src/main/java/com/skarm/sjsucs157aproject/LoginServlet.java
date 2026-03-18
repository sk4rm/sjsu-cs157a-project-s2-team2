package com.skarm.sjsucs157aproject;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "loginServlet", value = "/login")
public class LoginServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String email = req.getParameter("email");
        String password = req.getParameter("password");

        if (email == null || email.isBlank() || password == null || password.isBlank()) {
            req.setAttribute("error", "Email and password are required.");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        try {
            User user = userDao.findByEmail(email);
            if (user == null) {
                req.setAttribute("error", "Invalid email or password.");
                req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
                return;
            }

            String expectedHash = user.getPasswordHash();
            String providedHash = PasswordUtil.hashPassword(password);

            if (!expectedHash.equals(providedHash)) {
                req.setAttribute("error", "Invalid email or password.");
                req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
                return;
            }

            HttpSession session = req.getSession(true);
            session.setAttribute("userId", user.getUserId());
            session.setAttribute("userEmail", user.getEmail());
            session.setAttribute("userDisplayName", user.getDisplayName());
            session.setAttribute("userRole", user.getRole());

            resp.sendRedirect(req.getContextPath() + "/");
        } catch (SQLException e) {
            throw new ServletException("Database error during login", e);
        }
    }
}

