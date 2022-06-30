# Quick reference
- [Sources](https://github.com/colisee/docker-librebooking)

# What is librebooking
[Librebooking](https://github.com/effgarces/BookedScheduler) is a simply powerful scheduling solution for any organization, forked from [Booked](https://www.bookedscheduler.com/).

# Running this container with a compose file
This image is designed to be used in a micro-service environment. It contains the apache web server and exposes port 80. But it needs to be linked to a MariaDB database container. The easiest way to get a fully featured and functional setup is using a `docker-compose.yml` file. Here are some examples.

## Simple setup
This setup features volumes in order to keep your data persistent and is meant to run behind a proxy.

docker-compose.yml:
```
version: '3.4'

services:
  db:
    image: mariadb
    container_name: librebooking-db
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD=
  web:
    image: colisee/librebooking
    container_name: librebooking-web
    restart: always
    depends_on:
      - db
    links:
      - db
    ports:
      - "8080:80"
    volumes:
      - "web:/var/www/html"
    environment: 
      - TZ=
      - LB_DB_HOST=db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD=
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD=

volumes:
  db:
    name: librebooking-db
  web:
    name: librebooking-web
```

Then run:
```
docker-compose up --detach
```

## Docker secrets
As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. The following setup is also meant to be run behind a proxy.

docker-compose.yml:
```
version: '3.4'

services:
  db:
    image: mariadb
    container_name: librebooking-db
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_pwd
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD_FILE=/run/secrets/db_user_pwd
    secrets:
      - db_root_pwd
      - db_user_pwd
  web:
    image: colisee/librebooking
    container_name: librebooking-web
    restart: always
    depends_on:
      - db
    links:
      - db
    ports:
      - "8080:80"
    volumes:
      - "web:/var/www/html"
    environment: 
      - TZ=Europe/Zurich
      - LB_DB_HOST=db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
    secrets:
      - lb_install_pwd
      - lb_user_pwd

volumes:
  db:
    name: librebooking-db
  web:
    name: librebooking-web

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

Then run:
```
echo "your_Mariadb_root_password" > db_root_pwd.txt;
echo "your_Mariadb_user_password" > db_user_pwd.txt;
echo "your_Librebooking_installation_password" > lb_install_pwd.txt;
docker-compose up --detach
```

## Make Librebooking accessible from the internet
Until here, your Librebooking is just available from your docker host. If you want your Nextcloud available from the internet adding SSL encryption is mandatory.

We recommend using a reverse proxy in front of your Nextcloud installation. Your Librebooking will only be reachable through the proxy, which encrypts all traffic to the clients. You can mount your manually generated certificates to the proxy or use a fully automated solution which generates and renews the certificates for you.

In the following setup we have a fully automated setup using a reverse proxy, a container for Let's Encrypt certificate handling, database and Librebooking. It uses the popular nginx-proxy and docker-letsencrypt-nginx-proxy-companion containers. Please check the according documentations before using this setup.

docker-compose.yml
```
version: '3.4'

services:
  db:
    image: mariadb
    container_name: librebooking-db
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_pwd
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD_FILE=/run/secrets/db_user_pwd
    secrets:
      - db_root_pwd
      - db_user_pwd
  web:
    image: colisee/librebooking
    container_name: librebooking-web
    restart: always
    depends_on:
      - db
    links:
      - db
    ports:
      - "8080:80"
    volumes:
      - "web:/var/www/html"
    environment: 
      - TZ=Europe/Zurich
      - LB_DB_HOST=db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
      - VIRTUAL_HOST=
      - LETSENCRYPT_HOST=
      - LETSENCRYPT_EMAIL=
    secrets:
      - lb_install_pwd
      - lb_user_pwd
  proxy:
    image: nginxproxy/nginx-proxy:alpine
    restart: always
    ports:
      - 80:80
      - 443:443
    labels:
      com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy: "true"
    volumes:
      - certs:/etc/nginx/certs:ro
      - vhost.d:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - proxy-tier
  letsencrypt-companion:
    image: nginxproxy/acme-companion
    restart: always
    volumes:
      - certs:/etc/nginx/certs
      - acme:/etc/acme.sh
      - vhost.d:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy-tier
    depends_on:
      - proxy

volumes:
  db:
    name: librebooking-db
  web:
    name: librebooking-web
  certs:
  acme:
  vhost.d:
  html:

secrets:
  db_root_pwd:
    file: ./db_root_pwd.txt   # put the MariaDB root password in this file
  db_user_pwd:
    file: ./db_user_pwd.txt   # put the MariaDB user password in this file
  lb_user_pwd:
    file: ./db_user_pwd.txt
  lb_install_pwd:
    file: ./lb_install_pwd.txt   # put the app installation password in this file

networks:
  proxy-tier:
```

Then run:
```
echo "your_Mariadb_root_password" > db_root_pwd.txt;
echo "your_Mariadb_user_password" > db_user_pwd.txt;
echo "your_Librebooking_installation_password" > lb_install_pwd.txt;
docker-compose up --detach
```

# Operations
## installation instructions
1. Point your web browser to http://localhost:8080/Web/install:
   - Enter the installation password
   - Enter the database root user: root
   - Enter the database root password
   - Select "Create the database"
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator. The email must be **admin@example.com**
   - Click on the button `Register` to create the admin user

## Running instructions
1. Point your web browser to http://localhost:8080
1. Login with your application administrator profile
1. Configure the web application
