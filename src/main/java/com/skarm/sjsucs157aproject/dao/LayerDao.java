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
}
