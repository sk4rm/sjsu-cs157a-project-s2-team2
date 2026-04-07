package com.skarm.sjsucs157aproject;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

// Database connection helper - update DB_URL, DB_USER, and DB_PASSWORD for your MySQL setup
public class DbUtil {

    // Read from environment variables if set, otherwise use default values
    private static final String DB_URL = getEnvOrDefault("DB_URL", "jdbc:mysql://localhost:3306/warp?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC");
    private static final String DB_USER = getEnvOrDefault("DB_USER", "warp_user");
    private static final String DB_PASSWORD = getEnvOrDefault("DB_PASSWORD", "warp_password");

    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value != null && !value.isBlank()) ? value : defaultValue;
    }

    static {
        try {
            // MySQL 8+ driver class name
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL JDBC Driver not found in classpath", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }
}

