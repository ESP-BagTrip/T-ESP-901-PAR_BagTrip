#!/bin/sh
set -e

# If node_modules is stale (package.json changed since image build),
# re-run npm install so the anonymous volume stays in sync.
if [ ! -f /app/node_modules/.package-lock.json ] || \
   ! diff -q /app/package-lock.json /app/node_modules/.package-lock.json > /dev/null 2>&1; then
  echo "[entrypoint] package-lock.json changed — running npm ci..."
  npm ci
fi

exec "$@"
