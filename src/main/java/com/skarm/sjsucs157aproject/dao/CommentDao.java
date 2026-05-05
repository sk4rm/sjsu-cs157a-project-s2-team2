package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.Comment;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CommentDao {

    // Joined columns are aliased so mapRow can fetch them by name without
    // colliding with anything else and without depending on column order.
    private static final String SELECT_COMMENT_WITH_USER =
            "SELECT c.id, c.commenter_id, c.object_id, c.created_at, c.text_content, "
            + "u.display_name AS commenter_display_name "
            + "FROM comments c JOIN user_accounts u ON u.id = c.commenter_id";

    public Comment findById(long id) throws SQLException {
        String sql = SELECT_COMMENT_WITH_USER + " WHERE c.id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public List<Comment> findByObjectId(long objectId) throws SQLException {
        String sql = SELECT_COMMENT_WITH_USER + " WHERE c.object_id = ? ORDER BY c.created_at ASC";
        List<Comment> out = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, objectId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(mapRow(rs));
                }
            }
        }
        return out;
    }

    public Comment create(long commenterId, long objectId, String textContent) throws SQLException {
        String sql = "INSERT INTO comments (commenter_id, object_id, created_at, text_content) VALUES (?, ?, NOW(), ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, commenterId);
            ps.setLong(2, objectId);
            ps.setString(3, textContent);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new SQLException("comment insert got no id");
                }
                long id = rs.getLong(1);
                Comment c = findById(id);
                if (c == null) {
                    throw new SQLException("comment row missing after insert");
                }
                return c;
            }
        }
    }

    public boolean deleteById(long id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM comments WHERE id = ?")) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    private static Comment mapRow(ResultSet rs) throws SQLException {
        Comment c = new Comment();
        c.setId(rs.getLong("id"));
        c.setCommenterId(rs.getLong("commenter_id"));
        c.setCommenterDisplayName(rs.getString("commenter_display_name"));
        c.setObjectId(rs.getLong("object_id"));
        c.setCreatedAt(rs.getTimestamp("created_at"));
        c.setTextContent(rs.getString("text_content"));
        return c;
    }
}
