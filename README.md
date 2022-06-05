# docker-librebooking

## Introduction
This project implements the [librebooking](https://github.com/effgarces/BookedScheduler) web application as a container.

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
