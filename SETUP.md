# How to setup the application

## Fresh install

### Database initialization
1. Point your web browser to http://\<YOUR_HOST\>/Web/install:
   - Enter the installation password
   - Enter the database root user: root
   - Enter the database root password
   - Select `Create the database`
   - Click on the register link, at the bottom of the web page
   - Fill the register form for the application administrator
   - Click on the button `Register`

### Application configuration
1. Point your web browser to http://\<YOUR_HOST\>
1. Login with your application administrator profile
1. Configure the web application

## Upgrade
1. Define the From and To versions
```
V_OLD=2.8.5
V_NEW=2.8.6
```

1. Run the following commands on your host:
```
sudo docker cp librebooking:/var/www/html/config/config.php ./config.php
sudo docker-compose down
sudo docker volume rm librebooking_html
sed -e "s/librebooking:${V_OLD}/librebooking:${V_NEW}/g" -i docker-compose.yml
sudo docker-compose up --detach
sudo docker cp ./config.php librebooking:/var/www/html/config/config.php
sudo docker exec -t librebooking sh -c 'chown www-data:www-data /var/www/html/config/config.php'
```
1. Upgrade the application settings and database by pointing your web browser to `Web/install/configure.php`. You can ignore the thrown exceptions