This project implements the [librebooking](https://github.com/effgarces/BookedScheduler) web application as a container.

# How to build the image
## Builder: on your local host, Image: on your local host, Platform: single
Run the following commands:
   ```
   LB_RELEASE=2.8.5 # or any other librebooking release
   docker buildx build \
     --tag librebooking:${LB_RELEASE} \
     --build-arg LB_RELEASE=${LB_RELEASE} \
     --output type=docker \
     .
   ```

## Builder: on your local host, Image: on a registry, Platform: multiple
Run the following commands:
   ```
   LB_RELEASE=2.8.5 # or any other librebooking release
   REGISTRY_USER=colisee # or any other user
   docker login
   docker run --privileged tonistiigi/binfmt -install all
   docker buildx build \
     --tag ${REGISTRY_USER}/librebooking:${LB_RELEASE} \
     --build-arg LB_RELEASE=${LB_RELEASE} \
     --output type=registry \
     --platform=linux/amd64,linux/arm64,linux/arm/v7  \
     .
   ```

## Builder: on github, Image: on a registry, Platform: multiple
1. Run the github action `Docker`
1. Specify the librebooking release
=======
## Install instructions
1. Copy the [compose.yaml](https://raw.githubusercontent.com/colisee/docker-librebooking/master/compose.yaml) on your host 
1. Create the following 3 text files in the same directory as file `compose.yaml` :
   ```Shell
   echo "password_for_database_root_user" > db_root_pwd.txt
   echo "password_for_database_application_user" > db_user_pwd.txt
   echo "password_for_application_installation" > lb_install_pwd.txt
   ```
1. Start the application:
   ```Shell
   docker compose up --detach
   ```
1. Point your web browser to http://your_host:8080/Web/install:
   - Enter the installation password
   - Enter the database root user: root
   - Enter the database root password
   - Select "Create the database"
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator. The email must be **admin@example.com**
   - Click on the button `Register`

## Running instructions
1. Point your web browser to http://your_host:8080
1. Login with your application administrator profile
1. Configure the web application
