package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.User;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Friendships are mutual. Each pair is stored as a single row with
 * user_id_1 = min(a, b) and user_id_2 = max(a, b), so there's only ever one
 * representation of a friendship in the table.
 */
public class FriendDao {

    public List<User> findFriendsOf(long userId) throws SQLException {
        // OR-join handles either column order; ORDER BY display_name keeps the
        // UI list stable.
        String sql = "SELECT u.id, u.display_name, u.username, u.height_meter "
                + "FROM user_accounts u "
                + "JOIN befriends b ON ("
                + "    (b.user_id_1 = ? AND b.user_id_2 = u.id) OR "
                + "    (b.user_id_2 = ? AND b.user_id_1 = u.id)"
                + ") "
                + "ORDER BY u.display_name";
        List<User> friends = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    User u = new User();
                    u.setUserId(rs.getLong("id"));
                    u.setDisplayName(rs.getString("display_name"));
                    u.setUsername(rs.getString("username"));
                    u.setHeightMeter(rs.getDouble("height_meter"));
                    friends.add(u);
                }
            }
        }
        return friends;
    }

    public boolean areFriends(long a, long b) throws SQLException {
        if (a == b) return false;
        long lo = Math.min(a, b), hi = Math.max(a, b);
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT 1 FROM befriends WHERE user_id_1 = ? AND user_id_2 = ?")) {
            ps.setLong(1, lo);
            ps.setLong(2, hi);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Idempotent: re-adding an existing friendship is a no-op (INSERT IGNORE). */
    public void addFriend(long a, long b) throws SQLException {
        if (a == b) {
            throw new SQLException("Cannot befriend self");
        }
        long lo = Math.min(a, b), hi = Math.max(a, b);
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT IGNORE INTO befriends (user_id_1, user_id_2) VALUES (?, ?)")) {
            ps.setLong(1, lo);
            ps.setLong(2, hi);
            ps.executeUpdate();
        }
    }

    /** Idempotent: removing a non-existent friendship returns false but doesn't error. */
    public boolean removeFriend(long a, long b) throws SQLException {
        if (a == b) return false;
        long lo = Math.min(a, b), hi = Math.max(a, b);
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM befriends WHERE user_id_1 = ? AND user_id_2 = ?")) {
            ps.setLong(1, lo);
            ps.setLong(2, hi);
            return ps.executeUpdate() > 0;
        }
    }
}
