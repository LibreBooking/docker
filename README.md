# What is librebooking
[Librebooking](https://github.com/librebooking/app) is a simple powerful scheduling solution for any organization, forked from [Booked](https://www.bookedscheduler.com/).

# Project goal
This project implements the librebooking web application as a docker image.

The image contains the apache web server and the librebooking application files. It needs to be linked to a MariaDB database container.

# Upgrade to version 2 of the docker images
Version 1 of the docker images exposed the container directory `/var/www/html`. This resulted in:
- Storing the application files in a docker volume or a local directory on the host
- A complex upgrade procedure
- Longer container startup time

From version 2, the docker images expose the container directory `/config`. This implies:
- To store the application configuration file `config.php` only
- A simple upgrade procedure
- A faster container startup time

Docker images are tagged as follows:

librebooking/librebooking:\<*application-version*\>-\<**docker-image-version**\>

Examples:
- image v1: librebooking/librebooking:2.8.6-`1.2.3`
- image v2: librebooking/librebooking:2.8.6-`2.0`

To upgrade from a version-1 docker image to a version-2 docker image, you just need to:
1. Replace the v1-docker image with the corresponding v2
1. Change the mapping from /var/www/html to `/config`

On first run, all the application files will be moved to the folder `/config/archive` on your host docker volume/host local directory and the file `config.php` will be moved to `/config` on your host docker volume/host local directory. You can delete the `config/archive` folder later on.

# Table of contents
1. [Get or build the docker image](BUILD.md)
1. [Run the docker container](RUN.md)
1. [Setup the application](SETUP.md)
