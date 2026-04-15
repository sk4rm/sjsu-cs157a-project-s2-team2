package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.User;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.*;

// user table stuff
public class UserDao {

    public User findByUsername(String username) throws SQLException {
        String sql = "SELECT id, display_name, username, password_hash, height_meter FROM user_accounts WHERE username = ?";
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
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
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
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
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
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
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, displayName);
            ps.setDouble(2, heightMeter);
            ps.setLong(3, userId);
            ps.executeUpdate();
        }
    }

    // nuke user + their junk — no cascade in sql so we delete in order by hand
    public void deleteById(long userId) throws SQLException {
        String[] statements = {
                "DELETE FROM virtual_props WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?)",
                "DELETE FROM virtual_signposts WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?)",
                "DELETE FROM includes WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?)",
                "DELETE FROM comments WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?)",
                "DELETE FROM votes WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?)",
                "DELETE FROM virtual_objects WHERE user_id = ?",
                "DELETE FROM votes WHERE voter_id = ?",
                "DELETE FROM comments WHERE commenter_id = ?",
                "DELETE FROM object_placements WHERE user_id = ?",
                "DELETE FROM befriends WHERE user_id_1 = ? OR user_id_2 = ?",
                "DELETE FROM user_accounts WHERE id = ?"
        };

        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                for (String sql : statements) {
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setLong(1, userId);
                        // friends row needs both user ids
                        if (sql.contains("user_id_2")) {
                            ps.setLong(2, userId);
                        }
                        ps.executeUpdate();
                    }
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
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
