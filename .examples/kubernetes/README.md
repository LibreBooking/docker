# Running LibreBooking in Kubernetes

This is kubernetes configuration for LibreBooking. It is tested on OpenShift
and it's smaller version microshift. OpenShift is kubernetes distribution, so
the very same setup applies to any kubernetes except the ingress route might
differ depending on your ingress.

## Create kube objects for the following

Use `kubectl create -f`  for the following yaml files. You can either edit all
the below examples into one file, or have them separate and apply each
separately.

### Configuration

Take the config-dist.php and copy it into below file. Follow LB instructions
for setting the options.

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: librebooking
  name: librebooking
  namespace: librebooking
data:
  config: |
    <?php
    return [
        'settings' => [

            ##########################
            # Application configuration
            ##########################

            # The public name of the application
            # ... copy this from config-dist.php and indent it like here.
```

### Storage

This saves uploads. For some reason favicon and logo are stored elsewhere. I
override the logos from configMap in my setup.

```yaml
---
apiVersion: v1
kind: List
metadata: {}
items:
- apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    annotations:
    name: images
    namespace: librebooking
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 100Mi
- apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    annotations:
    name: reservation
    namespace: librebooking
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 100Mi
```

### Service

Here you can define the load-balancing options.

```yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: librebooking
  name: librebooking
  namespace: librebooking
spec:
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: librebooking
  type: ClusterIP
```

### Ingress

#### OpenShift Route

This uses the OpenShift default ingress router.

```yaml
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: librebooking
  namespace: librebooking
spec:
  host: librebooking.apps.myocp.mynet
  port:
    targetPort: 80
  to:
    kind: Service
    name: librebooking
    weight: 100
  wildcardPolicy: None
```

#### Ingress controller

If using generic ingress, it would be something like this:

```yaml
---
piVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: librebooking
  namespace: librebooking
  annotations:
    # define your ingress controller here:
    kubernetes.io/ingress.class: "openshift-default"
spec:
  rules:
  - host: librebooking.example.com  # Replace with your cluster's domain
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: librebooking
              port:
                number: 80

```

### Deployment

Here we launch the container. It maps the config.php from the above config map.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
  name: librebooking
  namespace: librebooking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: librebooking
  template:
    metadata:
      annotations:
      labels:
        app: librebooking
    spec:
      containers:
      - name: librebooking-app
        env:
        - name: LB_SCRIPT_URL
          value: https://librebooking.example.com/Web
        - name: VIRTUAL_HOST
          value: librebooking.example.com
        image: docker.io/librebooking/librebooking:develop
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          protocol: TCP
        volumeMounts:
        - mountPath: /config
          name: config
        - mountPath: /var/www/html/Web/uploads/images
          name: images
        - mountPath: /var/www/html/Web/uploads/reservation
          name: reservation
        - mountPath: /var/www/html/config/config.dist.php
          name: librebooking
          subPath: config
      restartPolicy: Always
      volumes:
      - name: config
        persistentVolumeClaim:
          claimName: config
      - name: images
        persistentVolumeClaim:
          claimName: images
      - name: reservation
        persistentVolumeClaim:
          claimName: reservation
      - configMap:
          defaultMode: 420
          name: librebooking
        name: librebooking
```
