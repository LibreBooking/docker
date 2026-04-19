# Run LibreBooking with Podman Quadlets (production)

This setup is meant for running the application in production using rootless Podman managed by systemd.
It features:

* A locally built image from the `Dockerfile` at the project root
* A librebooking container reachable at <http://localhost:8080>
* A dedicated cron container running background jobs via `supercronic`
* A MariaDB database container
* Persistent volumes for the database, images, and reservation attachments
* All services managed by systemd user units (auto-restart, boot start)

## Prerequisites

* Podman 4.4 or later (quadlet support)
* `loginctl enable-linger $USER` — required for user units to survive logout

## Configure

Adapt `librebooking.env` to your environment before starting:

| Variable | Description |
| -------- | ----------- |
| `LB_DATABASE_PASSWORD` | Database user password |
| `LB_INSTALL_PASSWORD` | LibreBooking installation password |
| `LB_DEFAULT_TIMEZONE` | Timezone (e.g. `Europe/London`) |
| `LB_LOGGING_LEVEL` | `none`, `DEBUG`, or `ERROR` |

## Start

Builds the image, installs the quadlet files into `~/.config/containers/systemd/`, and starts all services:

```sh
./scripts/start
```

## Stop

Stops all services and removes the quadlet unit files:

```sh
./scripts/stop
```

## Restart

Runs stop then start (rebuilds the image):

```sh
./scripts/restart
```


## Logs

```sh
journalctl --user -u app -f
journalctl --user -u cron -f
journalctl --user -u db -f
```

## Status

```sh
systemctl --user status app db cron
```