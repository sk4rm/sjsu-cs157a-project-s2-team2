-- Optional migration for warp DBs where virtual_objects has no ar_* columns yet.
-- scripts/import-warp-schemas.sh runs this automatically only when ar_x is missing.
-- Manual run (same condition): mysql ... warp < schemas/migration_add_ar_anchor.sql
USE `warp`;

ALTER TABLE `virtual_objects`
    ADD COLUMN `ar_x` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world x where user dropped',
    ADD COLUMN `ar_y` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world y',
    ADD COLUMN `ar_z` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world z',
    ADD COLUMN `ar_yaw_deg` DOUBLE NULL DEFAULT NULL COMMENT 'degrees around Y so sign faces placer';
