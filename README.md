# Librebooking

> [!WARNING]
> **Security: upgrade immediately to librebooking images published on
> 2026.10.21 or later.**
>
> Further to php security issues CVE-2026-109618 and CVE-2026-109619,
> Librebooking images were rebuilt with the fixed base image `php:8.5.12-apache` 
>
> All librebooking images published before 2026.10.21 were removed from the
> [docker hub](https://hub.docker.com)

[![Docker pulls](https://img.shields.io/docker/pulls/librebooking/librebooking)](https://github.com/LibreBooking/docker)

## Table of contents

1. [About librebooking](#about-librebooking)
1. [This project goal](#project-goal)
1. [Get or build the docker image](BUILD.md)
1. [Run the docker container](RUN.md)
1. [Set the application up](SETUP.md)


## About Librebooking
[Librebooking](https://github.com/Librebooking/librebooking) is a simple powerful
scheduling solution for any organization, forked from
[Booked](https://www.bookedscheduler.com/).

## Project goal

This project implements the librebooking web application as a container image.

The image contains the apache web server and the librebooking application files.
It needs to be linked to a MariaDB database container.