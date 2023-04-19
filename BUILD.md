You have 2 ways to get the docker image on your host:
1. Getting the image from the docker's hub
1. Building the image yourself

# How to get the image from the docker's hub

This is the easiest and fastest way.
```
docker image pull librebooking/librebooking
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

Run the following commands:
   ```
   LB_RELEASE=2.8.5 # or any other librebooking release
   docker buildx build \
     --tag librebooking:${LB_RELEASE} \
     --build-arg LB_RELEASE=${LB_RELEASE} \
     --output type=docker \
     .
   ```

## Option-2

| Item | Value |
| --- | --- |
| Builder | On your host |
| Image | On hub.docker.com |
| Platform | linux/amd64,linux/arm64,linux/arm/v7 |

Run the following commands:
   ```
   LB_RELEASE=2.8.5 # or any other librebooking release
   REGISTRY_USER=your_registry_user
   docker login --username ${REGISTRY_USER}
   docker run --privileged tonistiigi/binfmt -install all
   docker buildx build \
     --tag ${REGISTRY_USER}/librebooking:${LB_RELEASE} \
     --build-arg LB_RELEASE=${LB_RELEASE} \
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
1. Run the github action `Docker`
1. Specify the librebooking release
1. If necessary, modify the registry name and login name
1. Seat back and relax
