# Run the docker container

The image contains the apache web server and the librebooking application files.
It needs to be linked to a running MariaDB database container.

## Environment variables

From version-3, this docker image makes full usage of the
[environment variables override](https://github.com/LibreBooking/app/blob/develop/docs/source/BASIC-CONFIGURATION.rst).

### Required variables

| Variable | Defaults | Description |
| -------- | -------- | ----------- |
| LB_DATABASE_NAME | | Database name |
| LB_DATABASE_USER | | Database user |
| LB_DATABASE_PASSWORD | | Database password |
| LB_DATABASE_HOSTSPEC | | Database network address |
| LB_INSTALL_PASSWORD | | Librebooking installation password |
| LB_DEFAULT_TIMEZONE | | Timezone |
| LB_LOGGING_FOLDER | `/var/log/librebooking` | Logs folder |
| LB_LOGGING_LEVEL | `none` | Logging level |
| LB_LOGGING_SQL | `false` | SQL logging |

### Optional variables

| Variable | Description |
| -------- | ----------- |
| APP_PATH | URL path    |

## Optional mounts

If you need to persist some librebooking directories beyond the container
lifecycle, you need to bind-mount the required directories. For instance:

* Images directory: `/var/www/html/Web/uploads/images`
* Reservation attachments directory: `/var/www/html/Web/uploads/reservation`

If you need to customize some files, you can bind-mount them as well.
For instance:

* favicon: `/var/www/html/Web/favicon.ico`

## Backround jobs

Several services in librebooking such as reminder emails require a job
scheduler. For a full list of background jobs, checkout the
[wiki](https://github.com/LibreBooking/app/wiki/Background-jobs)

The background jobs can either be handled by the:

* Container itself, by running a separate `librebooking/librebooking` container
where the:

  * user is set to `root`
  * entrypoint is set to `cron.sh`

* Host running the container, by calling the desired script, as in

  ```sh
  docker exec \
    --detach \
    <container_name> \
    php -f /var/www/html/Jobs/sendreminders.php`
  ```

Based on the value of the environment variable `LB_LOGGING_LEVEL`, the
background jobs will output to the `app.log` file inside the log
folder defined by the environment variable `LB_LOGGING_FOLDER`.

## Examples of running librebooking

Examples are provided inside directory `.examples`