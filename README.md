# What is librebooking
[Librebooking](https://github.com/effgarces/BookedScheduler) is a simply powerful scheduling solution for any organization, forked from [Booked](https://www.bookedscheduler.com/).

# Docker image
This image is designed to be used in a micro-service environment. It contains the apache web server and exposes port 80. But it needs to be linked to a MariaDB database container.

## Environment variables

| Env | Default | Example | Required | Description |
| - | - | - | - | - |
| `LB_DB_HOST` | - | `lb-db` | Yes | Sets the value of ['settings']['database']['hostspec'] in config.php |
| `LB_DB_NAME` | - | `librebooking` | Yes | Sets the value of ['settings']['database']['name'] in config.php |
| `LB_DB_USER` | - | `lb_user` | Yes | Sets the value of ['settings']['database']['user'] in config.php |
| `LB_DB_USER_PWD` | - | `myPassw0rd` | Yes | Sets the value of ['settings']['database']['password'] in config.php |
| `LB_INSTALL_PWD` | - | `installPWD` | Yes | Sets the value of ['settings']['install.password'] in config.php |

## docker-compose: simple setup
This setup features volumes in order to keep your data persistent and is meant to run behind an existing reverse proxy.

Create a `docker-compose.yml` file from the following sample and adapt it to your needs and standards:
```
version: "3.7"

services:
  db:
    image: linuxserver/mariadb
    container_name: librebooking-db
    restart: always
    networks:
      - net
    volumes:
      - vol-db:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD=
  app:
    image: colisee/librebooking
    container_name: librebooking
    restart: always
    depends_on:
      - db
    networks:
      - net
    ports:
      - "8080:80"
    volumes:
      - vol-app:/var/www/html
    environment: 
      - TZ=
      - LB_DB_HOST=lb-db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD=
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD=

volumes:
  vol-db:
    name: librebooking-db_data
  vol-app:
    name: librebooking_html

networks:
  net:
    name: librebooking
```

Then run the following command:
```
docker-compose up --detach 
```

## docker-compose: simple setup with docker secrets
As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. The following setup is also meant to be run behind an existing reverse proxy.

Create a `docker-compose.yml` file from the following sample and adapt it to your needs and standards:

```
version: "3.7"

services:
  db:
    image: linuxserver/mariadb
    container_name: librebooking-db
    restart: always
    networks:
      - net
    volumes:
      - vol-db:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=
      - MYSQL_DATABASE=librebooking
      - FILE__MYSQL_ROOT_PASSWORD=/run/secrets/db_root_pwd
      - MYSQL_USER=lb_user
      - FILE__MYSQL_PASSWORD=/run/secrets/db_user_pwd
    secrets:
      - db_root_pwd
      - db_user_pwd
  app:
    image: colisee/librebooking
    container_name: librebooking
    restart: always
    depends_on:
      - db
    networks:
      - net
    ports:
      - "8080:80"
    volumes:
      - vol-app:/var/www/html
    environment: 
      - TZ=
      - LB_DB_HOST=lb-db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
    secrets:
      - lb_install_pwd
      - lb_user_pwd

volumes:
  vol-db:
    name: librebooking-db_data
  vol-app:
    name: librebooking_html

networks:
  net:
    name: librebooking

secrets:
  db_root_pwd:
    file: ./db_root_pwd.txt   # put the MariaDB root password in this file
  db_user_pwd:
    file: ./db_user_pwd.txt   # put the MariaDB user password in this file
  lb_user_pwd:
    file: ./db_user_pwd.txt
  lb_install_pwd:
    file: ./lb_install_pwd.txt   # put the app installation password in this file
```

Then run the following commands:
```
echo 'your_Mariadb_root_password' > db_root_pwd.txt;
echo 'your_Mariadb_user_password' > db_user_pwd.txt;
echo 'your_Librebooking_installation_password' > lb_install_pwd.txt;
docker-compose up --detach
```

## docker-compose: complete setup with reverse proxy
This setup is an extension of the simple setup and includes the [automated nginx reverse proxy](https://github.com/nginx-proxy/nginx-proxy) with its [automated letsencrypt companion](https://github.com/nginx-proxy/acme-companion). This setup can be adapted to handle Docker secrets as well.

Create a `docker-compose.yml` file from the following sample and adapt it to your needs and standards:

```
version: "3.7"

services:
  proxy:
    image: nginxproxy/nginx-proxy
    container_name: librebooking-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - vol_certs:/etc/nginx/certs
      - vol_vhost:/etc/nginx/vhost.d
      - vol_html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - net
  acme:
    image: nginxproxy/acme-companion
    container_name: librebooking-acme
    networks:
      - net
    volumes_from:
      - proxy
    volumes:
      - vol_acme:/etc/acme.sh
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - DEFAULT_EMAIL=
  db:
    image: linuxserver/mariadb
    container_name: librebooking-db
    restart: always
    depends_on:
      - proxy
      - acme
    networks:
      - net
    volumes:
      - vol-db:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD=
  app:
    image: colisee/librebooking
    container_name: librebooking
    restart: always
    depends_on:
      - db
    networks:
      - net
    volumes:
      - vol-app:/var/www/html
    environment: 
      - TZ=
      - LB_DB_HOST=lb-db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD=
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD=
      - VIRTUALHOST=
      - LETSENCRYPT_HOST=

volumes:
  vol-certs:
    name: librebooking-proxy_certs
  vol-vhosts:
    name: librebooking-proxy_vhosts
  vol-html:
    name: librebooking-proxy_html
  vol-acme:
    name: librebooking-acme_acme
  vol-db:
    name: librebooking-db_data
  vol-app:
    name: librebooking_html

networks:
  net:
    name: librebooking
```

Then run the following command:
```
docker-compose up --detach 
```

# Application setup
## Database initialization
1. Point your web browser to http://localhost:8080/Web/install:
   - Enter the installation password
   - Enter the database root user: root
   - Enter the database root password
   - Select "Create the database"
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator. The email must be **admin@example.com**
   - Click on the button `Register`

## Application configuration
1. Point your web browser to http://localhost:8080
1. Login with your application administrator profile
1. Configure the web application

# Quick reference
- [Sources](https://github.com/colisee/docker-librebooking)
- [Build](https://github.com/colisee/docker-librebooking/BUILD.md)
