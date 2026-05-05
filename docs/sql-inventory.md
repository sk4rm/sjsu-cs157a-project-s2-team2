# SQL Inventory

All SQL queries the application sends to MySQL at runtime, collected outside
the `schemas/` directory (which holds DDL dumps and the optional
`migration_add_ar_anchor.sql`).

Each entry shows the file, method, and the exact prepared-statement string
sent to MySQL. Multi-line Java string concatenations are joined into the
single-line form the JDBC driver actually receives.

## `src/main/java/com/skarm/sjsucs157aproject/dao/UserDao.java`

- `findByUsername`
  ```sql
  SELECT id, display_name, username, password_hash, height_meter
  FROM user_accounts
  WHERE username = ?
  ```
- `findById`
  ```sql
  SELECT id, display_name, username, password_hash, height_meter
  FROM user_accounts
  WHERE id = ?
  ```
- `createUser`
  ```sql
  INSERT INTO user_accounts (display_name, username, password_hash, height_meter)
  VALUES (?, ?, ?, ?)
  ```
- `updateProfile`
  ```sql
  UPDATE user_accounts
  SET display_name = ?, height_meter = ?
  WHERE id = ?
  ```
- `deleteById` — transactional, runs the following 11 statements in order:
  ```sql
  DELETE FROM virtual_props      WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?);
  DELETE FROM virtual_signposts  WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?);
  DELETE FROM includes           WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?);
  DELETE FROM comments           WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?);
  DELETE FROM votes              WHERE object_id IN (SELECT id FROM virtual_objects WHERE user_id = ?);
  DELETE FROM virtual_objects    WHERE user_id = ?;
  DELETE FROM votes              WHERE voter_id = ?;
  DELETE FROM comments           WHERE commenter_id = ?;
  DELETE FROM object_placements  WHERE user_id = ?;
  DELETE FROM befriends          WHERE user_id_1 = ? OR user_id_2 = ?;
  DELETE FROM user_accounts      WHERE id = ?;
  ```
- `searchByQuery`
  ```sql
  SELECT u.id, u.display_name, u.username,
         (b.user_id_1 IS NOT NULL) AS is_friend
  FROM user_accounts u
  LEFT JOIN befriends b ON (
      (b.user_id_1 = ? AND b.user_id_2 = u.id) OR
      (b.user_id_2 = ? AND b.user_id_1 = u.id)
  )
  WHERE u.id <> ?
    AND (u.username LIKE ? OR u.display_name LIKE ?)
  ORDER BY u.display_name
  LIMIT ?
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/FriendDao.java`

- `findFriendsOf`
  ```sql
  SELECT u.id, u.display_name, u.username, u.height_meter
  FROM user_accounts u
  JOIN befriends b ON (
      (b.user_id_1 = ? AND b.user_id_2 = u.id) OR
      (b.user_id_2 = ? AND b.user_id_1 = u.id)
  )
  ORDER BY u.display_name
  ```
- `areFriends`
  ```sql
  SELECT 1 FROM befriends WHERE user_id_1 = ? AND user_id_2 = ?
  ```
- `addFriend`
  ```sql
  INSERT IGNORE INTO befriends (user_id_1, user_id_2) VALUES (?, ?)
  ```
- `removeFriend`
  ```sql
  DELETE FROM befriends WHERE user_id_1 = ? AND user_id_2 = ?
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/VirtualObjectDao.java`

- `findAll` — UNION across the two subtype tables:
  ```sql
  SELECT v.id, v.user_id,
         ST_X(v.position) AS lng, ST_Y(v.position) AS lat,
         v.rotation, v.scale,
         p.file_hash AS detail, 'prop' AS subtype,
         v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg
  FROM virtual_objects v JOIN virtual_props p ON v.id = p.object_id
  UNION
  SELECT v.id, v.user_id,
         ST_X(v.position) AS lng, ST_Y(v.position) AS lat,
         v.rotation, v.scale,
         s.content AS detail, 'signpost' AS subtype,
         v.ar_x, v.ar_y, v.ar_z, v.ar_yaw_deg
  FROM virtual_objects v JOIN virtual_signposts s ON v.id = s.object_id
  ```
- `findById` — same UNION shape with `WHERE v.id = ?` appended to each branch.
- `createBaseObject`
  ```sql
  INSERT INTO virtual_objects
      (user_id, position, rotation, scale, ar_x, ar_y, ar_z, ar_yaw_deg)
  VALUES (?, ST_PointFromText(?), ?, ?, ?, ?, ?, ?)
  ```
- `create` — followed by one of (depending on subtype):
  ```sql
  INSERT INTO virtual_props     (object_id, file_hash) VALUES (?, ?);
  INSERT INTO virtual_signposts (object_id, content)   VALUES (?, ?);
  ```
- `update` — runs the base statement plus one of the subtype updates:
  ```sql
  UPDATE virtual_objects   SET rotation = ?, scale = ? WHERE id = ?;
  UPDATE virtual_props     SET file_hash = ?           WHERE object_id = ?;
  UPDATE virtual_signposts SET content = ?             WHERE object_id = ?;
  ```
- `delete` — transactional, dependents first:
  ```sql
  DELETE FROM virtual_props     WHERE object_id = ?;
  DELETE FROM virtual_signposts WHERE object_id = ?;
  DELETE FROM includes          WHERE object_id = ?;
  DELETE FROM comments          WHERE object_id = ?;
  DELETE FROM votes             WHERE object_id = ?;
  DELETE FROM virtual_objects   WHERE id = ?;
  ```
- `attachLayerIds` — placeholder count is dynamic, one per object id:
  ```sql
  SELECT object_id, layer_id
  FROM includes
  WHERE object_id IN (?, ?, ...)
  ORDER BY layer_id
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/LayerDao.java`

- `findAll`
  ```sql
  SELECT layer_id, name FROM layers ORDER BY layer_id
  ```
- `create`
  ```sql
  INSERT INTO layers (name) VALUES (?)
  ```
- `rename`
  ```sql
  UPDATE layers SET name = ? WHERE layer_id = ?
  ```
- `addObjectToLayer`
  ```sql
  INSERT IGNORE INTO includes (layer_id, object_id) VALUES (?, ?)
  ```
- `removeObjectFromLayer`
  ```sql
  DELETE FROM includes WHERE layer_id = ? AND object_id = ?
  ```
- `exists`
  ```sql
  SELECT 1 FROM layers WHERE layer_id = ?
  ```
- `delete` — transactional:
  ```sql
  DELETE FROM includes WHERE layer_id = ?;
  DELETE FROM layers   WHERE layer_id = ?;
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/CommentDao.java`

- Shared SELECT base (the `SELECT_COMMENT_WITH_USER` constant):
  ```sql
  SELECT c.id, c.commenter_id, c.object_id, c.created_at, c.text_content,
         u.display_name AS commenter_display_name
  FROM comments c
  JOIN user_accounts u ON u.id = c.commenter_id
  ```
- `findById` — base + ` WHERE c.id = ?`
- `findByObjectId` — base + ` WHERE c.object_id = ? ORDER BY c.created_at ASC`
- `create`
  ```sql
  INSERT INTO comments (commenter_id, object_id, created_at, text_content)
  VALUES (?, ?, NOW(), ?)
  ```
- `deleteById`
  ```sql
  DELETE FROM comments WHERE id = ?
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/VoteDao.java`

- `tallyForObject`
  ```sql
  SELECT
      COALESCE(SUM(CASE WHEN type =  1 THEN 1 ELSE 0 END), 0) AS up_cnt,
      COALESCE(SUM(CASE WHEN type = -1 THEN 1 ELSE 0 END), 0) AS down_cnt
  FROM votes
  WHERE object_id = ?
  ```
- `findVote`
  ```sql
  SELECT type FROM votes WHERE voter_id = ? AND object_id = ?
  ```
- `upsert`
  ```sql
  INSERT INTO votes (voter_id, object_id, type)
  VALUES (?, ?, ?)
  ON DUPLICATE KEY UPDATE type = VALUES(type)
  ```
- `delete`
  ```sql
  DELETE FROM votes WHERE voter_id = ? AND object_id = ?
  ```

## `src/main/java/com/skarm/sjsucs157aproject/dao/AssetDao.java`

- `create`
  ```sql
  INSERT INTO assets
      (uploader_id, display_name, file_hash, mime_type, byte_size, bytes)
  VALUES (?, ?, ?, ?, ?, ?)
  ```
- `listAll`
  ```sql
  SELECT id, uploader_id, display_name, file_hash, mime_type, byte_size, created_at
  FROM assets
  ORDER BY created_at DESC
  ```
- `findMetadata`
  ```sql
  SELECT id, uploader_id, display_name, file_hash, mime_type, byte_size, created_at
  FROM assets
  WHERE id = ?
  ```
- `readBytes`
  ```sql
  SELECT bytes FROM assets WHERE id = ?
  ```
- `delete`
  ```sql
  DELETE FROM assets WHERE id = ?
  ```

## `src/main/webapp/3-tier-demo.jsp`

Leftover JDBC scaffolding. Connects to a separate `Teoh` database with
hard-coded credentials and is unrelated to the rest of the app. Worth
removing in a future cleanup pass.

- inline statement
  ```sql
  SELECT * FROM Student
  ```

## Counts

- 7 source files contain runtime SQL.
- 50 distinct prepared-statement strings (counting each statement inside a
  transactional batch separately, and counting the `CommentDao` shared base
  twice — once via `findById`, once via `findByObjectId`).
