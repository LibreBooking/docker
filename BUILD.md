You have 2 ways to get the docker image on your host:
1. Getting the image from the docker's hub
1. Building the image yourself

# How to get the image from the docker's hub

This is the easiest and fastest way.
```
# Stable release
sudo docker image pull librebooking/librebooking:2.8.6

# Development branch
sudo docker image pull librebooking/librebooking:develop
```

# How to build the image

You have 3 ways to build the docker image.

Regardless of the chosen option, you need to clone this repository:
```
git clone https://github.com/librebooking/docker.git
```

## Option-1

| Item | Value |
| --- | --- |
| Builder | On your host |
| Image | On your host |
| Platform | your host architecture |

Run the following commands on your host:
   ```
   # Stable release
   LB_RELEASE=2.8.6
   APP_GH_REF=refs/tags/${LB_RELEASE}
   sudo docker build \
     --tag librebooking/librebooking:${LB_RELEASE} \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     .

   # Development branch
   LB_RELEASE=develop
   APP_GH_REF=refs/heads/${LB_RELEASE}
   sudo docker build \
     --tag librebooking/librebooking:${LB_RELEASE} \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     .
   ```

## Option-2

| Item | Value |
| --- | --- |
| Builder | On your host |
| Image | On hub.docker.com |
| Platform | linux/amd64,linux/arm64,linux/arm/v7 |

Run the following commands on your host:
   ```
   # Stable release
   LB_RELEASE=2.8.6
   APP_GH_REF=refs/tags/${LB_RELEASE}
   REGISTRY_USER=your_registry_user
   sudo docker login --username ${REGISTRY_USER}
   sudo docker run --privileged tonistiigi/binfmt -install all
   sudo docker buildx build \
     --tag ${REGISTRY_USER}/librebooking:${LB_RELEASE} \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --output type=registry \
     --platform=linux/amd64,linux/arm64,linux/arm/v7  \
     .

   # Development branch
   LB_RELEASE=develop
   APP_GH_REF=refs/heads/${LB_RELEASE}
   REGISTRY_USER=your_registry_user
   sudo docker login --username ${REGISTRY_USER}
   sudo docker run --privileged tonistiigi/binfmt -install all
   sudo docker buildx build \
     --tag ${REGISTRY_USER}/librebooking:${LB_RELEASE} \
     --build-arg APP_GH_REF=${APP_GH_REF} \
     --output type=registry \
     --platform=linux/amd64,linux/arm64,linux/arm/v7  \
     .
   ```

## Option-3

| Item | Value |
| --- | --- |
| Builder | On github.com |
| Image | On hub.docker.com |
| Platform | linux/amd64,linux/arm64,linux/arm/v7 |

1. Create a github secret, called `REGISTRY_TOKEN`, to store your registry personal access token
1. Run the github action `Build and publish docker images` from the latest repository tag
1. Click on `Run workflow`. Then click on `Branch: develop` and select instead the latest version tag
1. Specify the librebooking application github reference (ex: refs/tags/2.8.6 or refs/heads/develop)
1. Click on the `Run workflow` button
