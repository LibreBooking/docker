# Running Librebooking container in production

This setup is meant for accessing the application from the internet.
It features:

* A reverse proxy based on nginx that automatically handle certificates
* The usage of secrets to forward passwords to the docker container
* A librebooking service `lb1` reachable at <https://your.host.com/book>
* A librebooking service `lb2` reachable at <https://your.host.com>
* 2 docker volumes for services `lb1` and `lb2`
* 2 cron jobs for services `lb1` and `lb2`

## Setup

Set the secrets with the following commands:

```sh
echo -n 'db_root_pwd'     > pwd_db_root.txt;
echo -n 'db_user_pwd'     > pwd_db_user.txt;
echo -n 'app_install_pwd' > pwd_lb_inst.txt;
```

## Container management

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