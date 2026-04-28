package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class VoteDao {

    public record Tally(int up, int down) {}

    public Tally tallyForObject(long objectId) throws SQLException {
        String sql = "SELECT "
                + "COALESCE(SUM(CASE WHEN type = 1 THEN 1 ELSE 0 END), 0) AS up_cnt, "
                + "COALESCE(SUM(CASE WHEN type = -1 THEN 1 ELSE 0 END), 0) AS down_cnt "
                + "FROM votes WHERE object_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, objectId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Tally(rs.getInt("up_cnt"), rs.getInt("down_cnt"));
                }
            }
        }
        return new Tally(0, 0);
    }

    public Integer findVote(long voterId, long objectId) throws SQLException {
        String sql = "SELECT type FROM votes WHERE voter_id = ? AND object_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, voterId);
            ps.setLong(2, objectId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("type");
                }
            }
        }
        return null;
    }

    public void upsert(long voterId, long objectId, int type) throws SQLException {
        if (type != 1 && type != -1) {
            throw new IllegalArgumentException("vote type must be 1 or -1");
        }
        String sql = "INSERT INTO votes (voter_id, object_id, type) VALUES (?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE type = VALUES(type)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, voterId);
            ps.setLong(2, objectId);
            ps.setInt(3, type);
            ps.executeUpdate();
        }
    }
}
