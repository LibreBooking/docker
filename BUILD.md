# Get or build the docker image

You have 2 ways to get the docker image on your host:

1. Get the image from the docker's hub
1. Build the image

## Get the image from the docker's hub

This is the easiest and fastest way.

- Librebooking release (ex: 7.2.0 as of 2026-11-09):

  ```sh
  docker image pull librebooking/librebooking:7.2.0
  ```

- Librebooking on-going development:

  ```sh
  docker image pull librebooking/librebooking:develop
  ```

## Build the docker image

1. Clone this repository

   ```sh
   git clone https://github.com/librebooking/docker
   ```

1. Run the following commands on your host:

   ```sh
   # Set the application release if needed (ex: v7.2.0)
   APP_GH_REF=v7.2.0
   if [ -z "${APP_GH_REF}" ]; then
     IMG_TAG=develop
     APP_GH_ADD_SHA=true
   else
     IMG_TAG=${APP_GH_REF#v}
     APP_GH_ADD_SHA=false
   fi

   # Build the docker image
   docker build \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --build-arg APP_GH_ADD_SHA=${APP_GH_ADD_SHA} \
     --tag librebooking/librebooking:${IMG_TAG} \
     .
   ```

When `APP_GH_ADD_SHA=true`, the web UI footer appends the LibreBooking app
short SHA to the displayed version string.
