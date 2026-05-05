package com.skarm.sjsucs157aproject.model;

import java.sql.Timestamp;

public class Comment {
    private long id;
    private long commenterId;
    private String commenterDisplayName;
    private long objectId;
    private Timestamp createdAt;
    private String textContent;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getCommenterId() {
        return commenterId;
    }

    public void setCommenterId(long commenterId) {
        this.commenterId = commenterId;
    }

    public String getCommenterDisplayName() {
        return commenterDisplayName;
    }

    public void setCommenterDisplayName(String commenterDisplayName) {
        this.commenterDisplayName = commenterDisplayName;
    }

    public long getObjectId() {
        return objectId;
    }

    public void setObjectId(long objectId) {
        this.objectId = objectId;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public String getTextContent() {
        return textContent;
    }

    public void setTextContent(String textContent) {
        this.textContent = textContent;
    }
}
