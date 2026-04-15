package com.skarm.sjsucs157aproject.model;

public class VirtualObject {
    private long id;
    private long userId;
    private double latitude;
    private double longitude;
    private String rotation = "0,0,0,1"; // Match DB default (quaternion)
    private double scale = 1.0;
    /** optional: scene pose when dropped (persists stationary layout) */
    private Double arX;
    private Double arY;
    private Double arZ;
    private Double arYawDeg;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getUserId() {
        return userId;
    }

    public void setUserId(long userId) {
        this.userId = userId;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public String getRotation() {
        return rotation;
    }

    public void setRotation(String rotation) {
        this.rotation = rotation;
    }

    public double getScale() {
        return scale;
    }

    public void setScale(double scale) {
        this.scale = scale;
    }

    public Double getArX() {
        return arX;
    }

    public void setArX(Double arX) {
        this.arX = arX;
    }

    public Double getArY() {
        return arY;
    }

    public void setArY(Double arY) {
        this.arY = arY;
    }

    public Double getArZ() {
        return arZ;
    }

    public void setArZ(Double arZ) {
        this.arZ = arZ;
    }

    public Double getArYawDeg() {
        return arYawDeg;
    }

    public void setArYawDeg(Double arYawDeg) {
        this.arYawDeg = arYawDeg;
    }
}
