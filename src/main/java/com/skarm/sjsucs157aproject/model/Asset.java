package com.skarm.sjsucs157aproject.model;

import java.sql.Timestamp;

public class Asset {
    private long id;
    private long uploaderId;
    private String displayName;
    private String fileHash;
    private String mimeType;
    private int byteSize;
    private Timestamp createdAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public long getUploaderId() { return uploaderId; }
    public void setUploaderId(long uploaderId) { this.uploaderId = uploaderId; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getFileHash() { return fileHash; }
    public void setFileHash(String fileHash) { this.fileHash = fileHash; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public int getByteSize() { return byteSize; }
    public void setByteSize(int byteSize) { this.byteSize = byteSize; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
