# Get or build the docker image

You have 2 ways to get the docker image on your host:

1. Get the image from the docker's hub
1. Build the image

## Get the image from the docker's hub

This is the easiest and fastest way.

- Stable branch:

  ```sh
  docker image pull librebooking/librebooking:4.0.0
  ```

- Development branch:

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
   # Set the application release (ex: develop or v4.0.0)
   APP_RELEASE=develop
   if [ "${APP_RELEASE}" == "develop" ]; then
     APP_GH_REF="refs/heads/${APP_RELEASE}"
     APP_GH_ADD_SHA=true
   else
     APP_GH_REF="refs/tags/${APP_RELEASE}"
     APP_GH_ADD_SHA=false
   fi

   # Build the docker image
   docker buildx build \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --build-arg APP_GH_ADD_SHA=${APP_GH_ADD_SHA} \
     --tag librebooking/librebooking:$(echo ${APP_RELEASE} | sed -e "s/^v//") \
     --output type=docker \
     .
   ```

When `APP_GH_ADD_SHA=true`, the web UI footer appends the LibreBooking app
short SHA to the displayed version string.
