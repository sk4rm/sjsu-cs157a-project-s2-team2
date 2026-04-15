-- run once on existing warp db: mysql -u ... warp < schemas/migration_add_ar_anchor.sql
USE `warp`;

ALTER TABLE `virtual_objects`
    ADD COLUMN `ar_x` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world x where user dropped',
    ADD COLUMN `ar_y` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world y',
    ADD COLUMN `ar_z` DOUBLE NULL DEFAULT NULL COMMENT 'a-frame world z',
    ADD COLUMN `ar_yaw_deg` DOUBLE NULL DEFAULT NULL COMMENT 'degrees around Y so sign faces placer';
