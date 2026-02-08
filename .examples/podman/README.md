# Run LibreBooking with Podman

## Using the command line: local access (testing)

This setup is meant for accessing the application from your local network.
It features:

* A librebooking container reachable at <http://localhost:8080>
* A persistent storage for the database and librebooking configuration files

Adapt files `db.env`and `lb.env` to your needs

Create a container network

```sh
podman network create librebooking
```

Start the containers

```sh
podman container run \
  --name librebooking-db \
  --detach \
  --replace \
  --network librebooking \
  --hostname db \
  --volume librebooking-db_conf:/config:U \
  --env-file db.env \
  docker.io/linuxserver/mariadb:10.6.13

podman run \
  --name librebooking-app \
  --detach \
  --replace \
  --network librebooking \
  --publish 8080:8080 \
  --volume librebooking-app_conf:/config:U \
  --env-file lb.env \
  docker.io/librebooking/librebooking:develop
```

## Using systemd: local access (production)

This method persists over reboots.
[Automatic updates](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html)
for container images are not enabled in this example. Try it also, it's handy.

## Create network file

```sh
cat >> ~/.config/containers/systemd/librebooking.network<<EOF 
[Unit]
Description=Librebooking Network

[Network]
Subnet=192.168.30.0/24
Gateway=192.168.30.1
Label=app=librebooking
EOF
```

## create volume for DB

```sh
cat >> ~/.config/containers/systemd/mariadb-lb.volume<<EOF
[Volume]
Driver=local
Label=app=librebooking
EOF
```

## Create DB container conf

```sh
cat >> ~/.config/containers/systemd/mariadb-lb.container<<EOF
[Unit]
Description=MariaDB container

[Container]
Image=docker.io/linuxserver/mariadb:10.6.13
Environment=MYSQL_ROOT_PASSWORD=db_root_pwd
Environment=MYSQL_USER=lb
Environment=MYSQL_PASSWORD=lb-test
Environment=MYSQL_DATABASE=db
Environment=PUID=1000
Environment=PGID=1000
Volume=mariadb-lb.volume:/config:U
Network=librebooking.network
PublishPort=3306:3306
Label=app=librebooking
# AutoUpdate=registry

[Service]
Restart=on-failure
EOF
```

## Create Images Volume

```sh
cat >> ~/.config/containers/systemd/lb-images.volume<<EOF
[Volume]
Driver=local
Label=app=librebooking
EOF
```

## Create Reservations Volume

```sh
cat >> ~/.config/containers/systemd/lb-reservation.volume<<EOF
[Volume]
Driver=local
Label=app=librebooking
EOF
```

## Create LB container file

```sh
cat >> ~/.config/containers/systemd/lb.container<<EOF
[Unit]
Description=Librebooking container
Requires=mariadb-lb.service
After=mariadb-lb.service
 
[Container]
HostName=librebooking
Image=docker.io/librebooking/librebooking:develop
Network=librebooking.network
Environment=LB_DATABASE_NAME=db
Environment=LB_DATABASE_USER=lb
Environment=LB_DATABASE_PASSWORD=lb-test
Environment=LB_DATABASE_HOSTSPEC=systemd-mariadb-lb
Environment=LB_INSTALL_PASSWORD=installme
Environment=LB_LOGGING_FOLDER=/var/log/librebooking
Environment=LB_LOGGING_LEVEL=DEBUG
Environment=LB_LOGGING_SQL=false
Environment=LB_DEFAULT_TIMEZONE=Europe/Helsinki
PublishPort=8080:8080
Label=app=librebooking
Volume=lb-images.volume:/var/www/html/Web/uploads/images
Volume=lb-reservation.volume:/var/www/html/Web/uploads/reservation
Volume=%h/librebooking-conf:/config:U
# AutoUpdate=registry
# User=1000:1000


[Install]
WantedBy=multi-user.target

[Service]
Restart=on-failure
EOF
```

## Create ports.conf to override apache port

```sh
cat >> ~/lb-ports.conf<<EOF
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 8080

<IfModule ssl_module>
        Listen 8443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 8443
</IfModule>
EOF
```

## Create virtual server conf to override apache port

```sh
cat >> ~/ lb-000-default.conf<<EOF
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
```

## Create permanent conf dir for LB

```sh
mkdir ~/librebooking-conf
```

## Start the services

Now we have all the config files done for systemd. Next we reload the daemon, and start the services:

```sh
systemctl --user daemon-reload
systemctl --user start mariadb-lb
systemctl --user start lb
```

## Enable autostart at boot

To make the systemd start the containers automatically at boot you need to
enable lingering the the user and enable the services:

```sh
sudo loginctl enable-linger $USER
systemctl --user enable --now mariadb-lb
systemctl --user enable --now lb
```

## Logs

If you want to see the logs, you can use `podman logs ...` or use `journalctl --user -u lb`. You can also modify the conf file in ~/librebooking-conf/config.php, and restart the service with `systemctl --user restart lb`.

# Connect to Librebooking

At this point the system is running at http://<hostname>:8080.

*Note: I tested the config on Fedora 43.*
