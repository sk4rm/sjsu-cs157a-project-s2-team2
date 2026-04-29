package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.VirtualObject;
import com.skarm.sjsucs157aproject.model.VirtualProp;
import com.skarm.sjsucs157aproject.model.VirtualSignpost;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class VirtualObjectDao {

    public List<VirtualObject> findAll() throws SQLException {
        String sql = "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, "
                + "p.file_hash as detail, 'prop' as subtype, v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg "
                + "FROM virtual_objects v JOIN virtual_props p ON v.id = p.object_id "
                + "UNION "
                + "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, "
                + "s.content as detail, 'signpost' as subtype, v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg "
                + "FROM virtual_objects v JOIN virtual_signposts s ON v.id = s.object_id";

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
        attachLayerIds(objects);
        return objects;
    }

    public void create(VirtualObject obj) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                long objectId = createBaseObject(conn, obj);
                if (obj instanceof VirtualProp prop) {
                    try (PreparedStatement ps = conn.prepareStatement("INSERT INTO virtual_props (object_id, file_hash) VALUES (?, ?)")) {
                        ps.setLong(1, objectId);
                        ps.setString(2, prop.getFileHash());
                        ps.executeUpdate();
                    }
                } else if (obj instanceof VirtualSignpost signpost) {
                    try (PreparedStatement ps = conn.prepareStatement("INSERT INTO virtual_signposts (object_id, content) VALUES (?, ?)")) {
                        ps.setLong(1, objectId);
                        ps.setString(2, signpost.getContent());
                        ps.executeUpdate();
                    }
                } else {
                    throw new SQLException("Cannot create bare VirtualObject; must be a VirtualProp or VirtualSignpost");
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

    public VirtualObject findById(long id) throws SQLException {
        String sql = "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, "
                + "p.file_hash as detail, 'prop' as subtype, v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg "
                + "FROM virtual_objects v JOIN virtual_props p ON v.id = p.object_id WHERE v.id = ? "
                + "UNION "
                + "SELECT v.id, v.user_id, ST_X(v.position) as lng, ST_Y(v.position) as lat, v.rotation, v.scale, "
                + "s.content as detail, 'signpost' as subtype, v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg "
                + "FROM virtual_objects v JOIN virtual_signposts s ON v.id = s.object_id WHERE v.id = ?";
        VirtualObject result = null;
        try (Connection conn = DbUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String subtype = rs.getString("subtype");
                    if ("prop".equals(subtype)) {
                        VirtualProp prop = new VirtualProp();
                        mapBaseFields(rs, prop);
                        prop.setFileHash(rs.getString("detail"));
                        result = prop;
                    } else {
                        VirtualSignpost signpost = new VirtualSignpost();
                        mapBaseFields(rs, signpost);
                        signpost.setContent(rs.getString("detail"));
                        result = signpost;
                    }
                }
            }
        }
        if (result != null) {
            attachLayerIds(List.of(result));
        }
        return result;
    }

    public void update(VirtualObject obj) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement("UPDATE virtual_objects SET rotation = ?, scale = ? WHERE id = ?")) {
                    ps.setString(1, obj.getRotation());
                    ps.setDouble(2, obj.getScale());
                    ps.setLong(3, obj.getId());
                    ps.executeUpdate();
                }
                if (obj instanceof VirtualProp prop) {
                    try (PreparedStatement ps = conn.prepareStatement("UPDATE virtual_props SET file_hash = ? WHERE object_id = ?")) {
                        ps.setString(1, prop.getFileHash());
                        ps.setLong(2, prop.getId());
                        ps.executeUpdate();
                    }
                } else if (obj instanceof VirtualSignpost signpost) {
                    try (PreparedStatement ps = conn.prepareStatement("UPDATE virtual_signposts SET content = ? WHERE object_id = ?")) {
                        ps.setString(1, signpost.getContent());
                        ps.setLong(2, signpost.getId());
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

    public boolean delete(long id) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Delete from dependent tables first to avoid foreign key violations
                String[] dependents = {
                    "DELETE FROM virtual_props WHERE object_id = ?",
                    "DELETE FROM virtual_signposts WHERE object_id = ?",
                    "DELETE FROM includes WHERE object_id = ?",
                    "DELETE FROM comments WHERE object_id = ?",
                    "DELETE FROM votes WHERE object_id = ?"
                };
                
                for (String sql : dependents) {
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setLong(1, id);
                        ps.executeUpdate();
                    }
                }

                int rows;
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM virtual_objects WHERE id = ?")) {
                    ps.setLong(1, id);
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

    private long createBaseObject(Connection conn, VirtualObject obj) throws SQLException {
        String sql = "INSERT INTO virtual_objects (user_id, position, rotation, scale, ar_x, ar_y, ar_z, ar_yaw_deg) "
                + "VALUES (?, ST_PointFromText(?), ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, obj.getUserId());
            ps.setString(2, "POINT(" + obj.getLongitude() + " " + obj.getLatitude() + ")");
            ps.setString(3, obj.getRotation());
            ps.setDouble(4, obj.getScale());
            setNullableDouble(ps, 5, obj.getArX());
            setNullableDouble(ps, 6, obj.getArY());
            setNullableDouble(ps, 7, obj.getArZ());
            setNullableDouble(ps, 8, obj.getArYawDeg());
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
        mapArColumns(rs, obj);
    }

    private void mapArColumns(ResultSet rs, VirtualObject obj) throws SQLException {
        double x = rs.getDouble("ar_x");
        if (!rs.wasNull()) {
            obj.setArX(x);
        }
        double y = rs.getDouble("ar_y");
        if (!rs.wasNull()) {
            obj.setArY(y);
        }
        double z = rs.getDouble("ar_z");
        if (!rs.wasNull()) {
            obj.setArZ(z);
        }
        double yaw = rs.getDouble("ar_yaw_deg");
        if (!rs.wasNull()) {
            obj.setArYawDeg(yaw);
        }
    }

    private void setNullableDouble(PreparedStatement ps, int idx, Double val) throws SQLException {
        if (val != null) {
            ps.setDouble(idx, val);
        } else {
            ps.setNull(idx, Types.DOUBLE);
        }
    }

    private void attachLayerIds(List<VirtualObject> objects) throws SQLException {
        if (objects.isEmpty()) {
            return;
        }
        for (VirtualObject o : objects) {
            o.getLayerIds().clear();
        }
        List<Long> ids = new ArrayList<>();
        for (VirtualObject o : objects) {
            ids.add(o.getId());
        }
        String placeholders = String.join(",", ids.stream().map(id -> "?").toList());
        String sql = "SELECT object_id, layer_id FROM includes WHERE object_id IN (" + placeholders + ") ORDER BY layer_id";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setLong(i + 1, ids.get(i));
            }
            Map<Long, VirtualObject> byId = new HashMap<>();
            for (VirtualObject o : objects) {
                byId.put(o.getId(), o);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    long oid = rs.getLong("object_id");
                    VirtualObject o = byId.get(oid);
                    if (o != null) {
                        o.getLayerIds().add(rs.getLong("layer_id"));
                    }
                }
            }
        }
    }
}
