import subprocess
from pathlib import Path
import pytest
from dotenv import dotenv_values

SERVICE = "db"

_COMPOSE_DIR = Path(__file__).parent.parent / ".examples" / "docker"
_COMPOSE_FILE = _COMPOSE_DIR / "docker-compose-local.yml"

_db_env = dotenv_values(_COMPOSE_DIR / "db.env")
_lb_env = dotenv_values(_COMPOSE_DIR / "lb.env")

MARIADB_ROOT_PASSWORD = _db_env["MYSQL_ROOT_PASSWORD"]
MARIADB_USER = _lb_env["LB_DATABASE_USER"]
MARIADB_PASSWORD = _lb_env["LB_DATABASE_PASSWORD"]
MARIADB_DATABASE = _lb_env["LB_DATABASE_NAME"]

_COMPOSE_CMD = ["docker", "compose", "-f", str(_COMPOSE_FILE)]


def compose(*args, **kwargs):
    return subprocess.run(
        [*_COMPOSE_CMD, *args],
        capture_output=True,
        text=True,
        check=False,
        **kwargs,
    )


def compose_exec(*args, **kwargs):
    return compose("exec", "-T", SERVICE, *args, **kwargs)


def mariadb(user, password, *sql_args):
    return compose_exec(
        "mariadb",
        "-h",
        "127.0.0.1",
        "-u",
        user,
        f"-p{password}",
        *sql_args,
        "-e",
        "SELECT 1;",
    )


# ── 1. Container running ──────────────────────────────────────────────────────
@pytest.mark.dependency()
def test_container_is_running():
    result = compose("ps", "--status", "running", SERVICE)
    assert result.returncode == 0, f"docker compose ps failed: {result.stderr}"
    assert SERVICE in result.stdout, f"Service '{SERVICE}' is not running"


# ── 2. Port 3306 listening ───────────────────────────────────────────────────


@pytest.mark.dependency(depends=["test_container_is_running"])
def test_port_3306_listening():
    result = compose_exec("bash", "-c", "cat /dev/null > /dev/tcp/127.0.0.1/3306")
    assert result.returncode == 0, "Port 3306 is not listening inside the container"


# ── 3. Root login ─────────────────────────────────────────────────────────────


@pytest.mark.dependency(depends=["test_container_is_running"])
def test_root_login():
    result = mariadb("root", MARIADB_ROOT_PASSWORD)
    assert (
        result.returncode == 0
    ), f"Root login failed (exit code: {result.returncode}, stderr: {result.stderr})"


# ── 4. App user login ─────────────────────────────────────────────────────────


@pytest.mark.dependency(depends=["test_container_is_running"])
@pytest.mark.dependency()
def test_app_user_login():
    result = mariadb(MARIADB_USER, MARIADB_PASSWORD)
    assert result.returncode == 0, f"User '{MARIADB_USER}' login failed"


# ── 5. App user can access the database ──────────────────────────────────────


@pytest.mark.dependency(depends=["test_app_user_login"])
def test_app_user_can_access_database():
    result = mariadb(MARIADB_USER, MARIADB_PASSWORD, MARIADB_DATABASE)
    assert (
        result.returncode == 0
    ), f"User '{MARIADB_USER}' cannot access database '{MARIADB_DATABASE}'"
