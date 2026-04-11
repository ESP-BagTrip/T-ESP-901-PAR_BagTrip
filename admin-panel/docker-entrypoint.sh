#!/bin/sh
set -e

MARKER="/app/node_modules/.lockfile-checksum"
CURRENT_CHECKSUM=$(md5sum /app/package-lock.json | cut -d ' ' -f1)

needs_install=false

# 1) node_modules missing or empty (volume just created)
if [ ! -d /app/node_modules ] || [ ! -d /app/node_modules/next ]; then
  needs_install=true
# 2) checksum marker missing or outdated (package-lock.json changed on host)
elif [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "$CURRENT_CHECKSUM" ]; then
  needs_install=true
fi

if [ "$needs_install" = true ]; then
  echo "[entrypoint] node_modules out of sync — running npm ci..."
  npm ci
  echo "$CURRENT_CHECKSUM" > "$MARKER"
fi

exec "$@"
