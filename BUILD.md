# Get or build the docker image

You have 2 ways to get the docker image on your host:

1. Get the image from the docker's hub
1. Build the image

## Get the image from the docker's hub

This is the easiest and fastest way.

```sh
# Stable release
docker image pull librebooking/librebooking:2.8.6.2

# Development branch
docker image pull librebooking/librebooking:develop
```

## Build the docker image

1. Clone this repository

   ```sh
   git clone https://github.com/librebooking/docker
   ```

1. Run the following commands on your host:

   ```sh
   # Set the application release (ex: develop or 2.8.6.2)
   LB_RELEASE=develop
   if [ "${LB_RELEASE}" == "develop" ]; then
     APP_GH_REF="refs/heads/${LB_RELEASE}"
   else
     APP_GH_REF="refs/tags/${LB_RELEASE}"
   fi

   # Build the docker image
   docker buildx build \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --tag librebooking/librebooking:${LB_RELEASE} \
     --output type=docker \
     .
   ```
