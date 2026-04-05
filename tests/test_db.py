"""
pytest equivalent of test-db.sh
Tests the MariaDB container used by LibreBooking.
"""
import subprocess
import pytest

CONTAINER = "db"
MYSQL_ROOT_PASSWORD = "devpass"
MYSQL_USER = "lbuser"
MYSQL_PASSWORD = "lbtest"
MYSQL_DATABASE = "librebooking"


def podman(*args, **kwargs):
    return subprocess.run(
        ["podman", *args],
        capture_output=True,
        text=True,
        **kwargs,
    )


def mariadb(user, password, *sql_args):
    return podman(
        "exec", CONTAINER,
        "mariadb", "-h", "127.0.0.1",
        "-u", user, f"-p{password}",
        *sql_args,
        "-e", "SELECT 1;",
    )


# ── 1. Container running ──────────────────────────────────────────────────────

def test_container_is_running():
    result = podman("inspect", CONTAINER, "--format", "{{.State.Running}}")
    assert result.returncode == 0, f"podman inspect failed: {result.stderr}"
    assert "true" in result.stdout, f"Container '{CONTAINER}' is not running"


# ── 2. Port 3306 listening ────────────────────────────────────────────────────

@pytest.mark.dependency(depends=["test_container_is_running"])
def test_port_3306_listening():
    result = podman(
        "exec", CONTAINER,
        "bash", "-c", "cat /dev/null > /dev/tcp/127.0.0.1/3306",
    )
    assert result.returncode == 0, "Port 3306 is not listening inside the container"


# ── 3. Root login ─────────────────────────────────────────────────────────────

@pytest.mark.dependency(depends=["test_container_is_running"])
def test_root_login():
    result = mariadb("root", MYSQL_ROOT_PASSWORD)
    assert result.returncode == 0, f"Root login failed (password: {MYSQL_ROOT_PASSWORD})"


# ── 4. App user login ─────────────────────────────────────────────────────────

@pytest.mark.dependency(depends=["test_container_is_running"])
def test_app_user_login():
    result = mariadb(MYSQL_USER, MYSQL_PASSWORD)
    assert result.returncode == 0, f"User '{MYSQL_USER}' login failed"


# ── 5. App user can access the database ──────────────────────────────────────

@pytest.mark.dependency(depends=["test_app_user_login"])
def test_app_user_can_access_database():
    result = mariadb(MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE)
    assert result.returncode == 0, (
        f"User '{MYSQL_USER}' cannot access database '{MYSQL_DATABASE}'"
    )
