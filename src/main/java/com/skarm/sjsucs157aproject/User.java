package com.skarm.sjsucs157aproject;

public class User {
    private long userId;
    private String displayName;
    private String email;
    private String passwordHash;
    private double heightMeters;
    private String role; // e.g. GUEST, USER, MODERATOR

    public long getUserId() {
        return userId;
    }

    public void setUserId(long userId) {
        this.userId = userId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public double getHeightMeters() {
        return heightMeters;
    }

    public void setHeightMeters(double heightMeters) {
        this.heightMeters = heightMeters;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}

