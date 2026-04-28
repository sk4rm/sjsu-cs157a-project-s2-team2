package com.skarm.sjsucs157aproject.dao;

import com.skarm.sjsucs157aproject.model.Asset;
import com.skarm.sjsucs157aproject.util.DbUtil;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AssetDao {

    public Asset create(long uploaderId, String displayName, String mimeType, byte[] bytes) throws SQLException {
        String hash = sha256Hex(bytes);
        String sql = "INSERT INTO assets (uploader_id, display_name, file_hash, mime_type, byte_size, bytes) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, uploaderId);
            ps.setString(2, displayName);
            ps.setString(3, hash);
            ps.setString(4, mimeType);
            ps.setInt(5, bytes.length);
            ps.setBytes(6, bytes);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) throw new SQLException("Asset insert returned no id");
                Asset a = new Asset();
                a.setId(rs.getLong(1));
                a.setUploaderId(uploaderId);
                a.setDisplayName(displayName);
                a.setFileHash(hash);
                a.setMimeType(mimeType);
                a.setByteSize(bytes.length);
                return a;
            }
        }
    }

    public List<Asset> listAll() throws SQLException {
        String sql = "SELECT id, uploader_id, display_name, file_hash, mime_type, byte_size, created_at "
                + "FROM assets ORDER BY created_at DESC";
        List<Asset> out = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(mapMetadata(rs));
        }
        return out;
    }

    public Asset findMetadata(long id) throws SQLException {
        String sql = "SELECT id, uploader_id, display_name, file_hash, mime_type, byte_size, created_at "
                + "FROM assets WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapMetadata(rs);
            }
        }
        return null;
    }

    public byte[] readBytes(long id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT bytes FROM assets WHERE id = ?")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBytes("bytes");
            }
        }
        return null;
    }

    public boolean delete(long id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM assets WHERE id = ?")) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    private Asset mapMetadata(ResultSet rs) throws SQLException {
        Asset a = new Asset();
        a.setId(rs.getLong("id"));
        a.setUploaderId(rs.getLong("uploader_id"));
        a.setDisplayName(rs.getString("display_name"));
        a.setFileHash(rs.getString("file_hash"));
        a.setMimeType(rs.getString("mime_type"));
        a.setByteSize(rs.getInt("byte_size"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        return a;
    }

    private static String sha256Hex(byte[] bytes) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
