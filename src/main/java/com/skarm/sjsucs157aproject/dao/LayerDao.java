package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.Layer;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class LayerDao {

    public List<Layer> findAll() throws SQLException {
        String sql = "SELECT layer_id, name FROM layers ORDER BY layer_id";
        List<Layer> layers = new ArrayList<>();

        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Layer layer = new Layer();
                layer.setLayerId(rs.getLong("layer_id"));
                layer.setName(rs.getString("name"));
                layers.add(layer);
            }
        }

        return layers;
    }

    public Layer create(String name) throws SQLException {
        String sql = "INSERT INTO layers (name) VALUES (?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    Layer layer = new Layer();
                    layer.setLayerId(rs.getLong(1));
                    layer.setName(name);
                    return layer;
                }
            }
        }
        throw new SQLException("Failed to create layer, no ID returned.");
    }

    public boolean rename(long layerId, String name) throws SQLException {
        String sql = "UPDATE layers SET name = ? WHERE layer_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setLong(2, layerId);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Associates a virtual object with a layer. Duplicate pairs are ignored (INSERT IGNORE).
     */
    public void addObjectToLayer(long layerId, long objectId) throws SQLException {
        String sql = "INSERT IGNORE INTO includes (layer_id, object_id) VALUES (?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, layerId);
            ps.setLong(2, objectId);
            ps.executeUpdate();
        }
    }

    /**
     * Removes an object from a layer. Returns true if a row was deleted.
     */
    public boolean removeObjectFromLayer(long layerId, long objectId) throws SQLException {
        String sql = "DELETE FROM includes WHERE layer_id = ? AND object_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, layerId);
            ps.setLong(2, objectId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean exists(long layerId) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM layers WHERE layer_id = ?")) {
            ps.setLong(1, layerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean delete(long layerId) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM includes WHERE layer_id = ?")) {
                    ps.setLong(1, layerId);
                    ps.executeUpdate();
                }

                int rows;
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM layers WHERE layer_id = ?")) {
                    ps.setLong(1, layerId);
                    rows = ps.executeUpdate();
                }

                conn.commit();
                return rows > 0;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
