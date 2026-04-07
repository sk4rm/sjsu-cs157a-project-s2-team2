package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.User;
import com.skarm.sjsucs157aproject.util.DbUtil;
import java.sql.*;

// Simple DAO for user database operations
public class UserDao {

    public User findByUsername(String username) throws SQLException {
        String sql = "SELECT id, display_name, username, password_hash, height_meter FROM user_accounts WHERE username = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public User findById(long userId) throws SQLException {
        String sql = "SELECT id, display_name, username, password_hash, height_meter FROM user_accounts WHERE id = ?";
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

    public long createUser(String displayName, String username, String passwordHash, double heightMeter) throws SQLException {
        String sql = "INSERT INTO user_accounts (display_name, username, password_hash, height_meter) VALUES (?,?,?,?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, displayName);
            ps.setString(2, username);
            ps.setString(3, passwordHash);
            ps.setDouble(4, heightMeter);
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }
        return -1;
    }

    public void updateProfile(long userId, String displayName, double heightMeter) throws SQLException {
        String sql = "UPDATE user_accounts SET display_name = ?, height_meter = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, displayName);
            ps.setDouble(2, heightMeter);
            ps.setLong(3, userId);
            ps.executeUpdate();
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserId(rs.getLong("id"));
        user.setDisplayName(rs.getString("display_name"));
        user.setUsername(rs.getString("username"));
        user.setPasswordHash(rs.getString("password_hash"));
        user.setHeightMeter(rs.getDouble("height_meter"));
        return user;
    }
}
