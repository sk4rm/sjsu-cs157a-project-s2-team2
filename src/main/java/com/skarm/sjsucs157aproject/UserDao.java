package com.skarm.sjsucs157aproject;

import java.sql.*;

// Simple DAO for user database operations
public class UserDao {

    public User findByEmail(String email) throws SQLException {
        String sql = "SELECT user_id, display_name, email, password_hash, height_meters, role FROM UserAccounts WHERE email = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public User findById(long userId) throws SQLException {
        String sql = "SELECT user_id, display_name, email, password_hash, height_meters, role FROM UserAccounts WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public long createUser(String displayName, String email, String passwordHash, double heightMeters, String role) throws SQLException {
        String sql = "INSERT INTO UserAccounts (display_name, email, password_hash, height_meters, role) VALUES (?,?,?,?,?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, displayName);
            ps.setString(2, email);
            ps.setString(3, passwordHash);
            ps.setDouble(4, heightMeters);
            ps.setString(5, role);
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }
        return -1;
    }

    public void updateProfile(long userId, String displayName, double heightMeters) throws SQLException {
        String sql = "UPDATE UserAccounts SET display_name = ?, height_meters = ? WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, displayName);
            ps.setDouble(2, heightMeters);
            ps.setLong(3, userId);
            ps.executeUpdate();
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserId(rs.getLong("user_id"));
        user.setDisplayName(rs.getString("display_name"));
        user.setEmail(rs.getString("email"));
        user.setPasswordHash(rs.getString("password_hash"));
        user.setHeightMeters(rs.getDouble("height_meters"));
        user.setRole(rs.getString("role"));
        return user;
    }
}

