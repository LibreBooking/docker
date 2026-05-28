# Run LibreBooking with Podman

## Using the command line

This example features:

* A librebooking container reachable at <http://localhost:8080>
* A cron container executing scheduled librebooking-related jobs
* A database container hosting the librebooking data
* Persistent volumes storage for the database, librebooking configuration,
uploaded images and reservations

Adapt files `db.env`and `lb.env` to your needs

Create a pod

```sh
podman pod create --publish 8080:8080 librebooking
```

Add the database and librebooking containers to the pod

```sh
podman container create \
  --name librebooking-db \
  --replace \
  --pod librebooking \
  --volume librebooking-db_conf:/config:U \
  --env-file $(pwd)/db.env \
  docker.io/linuxserver/mariadb:10.6.13

podman container create \
  --name librebooking-app \
  --replace \
  --pod librebooking \
  --volume librebooking-app_conf:/config:U \
  --volume librebooking-app_img:/var/www/html/Web/uploads/images:U \
  --volume librebooking-app_res:/var/www/html/Web/uploads/reservation:U \
  --env-file $(pwd)/lb.env \
  docker.io/librebooking/librebooking:develop
```

If desired, add the cron container to the pod

```sh
podman container create \
  --name librebooking-cron \
  --replace \
  --pod librebooking \
  --volumes-from librebooking-app \
  --volume $(pwd)/crontab:/config/lb-jobs-cron:U \
  --env-file $(pwd)/lb.env \
  docker.io/librebooking/librebooking:develop \
  supercronic /config/lb-jobs-cron
```

Start the application and check it works as expected

```sh
podman pod start librebooking
```

Stop the application

```sh
podman pod stop librebooking
```

## Using a pod file

This setup is equivalent to the previous one, except it uses the
`podman kube play` command to run the pod.

From the previous example, generate the pod file

```sh
podman kube generate librebooking --filename librebooking.yml
```

Start the application

```sh
podman kube play librebooking.yml
```

Stop the application

```sh
podman kube down librebooking.yml
```

## Using systemd

This setup is equivalent to the previous one, except it uses the
`systemd` infrastructure to run the pod.

Install the `librebooking.kube` quadlet

```sh
if [ ! $(podman quadlet install librebooking.kube >/dev/null 2>&1) ]; then
  mkdir --parents $HOME/.config/containers/systemd
  cp librebooking.kube $HOME/.config/containers/systemd/
fi
```

From the previous example, generate the pod file inside the drop-in directory

```sh
pushd $HOME/.config/containers/systemd
podman kube generate librebooking --filename librebooking.yml
popd
```
 
Reload the systemd manager configuration

```sh
systemctl --user daemon-reload
```

Start the librebooking systemd service

```sh
systemctl --user start librebooking.service
```

Stop the librebooking systemd service

```sh
systemctl --user stop librebooking.service
```

### Enable autostart at boot

Enable lingering for your user

```sh
sudo loginctl enable-linger $(whoami)
```

Enable and start the librebooking system service

```sh
systemctl --user enable --now librebooking.service
```
