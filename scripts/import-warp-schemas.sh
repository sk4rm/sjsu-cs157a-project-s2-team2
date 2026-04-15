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
)

for f in "${FILES[@]}"; do
  echo "Importing $f ..."
  docker compose exec -T db mysql -uroot -pwarp_root_local < "$ROOT/schemas/$f"
done

echo "Done. You can register at http://localhost:8080/ (with mvn jetty:run)."
