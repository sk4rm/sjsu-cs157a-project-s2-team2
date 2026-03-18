-- WARP initial schema for MySQL
-- Adjust database name / user / password to match DbUtil.java configuration.

CREATE TABLE IF NOT EXISTS UserAccounts (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    display_name VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash CHAR(64) NOT NULL,
    height_meters DOUBLE NOT NULL,
    role VARCHAR(16) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Additional tables for virtual objects, signposts, votes, etc. will be added in later milestones.
-- This keeps the first iteration focused on authentication and account management.

