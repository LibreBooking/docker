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
- To store the application configuration files only
- A simple upgrade procedure
- A faster container startup time

Docker images are tagged as follows:

librebooking/librebooking:\<*application-version*\>-\<**image-version**\>

Examples:
- image v1: librebooking/librebooking:2.8.5.5-`1.2.3`
- image v2: librebooking/librebooking:2.8.5.5-`2.3.2`

To upgrade from a version-1 docker image to a version-2 docker image, you need to:
1. Stop your running librebooking-V1 instance
1. Edit your `docker-compose.yml` file to replace the:
   1. v1-docker image with the corresponding v2
	 1. container mapped folder `/var/www/html` with `/config`
1. Start your librebooking-V2 instance

On first run:
- The former content of your librebooking volume will be moved to the folder `archive`
- The librebooking configuration files will be copied under the root of the librebooking volume and linked to the application container folder

# Table of contents
1. [Get or build the docker image](BUILD.md)
1. [Run the docker container](RUN.md)
1. [Setup the application](SETUP.md)
