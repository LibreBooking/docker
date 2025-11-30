# Testing Librebooking as a container

This setup is meant for accessing the application from your local network.
It features:

* A librebooking container reachable at <http://localhost>
* A docker volume
* A cron container

## Using the command line

Start the application
```sh
bash start.sh
```

Stop the application
```sh
bash stop.sh
```

Delete the application containers
```sh
docker container rm librebooking-db librebooking-app
```

Delete the application docker volumes
```sh
docker volume rm librebooking-db librebooking-conf
```
## Using docker-compose.yml

Customize the environment variables inside files `db.env` and `lb.env`

Start the application
```sh
docker compose up --detach
```

Stop the application and delete the containers
```sh
docker compose down
```

Remove the application docker volumes
```sh
docker compose down --volumes
```