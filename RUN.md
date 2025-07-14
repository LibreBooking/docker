# Run the docker container

The image contains the apache web server and the librebooking application files.
It needs to be linked to a MariaDB database container.

## Environment variables

The following environment variables are used when the file `/config/config.php` **does not exist**:

| Env | Default | Example | Required | config.php settings |
| - | - | - | - | - |
| `LB_DB_NAME` | - | librebooking | **Yes** | `['settings']['database']['name']` |
| `LB_DB_USER` | - | lb_user | **Yes** | `['settings']['database']['user']` |
| `LB_DB_USER_PWD` | - | myPassw0rd | **Yes** | `['settings']['database']['password']` |
| `LB_ENV` | production | dev | **No** | N/A - Used to initialize file config.php |

The following environment variables are **always** used:

| Env | Default | Example | Required | config.php settings |
| - | - | - | - | - |
| `LB_DB_HOST` | - | lb-db | **Yes** | `['settings']['database']['hostspec']` |
| `LB_INSTALL_PWD` | - | installPWD | **Yes** | `['settings']['install.password']` |
| `TZ` | - | Europe/Zurich | **Yes** | `['settings']['default.timezone']` |
| `LB_LOG_FOLDER` | /var/log/librebooking | | **No** | `['settings']['logging']['folder']` |
| `LB_LOG_LEVEL` | none | debug | **No** | `['settings']['logging']['level']` |
| `LB_LOG_SQL` | false | true | **No** | `['settings']['logging']['sql']` |
| `LB_PATH` | - | book | **No** | N/A - URL path prefix (usually none) |
| `LB_CRON_ENABLED` | false | true | **No** | N/A - Enable cron background jobs |

## Optional mounts

If you need to persist some librebooking directories beyond the container lifecycle, you need to bind-mount the required directories. For instance:

* Images directory: `/var/www/html/Web/uploads/images`
* Reservation attachments directory: `/var/www/html/Web/uploads/reservation`

If you need to customize some files, you can bind-mount them as well. For instance:

* favicon: `/var/www/html/Web/favicon.ico`

## Run a development instance: using the command line interface

This simple setup is meant for testing the application within your private network.

1. Create the container network

   ```sh
   docker network create mynet
   ```

1. Run the database

   ```sh
   docker run \
     --name librebooking-db \
     --detach \
     --network mynet \
     --volume librebooking-db:/config \
     --env PUID=1000 \
     --env PGID=1000 \
     --env TZ=Europe/Zurich \
     --env MYSQL_ROOT_PASSWORD=your_Mariadb_root_password \
     linuxserver/mariadb:10.6.13
   ```

1. Run librebooking

   ```sh
   docker run \
     --name librebooking \
     --detach \
     --network mynet \
     --publish 80:80 \
     --volume librebooking-conf:/config \
     --env LB_DB_NAME=librebooking \
     --env LB_DB_USER=lb_user \
     --env LB_DB_USER_PWD=your_Mariadb_user_password \
     --env LB_DB_HOST=librebooking-db \
     --env LB_INSTALL_PWD=your_Librebooking_installation_password \
     --env LB_ENV=dev \
     --env LB_LOG_FOLDER=/var/log/librebooking \
     --env LB_LOG_LEVEL=debug \
     --env LB_LOG_SQL=false \
     --env TZ=Europe/Zurich \
    librebooking/librebooking:develop
   ```

## Run a development instance: using compose

This simple setup is meant for testing the application within your private network.

1. Create a `docker-compose.yml` file from the following sample and adapt the
value of the environment variables to your needs:

   ```yaml
   name: librebooking

   services:
     db:
       image: linuxserver/mariadb:10.6.13
       restart: always
       volumes:
         - db_conf:/config
       environment:
         - PUID=1000
         - PGID=1000
         - TZ=Europe/Zurich
         - MYSQL_ROOT_PASSWORD=your_Mariadb_root_password
     app:
       image: librebooking/librebooking:develop
       restart: always
       depends_on:
         - db
       ports:
         - "80:80"
       volumes:
         - app_conf:/config
       environment: 
         - LB_DB_NAME=librebooking
         - LB_DB_USER=lb_user
         - LB_DB_USER_PWD=your_Mariadb_user_password
         - LB_DB_HOST=db
         - LB_INSTALL_PWD=your_Librebooking_installation_password
         - LB_ENV=dev
         - LB_LOG_FOLDER=/var/log/librebooking
         - LB_LOG_LEVEL=debug
         - LB_LOG_SQL=false
         - LB_CRON_ENABLED=false
         - TZ=Europe/Zurich

   volumes:
     db_conf:
     app_conf:
   ```

1. Start the application with the following command:

   ```sh
   docker-compose up --detach 
   ```

## Run a production instance: using compose

This setup is meant for accessing the application from the internet. It features:

* A reverse proxy based on nginx that automatically handle certificates
* The usage of secrets to pass passwords to the docker container
* A librebooking service `lb1` accessible with a URL-path (ex: <https://your-host.com/book>)
* A librebooking service `lb2` accessible without a URL-path
(ex: <https://your-host.com>)
* 2 bind-mounts to persist images and reservation attachments for service `lb2`

1. Create a `docker-compose.yml` file from the following sample and adapt the value of the environment variables to your needs:

   ```yaml
   name: librebooking

   services:
     proxy:
     image: nginxproxy/nginx-proxy
     restart: always
     networks:
       - mynet
     ports:
       - 80:80
       - 443:443
     volumes:
       - proxy_certs:/etc/nginx/certs
       - proxy_html:/usr/share/nginx/html
       - /var/run/docker.sock:/tmp/docker.sock:ro
     acme:
       image: nginxproxy/acme-companion
       restart: always
       depends_on:
         - proxy
       volumes_from:
         - proxy
       volumes:
         - acme_acme:/etc/acme.sh
         - /var/run/docker.sock:/var/run/docker.sock:ro
       environment:
         - DEFAULT_EMAIL=your_email
     db:
       image: linuxserver/mariadb:10.6.13
       restart: always
       volumes:
         - db_conf:/config
       environment:
         - PUID=1000
         - PGID=1000
         - TZ=Europe/Zurich
         - FILE__MYSQL_ROOT_PASSWORD=/run/secrets/db_root_pwd
       secrets:
         - db_root_pwd
         - db_user_pwd
     lb1:
       image: librebooking/librebooking:2.8.6.2
       restart: always
       depends_on:
         - db
       volumes:
         - lb1_conf:/config
       environment:
         - LB_DB_NAME=lb1
         - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
         - LB_DB_USER=lb1
         - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
         - LB_DB_HOST=db
         - LB_ENV=production
         - LB_LOG_FOLDER=/var/log/librebooking
         - LB_LOG_LEVEL=error
         - LB_LOG_SQL=false
         - LB_PATH=lb1
         - LB_CRON_ENABLED=true
         - TZ=Europe/Zurich
         - VIRTUAL_HOST=your_host_com
         - VIRTUAL_PATH=/your_path
         - LETSENCRYPT_HOST=your_host_com
       secrets:
         - lb_install_pwd
         - lb_user_pwd
     lb2:
       image: librebooking/librebooking:2.8.6.2
       restart: always
       depends_on:
         - db
       volumes:
         - lb2_conf:/config
         - ./uploads/images:/var/www/html/Web/uploads/images
         - ./uploads/reservation:/var/www/html/Web/uploads/reservation
       environment:
         - LB_DB_NAME=lb2
         - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
         - LB_DB_USER=lb2
         - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
         - LB_DB_HOST=db
         - LB_ENV=production
         - LB_LOG_FOLDER=/var/log/librebooking
         - LB_LOG_LEVEL=error
         - LB_LOG_SQL=false
         - LB_CRON_ENABLED=true
         - TZ=Europe/Zurich
         - VIRTUAL_HOST=your_host_com
         - LETSENCRYPT_HOST=your_host_com
       secrets:
         - lb_install_pwd
         - lb_user_pwd

   volumes:
     proxy_certs:
     proxy_html:
     acme_acme:
     db_conf:
     lb1_conf:
     lb2_conf:

   secrets:
     db_root_pwd:
       file: ./pwd_db_root.txt
     db_user_pwd:
       file: ./pwd_db_user.txt
     lb_user_pwd:
       file: ./pwd_db_user.txt
     lb_install_pwd:
       file: ./pwd_lb_inst.txt
   ```

1. Set the secrets with the following commands:

   ```sh
   echo -n 'your_Mariadb_root_password'              > pwd_db_root.txt;
   echo -n 'your_Mariadb_user_password'              > pwd_db_user.txt;
   echo -n 'your_Librebooking_installation_password' > pwd_lb_inst.txt;
   ```

1. Start the application with the following command:

   ```sh
   docker-compose up --detach 
   ```

## Cron jobs

Several services in librebooking such as reminder emails require a cron. For a full list of background jobs checkout the [wiki](https://github.com/LibreBooking/app/wiki/Background-jobs)

This can either be handled by the:

* Container itself, by setting the environment variable

    ```sh
    LB_CRON_ENABLED=true
    ```

* Host running the container, by calling the desired script, as in

  ```sh
  docker exec --detach <container_name> php -f /var/www/html/Jobs/sendreminders.php`
  ```
