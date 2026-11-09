#!/bin/bash
set -e

# Runtime root-path substitution for reverse-proxy sub-path deployments.
#
# The frontend is built once with a sentinel prefix (/__WEBUI_ROOT_PATH__)
# baked into /app/build. At container start we replace that sentinel with the
# real WEBUI_ROOT_PATH, so the deployment path is chosen at runtime (via env)
# without a rebuild. An empty WEBUI_ROOT_PATH (or "/") serves at the root and
# strips the sentinel entirely.
#
# The backend reads WEBUI_ROOT_PATH directly (see open_webui/env.py +
# PathPrefixStripMiddleware), so only the built frontend assets need rewriting.

SENTINEL="/__WEBUI_ROOT_PATH__"
ROOT_PATH="${WEBUI_ROOT_PATH:-}"

# Normalize: leading slash, no trailing slash. Empty or "/" => root (no prefix).
if [ "$ROOT_PATH" = "/" ] || [ -z "$ROOT_PATH" ]; then
    REPLACEMENT=""
else
    REPLACEMENT="${ROOT_PATH#/}"     # strip leading slash
    REPLACEMENT="${REPLACEMENT%/}"   # strip trailing slash
    REPLACEMENT="/${REPLACEMENT}"    # re-add exactly one leading slash
fi

if grep -rq "$SENTINEL" /app/build/ 2>/dev/null; then
    echo "=== Replacing sentinel root path with: ${REPLACEMENT:-(root)} ==="
    find /app/build -type f \( -name '*.html' -o -name '*.js' -o -name '*.json' \) -exec sed -i "s|${SENTINEL}|${REPLACEMENT}|g" {} +
    echo "=== Done ==="
else
    echo "=== No sentinel root path found in /app/build/ (already replaced or not present) ==="
fi

exec "$@"
