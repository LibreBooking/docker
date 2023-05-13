# How to setup the application

## First-time fresh install

### Database initialization
1. Point your web browser to `http://<YOUR_HOST>/Web/install`
   - Enter the installation password
   - Enter the database root user: `root`
   - Enter the database root password (same as environment variable `LB_DB_USER_PWD`)
   - Select `Create the database`
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator
   - Click on the button `Register`

### Application configuration
1. Point your web browser to http://\<YOUR_HOST\>
1. Login with your application administrator profile
1. Configure the web application

## Upgrade from a previous version
1. Stop the service
   ```
   sudo docker-compose down
   ```
1. Define the From and To versions
   ```
   V_OLD=2.8.5
   V_NEW=2.8.6
   ```
1. Upgrade the application
   ```
   sudo docker run \
     --rm \
     --volume librebooking_html:/var/www/html \
     librebooking/librebooking:${V_NEW} \
     upgrade
   ```
1. Restart the service
   ```
   sed \
     -i docker-compose.yml \
     -e "s/librebooking:${V_OLD}/librebooking:${V_NEW}/g" 
   sudo docker-compose up --detach
   ```
1. Upgrade the application database by pointing your web browser to `http://<YOUR_HOST>/Web/install/configure.php`