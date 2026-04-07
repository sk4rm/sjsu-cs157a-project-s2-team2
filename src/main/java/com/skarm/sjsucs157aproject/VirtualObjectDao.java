package com.skarm.sjsucs157aproject;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VirtualObjectDao {

    public List<VirtualObject> findAll() throws SQLException {
        String sql = "SELECT id, user_id, ST_X(position) as lng, ST_Y(position) as lat, rotation, scale, type, description FROM virtual_objects";
        List<VirtualObject> objects = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                objects.add(mapRow(rs));
            }
        }
        return objects;
    }

    public void create(VirtualObject obj) throws SQLException {
        String sql = "INSERT INTO virtual_objects (id, user_id, position, rotation, scale, type, description) VALUES (?, ?, ST_PointFromText(?), ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, obj.getId());
            ps.setLong(2, obj.getUserId());
            ps.setString(3, "POINT(" + obj.getLongitude() + " " + obj.getLatitude() + ")");
            ps.setString(4, obj.getRotation());
            ps.setDouble(5, obj.getScale());
            ps.setString(6, obj.getType());
            ps.setString(7, obj.getDescription());
            ps.executeUpdate();
        }
    }

    // Overload for creating with auto-increment ID if the schema supports it
    public void createWithoutSpecifiedId(VirtualObject obj) throws SQLException {
        String sql = "INSERT INTO virtual_objects (user_id, position, rotation, scale, type, description) VALUES (?, ST_PointFromText(?), ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, obj.getUserId());
            ps.setString(2, "POINT(" + obj.getLongitude() + " " + obj.getLatitude() + ")");
            ps.setString(3, obj.getRotation());
            ps.setDouble(4, obj.getScale());
            ps.setString(5, obj.getType());
            ps.setString(6, obj.getDescription());
            ps.executeUpdate();
            
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    obj.setId(rs.getLong(1));
                }
            }
        }
    }

    private VirtualObject mapRow(ResultSet rs) throws SQLException {
        VirtualObject obj = new VirtualObject();
        obj.setId(rs.getLong("id"));
        obj.setUserId(rs.getLong("user_id"));
        obj.setLongitude(rs.getDouble("lng"));
        obj.setLatitude(rs.getDouble("lat"));
        obj.setRotation(rs.getString("rotation"));
        obj.setScale(rs.getDouble("scale"));
        obj.setType(rs.getString("type"));
        obj.setDescription(rs.getString("description"));
        return obj;
    }
}
