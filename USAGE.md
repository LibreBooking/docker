# What is librebooking
[Librebooking](https://github.com/effgarces/BookedScheduler) is a simply powerful scheduling solution for any organization, forked from [Booked](https://www.bookedscheduler.com/).

# Running this container with a compose file
This image is designed to be used in a micro-service environment. It contains the apache web server and exposes port 80. But it needs to be linked to a MariaDB database container. The easiest way to get a fully featured and functional setup is using a `docker-compose.yml` file. Here are some examples.

## Simple setup
This setup features volumes in order to keep your data persistent and is meant to run behind a proxy.

Create a `docker-compose.yml` file with the following content:
```
version: "3.7"

services:
  db:
    image: linuxserver/mariadb
    container_name: lb-db
    restart: unless-stopped
    volumes:
      - lb-db:/var/lib/mysql
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
    container_name: lb-app
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    volumes:
      - "lb-app:/var/www/html"
    environment: 
      - TZ=
      - LB_DB_HOST=lb-db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD=
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD=

volumes:
  lb-db:
    name: lb-db
  lb-app:
    name: lb-app
```

Then run the following command:
```
docker-compose up --detach 
```

## Docker secrets
As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. The following setup is also meant to be run behind a proxy.

Create a `docker-compose.yml` file with the following content:

```
services:
  db:
    image: linuxserver/mariadb
    container_name: lb-db
    restart: unless-stopped
    volumes:
      - lb-db:/var/lib/mysql
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
    container_name: lb-app
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    volumes:
      - lb-app:/var/www/html
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
  lb-db:
    name: lb-db
  lb-app:
    name: lb-app

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

## installation instructions
1. Point your web browser to http://localhost:8080/Web/install:
   - Enter the installation password
   - Enter the database root user: root
   - Enter the database root password
   - Select "Create the database"
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator. The email must be **admin@example.com**
   - Click on the button `Register`

## Running instructions
1. Point your web browser to http://localhost:8080
1. Login with your application administrator profile
1. Configure the web application

# Quick reference
- [Sources](https://github.com/colisee/docker-librebooking)
