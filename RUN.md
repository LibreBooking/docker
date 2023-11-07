# How to run the docker image
The image contains the apache web server and the librebooking application files. It needs to be linked to a MariaDB database container.

## Environment variables
Environment variables are used on first invocation of the container (when the file config/config.php does not yet exist)

| Env | Default | Example | Required | config.php settings |
| - | - | - | - | - |
| `LB_DB_HOST` | - | lb-db | **Yes** | ['settings']['database']['hostspec'] |
| `LB_DB_NAME` | - | librebooking | **Yes** | ['settings']['database']['name'] |
| `LB_DB_USER` | - | lb_user | **Yes** | ['settings']['database']['user'] |
| `LB_DB_USER_PWD` | - | myPassw0rd | **Yes** | ['settings']['database']['password'] |
| `LB_INSTALL_PWD` | - | installPWD | **Yes** | ['settings']['install.password'] |
| `TZ` | - | Europe/Zurich | **Yes** | ['settings']['default.timezone'] |
| `LB_LOG_FOLDER` | /var/log/librebooking/log | | **No** | ['settings']['logging']['folder'] |
| `LB_LOG_LEVEL` | debug | none | **No** | ['settings']['logging']['level'] |
| `LB_LOG_SQL` | false | true | **No** | ['settings']['logging']['sql'] |
| `LB_ENV` | production | dev | **No** | N/A - Used to initialize file config.php |

## Development environment: using the command line interface
This simple setup is meant for testing the application within your private network.

Run the following commands:
```
# Create the container network
docker network create magnolias

# Run the database
docker run \
  --name librebooking-db \
  --detach \
  --network magnolias \
  --volume librebooking-db:/config \
  --env PUID=1000 \
  --env PGID=1000 \
  --env TZ=Europe/Zurich \
  --env MYSQL_DATABASE=librebooking \
  --env MYSQL_ROOT_PASSWORD=your_Mariadb_root_password \
  --env MYSQL_USER=lb_user \
  --env MYSQL_PASSWORD=your_Mariadb_user_password \
  linuxserver/mariadb:10.6.13

# Run librebooking
docker run \
  --name librebooking \
  --detach \
  --network magnolias \
  --publish 80:80 \
  --volume librebooking-conf:/config \
  --env TZ=Europe/Zurich \
  --env LB_DB_HOST=librebooking-db \
  --env LB_DB_NAME=librebooking \
  --env LB_INSTALL_PWD=your_Librebooking_installation_password \
  --env LB_DB_USER=lb_user \
  --env LB_DB_USER_PWD=your_Mariadb_user_password \
  --env LB_ENV=dev \
  librebooking/librebooking:develop
```

## Development environment: using docker compose
This simple setup is meant for testing the application within your private network.

Create a `docker-compose.yml` file from the following sample and adapt the value of the environment variables to your needs:
```
version: "3.7"

services:
  db:
    image: linuxserver/mariadb:10.6.13
    container_name: librebooking-db
    restart: always
    networks:
      - net
    volumes:
      - vol-db:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Zurich
      - MYSQL_DATABASE=librebooking
      - MYSQL_ROOT_PASSWORD=your_Mariadb_root_password
      - MYSQL_USER=lb_user
      - MYSQL_PASSWORD=your_Mariadb_user_password
  app:
    image: librebooking/librebooking:develop
    container_name: librebooking
    restart: always
    depends_on:
      - db
    networks:
      - net
    ports:
      - "80:80"
    volumes:
      - vol-app:/config
    environment: 
      - TZ=Europe/Zurich
      - LB_DB_HOST=db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD=your_Librebooking_installation_password
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD=your_Mariadb_user_password
      - LB_ENV=dev

volumes:
  vol-db:
    name: librebooking_data
  vol-app:
    name: librebooking_conf

networks:
  net:
    name: librebooking
```

Start the application with the following command:
```
docker-compose up --detach 
```

## Production environment: using docker compose
This setup is meant for accessing the application from the internet. It features:
- The [traefik reverse proxy](https://traefik.io/traefik/) 
- The usage of secrets to pass passwords to the docker container

Create a `docker-compose.yml` file from the following sample and adapt the value of the environment variables to your needs:

```
version: "3.7"

services:
  rproxy:
    image: traefik:2.10
    container_name: traefik
    restart: always
    networks:
      net:
    ports:
      - 80:80
      - 443:443
      - 8080:8080
    command:
      - "--api.insecure=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=webs"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.webs.address=:443"
      - "--certificatesresolvers.myresolver.acme.email=your@email"
      - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
    volumes:
      - "vol-rproxy:/etc/traefik/acme"
      - "/var/run/docker.sock:/var/run/docker.sock"
  db:
    image: linuxserver/mariadb:10.6.13
    container_name: librebooking-db
    restart: always
    depends_on:
      - proxy
      - acme
    networks:
      - net
    volumes:
      - vol-db:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Zurich
      - MYSQL_DATABASE=librebooking
      - FILE__MYSQL_ROOT_PASSWORD=/run/secrets/db_root_pwd
      - MYSQL_USER=lb_user
      - FILE__MYSQL_PASSWORD=/run/secrets/db_user_pwd
    secrets:
      - db_root_pwd
      - db_user_pwd
  app:
    image: librebooking/librebooking:2.8.6.1
    container_name: librebooking
    restart: always
    depends_on:
      - db
    networks:
      - net
    volumes:
      - vol-app:/config
    environment: 
      - TZ=Europe/Zurich
      - LB_DB_HOST=db
      - LB_DB_NAME=librebooking
      - LB_INSTALL_PWD_FILE=/run/secrets/lb_install_pwd
      - LB_DB_USER=lb_user
      - LB_DB_USER_PWD_FILE=/run/secrets/lb_user_pwd
      - LB_ENV=production
    secrets:
      - lb_install_pwd
      - lb_user_pwd
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.librebooking.rule=Host(`www.domain.com`)"
      - "traefik.http.routers.librebooking.tls.certresolver=myresolver"
      - "traefik.http.services.librebooking.loadbalancer.server.port=80"

volumes:
  vol-rproxy:
    name: traefik_certs
  vol-db:
    name: librebooking_data
  vol-app:
    name: librebooking_conf

networks:
  net:
    name: librebooking

secrets:
  db_root_pwd:
    file: ./db_root_pwd.txt
  db_user_pwd:
    file: ./db_user_pwd.txt
  lb_user_pwd:
    file: ./db_user_pwd.txt
  lb_install_pwd:
    file: ./lb_install_pwd.txt
```

Set the secrets with the following commands:
```
echo -n 'your_Mariadb_root_password' > db_root_pwd.txt;
echo -n 'your_Mariadb_user_password' > db_user_pwd.txt;
echo -n 'your_Librebooking_installation_password' > lb_install_pwd.txt;
```
Start the application with the following command:
```
docker-compose up --detach 
```
