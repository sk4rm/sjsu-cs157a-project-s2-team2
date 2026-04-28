-- Optional one-time migration for an *existing* warp DB that was created before AR anchor
-- columns existed on virtual_objects. Do NOT run this if your table already has ar_x, etc.
-- (fresh installs: use schemas/warp_virtual_objects.sql only.)
--
-- Example:
--   mysql -h 127.0.0.1 -u warp_user -p warp < schemas/migration_add_ar_anchor.sql
USE `warp`;

ALTER TABLE `virtual_objects`
    ADD COLUMN `ar_x` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world x where user dropped',
    ADD COLUMN `ar_y` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world y',
    ADD COLUMN `ar_z` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world z',
    ADD COLUMN `ar_yaw_deg` DOUBLE NULL DEFAULT NULL COMMENT 'degrees around Y so sign faces placer';
