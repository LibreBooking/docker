#!/usr/bin/bash

set -eux

# Create the docker network
docker network create mynet

# Start the database container
docker run \
  --detach \
  --name librebooking-db \
  --network mynet \
  --volume librebooking-db:/config \
  --env PUID=1000 \
  --env PGID=1000 \
  --env TZ=Europe/Zurich \
  --env MYSQL_ROOT_PASSWORD=db_root_pwd \
  linuxserver/mariadb:10.6.13

# Start the librabooking app container
docker run \
  --detach \
  --name librebooking-app \
  --network mynet \
  --publish 8080:8080 \
  --volume librebooking-conf:/config \
  --env LB_DATABASE_NAME=librebooking \
  --env LB_DATABASE_USER=lb_user \
  --env LB_DATABASE_PASSWORD=db_user_pwd \
  --env LB_DATABASE_HOSTSPEC=librebooking-db \
  --env LB_INSTALL_PASSWORD=app_install_pwd \
  --env LB_LOGGING_FOLDER=/var/log/librebooking \
  --env LB_LOGGING_LEVEL=DEBUG \
  --env LB_LOGGING_SQL=false \
  --env LB_DEFAULT_TIMEZONE=Europe/Zurich \
 librebooking/librebooking:develop

# Start the Librebooking cron container
 docker run \
  --detach \
  --name librebooking-cron \
  --user root \
  --entrypoint /usr/local/bin/cron.sh \
  --network mynet \
  --volume librebooking-conf:/config \
  --env LB_DATABASE_NAME=librebooking \
  --env LB_DATABASE_USER=lb_user \
  --env LB_DATABASE_PASSWORD=db_user_pwd \
  --env LB_DATABASE_HOSTSPEC=librebooking-db \
  --env LB_LOGGING_FOLDER=/var/log/librebooking \
  --env LB_LOGGING_LEVEL=DEBUG \
  --env LB_LOGGING_SQL=false \
  --env LB_DEFAULT_TIMEZONE=Europe/Zurich \
 librebooking/librebooking:develop
