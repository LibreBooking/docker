# Run librebooking with docker

## Using the command line: local access

This setup is meant for accessing the application from your local network.
It features:

* A librebooking container reachable at <http://localhost:8080>
* A docker volume storing the configuration files

Adapt files `db.env`and `lb.env` to your needs

Create a docker network

```sh
docker network create librebooking
```

Start the containers

```sh
docker run \
  --detach \
  --name librebooking-db \
  --network librebooking \
  --volume librebooking-db:/config \
  --env-file db.env \
  linuxserver/mariadb:10.6.13

docker run \
  --detach \
  --name librebooking-app \
  --network librebooking \
  --publish 8080:8080 \
  --volume librebooking-conf:/config \
  --env-file lb.env \
 librebooking/librebooking:4.1.0
```

## Using docker compose: local access

This setup is meant for accessing the application from your local network.
It features:

* A librebooking container reachable at <http://localhost:8080>
* A docker volume storing the configuration files
* A librebooking container used to run cron jobs

Adapt files `db.env`and `lb.env` to your needs

Start the application

```sh
docker compose --file docker-compose-local.yml up --detach
```

## Using docker compose: public access

This setup is meant for accessing the application from the internet.
It features:

* A reverse proxy based on nginx that automatically handle certificates
* A librebooking service `lb1` reachable at <https://your.host.com/book>
* A librebooking service `lb2` reachable at <https://your.host.com>
* 2 librebooking services `job1` and `job2` to handle cron jobs
* The usage of secrets to forward passwords to both containers

Adapt files `db.env`, `lb1.env` and `lb2.env` to your needs

Set the secret files

```sh
echo -n 'db_root_pwd'     > pwd_db_root.txt;
echo -n 'db_user_pwd'     > pwd_db_user.txt;
echo -n 'app_install_pwd' > pwd_lb_inst.txt;
```

Start the application

```sh
docker compose --file docker-compose-public.yml up --detach
```
