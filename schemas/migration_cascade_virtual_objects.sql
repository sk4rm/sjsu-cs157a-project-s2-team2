-- Migrate existing warp DBs so the four FKs that point at virtual_objects.id
-- cascade on delete. Without this, MySQL Workbench (and any raw
-- DELETE FROM virtual_objects ...) hits ERROR 1451 because the dependent
-- comments / includes / virtual_props / virtual_signposts rows still exist.
--
-- Run once: mysql ... warp < schemas/migration_cascade_virtual_objects.sql
-- Re-running will fail at the first DROP FOREIGN KEY because the constraint
-- name will no longer match — that's fine, it just means the migration
-- already happened.
USE `warp`;

ALTER TABLE `comments`
    DROP FOREIGN KEY `fk_virtual_objects_comments`,
    ADD CONSTRAINT `fk_virtual_objects_comments`
        FOREIGN KEY (`object_id`) REFERENCES `virtual_objects` (`id`) ON DELETE CASCADE;

ALTER TABLE `includes`
    DROP FOREIGN KEY `fk_virtual_objects_includes`,
    ADD CONSTRAINT `fk_virtual_objects_includes`
        FOREIGN KEY (`object_id`) REFERENCES `virtual_objects` (`id`) ON DELETE CASCADE;

ALTER TABLE `virtual_props`
    DROP FOREIGN KEY `fk_virtual_objects_virtual_props`,
    ADD CONSTRAINT `fk_virtual_objects_virtual_props`
        FOREIGN KEY (`object_id`) REFERENCES `virtual_objects` (`id`) ON DELETE CASCADE;

ALTER TABLE `virtual_signposts`
    DROP FOREIGN KEY `fk_virtual_objects_virtual_signposts`,
    ADD CONSTRAINT `fk_virtual_objects_virtual_signposts`
        FOREIGN KEY (`object_id`) REFERENCES `virtual_objects` (`id`) ON DELETE CASCADE;
