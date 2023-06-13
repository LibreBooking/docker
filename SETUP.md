# How to setup the application

## First-time fresh install

### Database initialization
1. Point your web browser to `http://<YOUR_HOST>/Web/install`
   - Enter the installation password (docker variable `LB_INSTALL_PWD`)
   - Enter the database root user: `root`
   - Enter the database root password (docker variable `LB_DB_USER_PWD`)
   - Select `Create the database`
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator
   - Click on the button `Register`

### Application configuration
1. Point your web browser to `http://<YOUR_HOST>`
1. Login with your application administrator profile
1. Configure the web application

## Upgrade from a previous application version
1. Stop the service
   ```
   sudo docker-compose down
   ```
1. Change the `docker-compose.yml` file
   ```
   V_OLD=2.8.5.5
   V_NEW=2.8.6
   sed \
     -i docker-compose.yml \
     -e "s/librebooking:${V_OLD}/librebooking:${V_NEW}/g" 
   ```
1. Restart the service
   ```
   sudo docker-compose up --detach
   ```
1. Upgrade the application database by pointing your web browser to `http://<YOUR_HOST>/Web/install/configure.php`

## Upgrade to docker-image v2 from docker-image v1
1. Stop the service
   ```
   sudo docker-compose down
   ```
1. Change the `docker-compose.yml` file
   ```
   sed \
     -i docker-compose.yml \
     -e "s|\(librebooking/librebooking:.*\)-1.*|\1-2.0|g" \
     -e "s|/var/www/html|/config|g" 
   ```
1. Restart the service
   ```
   sudo docker-compose up --detach
   ```
1. If you didn't customize the `/var/www/html` directory, you can delete the /config/archive folder at your convenience
   ```
   sudo docker exec -t librebooking bash -c 'rm -rf /config/archive'
      ```
