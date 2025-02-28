You have 2 ways to get the docker image on your host:
1. Getting the image from the docker's hub
1. Building the image yourself

# Getting the image from the docker's hub

This is the easiest and fastest way.
```
# Stable release
docker image pull librebooking/librebooking:2.8.6.2

# Development branch
docker image pull librebooking/librebooking:develop
```

# Building the image

You have 3 ways to build the docker image.

Regardless of the chosen option, you need to clone this repository:
```
git clone https://github.com/librebooking/docker
```

## Option-1

| Item     | Value                  |
| ---      | ---                    |
| Builder  | On your host           |
| Image    | On your host           |
| Platform | your host architecture |

Run the following commands on your host:
   ```
   # Set the application release (ex: develop or 2.8.6.2)
   LB_RELEASE=develop
   if [ "${LB_RELEASE}" == "develop" ]; then
     APP_GH_REF="refs/heads/${LB_RELEASE}"
   else
     APP_GH_REF="refs/tags/${LB_RELEASE}"
   fi

   # Build the docker image
   docker buildx build \
     --build-arg PHP_VERSION=8 \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --tag librebooking/librebooking:${LB_RELEASE} \
     --output type=docker \
     .
   ```

## Option-2

| Item     | Value                                |
| ---      | ---                                  |
| Builder  | On your host                         |
| Image    | On hub.docker.com                    |
| Platform | linux/amd64,linux/arm64,linux/arm/v7 |

Run the following commands on your host:
   ```
   # Set the application release (ex: develop or 2.8.6.2)
   LB_RELEASE=develop
   if [ "${LB_RELEASE}" == "develop" ]; then
     APP_GH_REF="refs/heads/${LB_RELEASE}"
   else
     APP_GH_REF="refs/tags/${LB_RELEASE}"
   fi

   # Log to the docker hub
   docker login --username <your_docker_hub_profile>

   # If needed, create a docker-container based build instance
   docker buildx create --driver docker-container --use

   # Build the docker image
   docker buildx build \
     --build-arg PHP_VERSION=8 \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --tag ${REGISTRY_USER}/librebooking:${LB_RELEASE} \
     --output type=registry \
     --platform=linux/amd64,linux/arm64,linux/arm/v7  \
     .
   ```

## Option-3

| Item     | Value                                |
| ---      | ---                                  |
| Builder  | On github.com                        |
| Image    | On hub.docker.com                    |
| Platform | linux/amd64,linux/arm64,linux/arm/v7 |

1. Create a github secret, called `REGISTRY_TOKEN`, to store your registry personal access token
1. Run the github action `Build and publish docker images` from the latest repository tag
1. Click on `Run workflow`. Then click on `Branch: develop` and select instead the latest version tag
1. Specify the librebooking application github reference (ex: refs/tags/2.8.6.2 or refs/heads/develop)
1. Click on the `Run workflow` button
