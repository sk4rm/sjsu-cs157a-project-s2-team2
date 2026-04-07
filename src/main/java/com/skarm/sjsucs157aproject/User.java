package com.skarm.sjsucs157aproject;

public class User {
    private long userId;
    private String displayName;
    private String username;
    private String passwordHash;
    private double heightMeter;

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

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public double getHeightMeter() {
        return heightMeter;
    }

    public void setHeightMeter(double heightMeter) {
        this.heightMeter = heightMeter;
    }


}

