#!/usr/bin/env bash
# Import schemas/ into the warp database. Use after: docker compose up -d
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! docker compose ps db --status running --quiet 2>/dev/null | grep -q .; then
  echo "Error: database container is not running. From the project root run:"
  echo "  docker compose up -d"
  exit 1
fi

echo "Waiting for MySQL to accept connections..."
for _ in $(seq 1 60); do
  if docker compose exec -T db mysqladmin ping -h localhost -uroot -pwarp_root_local --silent 2>/dev/null; then
    break
  fi
  sleep 1
done

# Order respects foreign keys between tables
FILES=(
  warp_user_accounts.sql
  warp_layers.sql
  warp_virtual_objects.sql
  warp_virtual_props.sql
  warp_virtual_signposts.sql
  warp_includes.sql
  warp_comments.sql
  warp_votes.sql
  warp_befriends.sql
  warp_object_placements.sql
  warp_assets.sql
)

for f in "${FILES[@]}"; do
  echo "Importing $f ..."
  docker compose exec -T db mysql -uroot -pwarp_root_local < "$ROOT/schemas/$f"
done

# Fresh dumps already include ar_* on virtual_objects; older DBs might not. Apply migration only if missing.
AR_COLS="$(
  docker compose exec -T db mysql -uroot -pwarp_root_local -N -e \
    "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='warp' AND TABLE_NAME='virtual_objects' AND COLUMN_NAME='ar_x'" \
    2>/dev/null || echo 0
)"
AR_COLS="$(echo -n "${AR_COLS}" | tr -d '[:space:]')"
if [[ "${AR_COLS:-0}" == "0" ]]; then
  echo "Applying optional migration migration_add_ar_anchor.sql (virtual_objects missing ar_* columns) ..."
  docker compose exec -T db mysql -uroot -pwarp_root_local < "$ROOT/schemas/migration_add_ar_anchor.sql"
else
  echo "Skipping migration_add_ar_anchor.sql (ar_x already present on virtual_objects)."
fi

echo "Done. You can register at http://localhost:8080/ (with mvn jetty:run)."
