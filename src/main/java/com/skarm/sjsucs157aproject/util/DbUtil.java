package com.skarm.sjsucs157aproject.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

// jdbc hookup — point url/user/pass at your mysql
public class DbUtil {

    // intellij/tomcat env vars override these defaults
    private static final String DB_URL = getEnvOrDefault("DB_URL", "jdbc:mysql://localhost:3306/warp?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC");
    private static final String DB_USER = getEnvOrDefault("DB_USER", "warp_user");
    private static final String DB_PASSWORD = getEnvOrDefault("DB_PASSWORD", "warp_password");

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL JDBC Driver not found in classpath", e);
        }
    }

    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value != null && !value.isBlank()) ? value : defaultValue;
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
    }
}
