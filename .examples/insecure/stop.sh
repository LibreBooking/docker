#!/usr/bin/bash

set -eux

# Stop the Librebooking cron container
docker stop librebooking-cron

# Start the librabooking app container
docker stop librebooking-app

# Start the database container
docker stop librebooking-db

# Delete the docker network
docker network create mynet
