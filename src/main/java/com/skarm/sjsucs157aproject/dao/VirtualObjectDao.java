package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.VirtualObject;
import com.skarm.sjsucs157aproject.model.VirtualProp;
import com.skarm.sjsucs157aproject.model.VirtualSignpost;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VirtualObjectDao {

    public List<VirtualObject> findAll() throws SQLException {
        String sql = "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, p.file_hash as detail, 'prop' as subtype " + "FROM virtual_objects v JOIN virtual_props p ON v.id = p.object_id " + "UNION " + "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, s.content as detail, 'signpost' as subtype " + "FROM virtual_objects v JOIN virtual_signposts s ON v.id = s.object_id";

        List<VirtualObject> objects = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String subtype = rs.getString("subtype");
                if ("prop".equals(subtype)) {
                    VirtualProp prop = new VirtualProp();
                    mapBaseFields(rs, prop);
                    prop.setFileHash(rs.getString("detail"));
                    objects.add(prop);
                } else {
                    VirtualSignpost signpost = new VirtualSignpost();
                    mapBaseFields(rs, signpost);
                    signpost.setContent(rs.getString("detail"));
                    objects.add(signpost);
                }
            }
        }
        return objects;
    }

    public void createProp(VirtualProp prop) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                long objectId = createBaseObject(conn, prop);
                String sql = "INSERT INTO virtual_props (object_id, file_hash) VALUES (?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, objectId);
                    ps.setString(2, prop.getFileHash());
                    ps.executeUpdate();
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

    public void createSignpost(VirtualSignpost signpost) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                long objectId = createBaseObject(conn, signpost);
                String sql = "INSERT INTO virtual_signposts (object_id, content) VALUES (?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, objectId);
                    ps.setString(2, signpost.getContent());
                    ps.executeUpdate();
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

    private long createBaseObject(Connection conn, VirtualObject obj) throws SQLException {
        String sql = "INSERT INTO virtual_objects (user_id, position, rotation, scale) VALUES (?, ST_PointFromText(?), ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, obj.getUserId());
            ps.setString(2, "POINT(" + obj.getLongitude() + " " + obj.getLatitude() + ")");
            ps.setString(3, obj.getRotation());
            ps.setDouble(4, obj.getScale());
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long id = rs.getLong(1);
                    obj.setId(id);
                    return id;
                }
            }
        }
        throw new SQLException("Failed to create base virtual object, no ID obtained.");
    }

    private void mapBaseFields(ResultSet rs, VirtualObject obj) throws SQLException {
        obj.setId(rs.getLong("id"));
        obj.setUserId(rs.getLong("user_id"));
        obj.setLongitude(rs.getDouble("lng"));
        obj.setLatitude(rs.getDouble("lat"));
        obj.setRotation(rs.getString("rotation"));
        obj.setScale(rs.getDouble("scale"));
    }
}
