#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[PASS]${RESET} $*"; ((++PASS)); }
fail() { echo -e "${RED}[FAIL]${RESET} $*"; ((++FAIL)); }

# Credentials from quadlets/db.container
CONTAINER=db
MYSQL_ROOT_PASSWORD=devpass
MYSQL_USER=lbuser
MYSQL_PASSWORD=lbtest
MYSQL_DATABASE=librebooking

# ── 1. Container running ──────────────────────────────────────────────────────
echo "=== 1. Container running ==="
if podman inspect "$CONTAINER" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    ok "Container '$CONTAINER' is running"
else
    fail "Container '$CONTAINER' is NOT running (start it first)"
    exit 1
fi

# ── 2. Port 3306 listening ────────────────────────────────────────────────────
echo ""
echo "=== 2. Port 3306 listening ==="
if podman exec "$CONTAINER" bash -c 'cat /dev/null > /dev/tcp/127.0.0.1/3306' 2>/dev/null; then
    ok "Port 3306 is listening"
else
    fail "Port 3306 is NOT listening"
fi

# ── 3. Root login ─────────────────────────────────────────────────────────────
echo ""
echo "=== 3. Root login ==="
if podman exec "$CONTAINER" mariadb -h 127.0.0.1 -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" &>/dev/null; then
    ok "Root login succeeded"
else
    fail "Root login FAILED (password: $MYSQL_ROOT_PASSWORD)"
fi

# ── 4. App user login ─────────────────────────────────────────────────────────
echo ""
echo "=== 4. App user login ==="
if podman exec "$CONTAINER" mariadb -h 127.0.0.1 -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" &>/dev/null; then
    ok "User '$MYSQL_USER' login succeeded"
else
    fail "User '$MYSQL_USER' login FAILED"
fi

# ── 5. App user can access the database ──────────────────────────────────────
echo ""
echo "=== 5. App user can access '$MYSQL_DATABASE' ==="
if podman exec "$CONTAINER" mariadb -h 127.0.0.1 -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1;" &>/dev/null; then
    ok "User '$MYSQL_USER' can access database '$MYSQL_DATABASE'"
else
    fail "User '$MYSQL_USER' cannot access database '$MYSQL_DATABASE'"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Result: ${PASS} passed, ${FAIL} failed ==="
[[ $FAIL -eq 0 ]]
