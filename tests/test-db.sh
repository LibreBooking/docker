#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

ok() {
	echo -e "  ${GREEN}[PASS]${RESET} $*"
	((++PASS))
}
fail() {
	echo -e "  ${RED}[FAIL]${RESET} $*"
	((++FAIL))
}

describe() {
	echo ""
	echo "--- $1 ---"
}

it() {
	local title=$1
	shift
	if "$@"; then ok "$title"; else fail "$title"; fi
}

# Credentials from quadlets/db.container
CONTAINER=db
MYSQL_ROOT_PASSWORD=devpass
MYSQL_USER=lbuser
MYSQL_PASSWORD=lbtest
MYSQL_DATABASE=librebooking

# ── 1. Container running ──────────────────────────────────────────────────────
echo ""
echo "=== 1. Container status ==="
if podman inspect "$CONTAINER" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
	ok "Container '$CONTAINER' is running"
else
	fail "Container '$CONTAINER' is NOT running"
fi

container_is_running() {
	podman inspect "$CONTAINER" --format '{{.State.Running}}' 2>/dev/null | grep -q true
}

describe "Container"
it "container '$CONTAINER' is running" podman inspect "$CONTAINER" --format '{{.State.Running}}' 2>/dev/null | grep -q true

# bail early if container isn't up
[[ $FAIL -eq 0 ]] || {
	echo "Aborting: container not running"
	exit 1
}

# ── 2. Port 3306 listening ────────────────────────────────────────────────────
describe "Networking"
it "port 3306 is listening" \
	podman exec "$CONTAINER" bash -c 'cat /dev/null > /dev/tcp/127.0.0.1/3306'

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
