-- Remove every prop/signpost and related rows. Run against `warp` (see import-warp-schemas.sh).
USE warp;

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM includes;
DELETE FROM comments;
DELETE FROM votes;
DELETE FROM object_placements;
DELETE FROM virtual_props;
DELETE FROM virtual_signposts;
DELETE FROM virtual_objects;
SET FOREIGN_KEY_CHECKS = 1;
