```page lp session=hello
```

# Stateful App With MySQL Database

Lets connect a database to our [hello app](../1_hello_app/), i.e. we need a Stateful Set.

## Requirements

We require the app from [last chapter](../1_hello_app/):

```bash lp cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/k8s/hello_app
git ls-files # lp: asserts=server.py
git tag
sed -i 's/0.2/0.3/' environ # version now 0.3
source ./environ
# rm the old yaml files from last chapter:
rm -f *.yaml
```

## Server App

First we need a mysql server:

```bash lp timeout=100
( p images | grep mysql | grep 5.7 || p pull docker.io/library/mysql:5.7 )
p run -d -e MYSQL_ROOT_HOST='%' -e MYSQL_ROOT_PASSWORD=secret -e MYSQL_DATABASE=db -p3306:3306 --rm -ti mysql:5.7
```

The app is simple webserver, now with database support plus a real app server framework:

```python lp mode=make_file fn=server.py chmod=755
#!/usr/bin/env python
import os, sys, time, bottle, bottle_mysql, json as j

app = bottle.Bottle()
dbconf = {k: os.environ[k] for k in ('dbuser', 'dbpass', 'dbname', 'dbhost')}
plugin = bottle_mysql.Plugin(**dict(dbconf))
app.install(plugin)

now, die = time.time, sys.exit

@app.route('/initdb')
def initdb(db):
    db.execute('drop TABLE IF EXISTS items')
    db.execute('CREATE TABLE items (name varchar(255), age int)')
    db.execute("INSERT INTO items (name, age) VALUES ('brian', 42)")
    db.execute('show tables')
    row = db.fetchone()
    return {'result': str(row)}


@app.route('/show/<item>')
def show(item, db):
    db.execute('SELECT * from items where name=%s', (item,))
    row = db.fetchone()
    if row:
        return {'result': row}
    return bottle.HTTPError(404, 'Item not found')


@app.route('/env', method='GET')
def env():
    return {'at': now(), 'env': dict(os.environ)}


@app.route('/kill/<ec>')
def kill(ec):
    sys.stderr.close()
    die(int(ec))


if __name__ == '__main__':
    print(f'Starting bottle httpd server')
    bottle.run(app, host='0.0.0.0', port=28001)
```


### Containerize

```docker lp mode=make_file fn=Dockerfile
FROM         python:3.8
MAINTAINER   gk
RUN          mkdir -p /app
# the base image has the mysql C-libs already:
RUN          pip install mysql bottle bottle-mysql
WORKDIR      /app
COPY         server.py /app/server.py
ENV          APP_ENV development
EXPOSE       28001
#            VOLUME ["/app-data"]
CMD          ["python", "server.py"]
```

```bash lp timeout=100
p rmi -f $namespace/$app
p build --quiet -t $app  .
p tag "$app:latest" "$namespace/$app:$ver"
```

### Test


```bash lp timeout=100 fmt=xt_flat
hostip="$(ip addr show |grep 'inet ' | grep -v 127 | head -n 1 | cut -d t -f2 | cut -db -f1 | cut -d'/' -f1 | xargs)"
echo $hostip
p run -d -ti --rm -p 28001:28001 -e dbuser=root -e dbpass=secret -e dbname=db -e dbhost=$hostip $namespace/$app:$ver
( while true; do sleep 1; wget -q http://127.0.0.1:28001/initdb -O - && break; done ) 
wget -q http://127.0.0.1:28001/show/brian -O - | jq . # lp: asserts=brian and result
```

!!! note
    The app container needed to connect to an ip different to 127.0.0.1 (mysql binds to `0.0.0.0` but
    127.0.0.1 within the app container is within its own network namespace).


Cleanup:

```bash lp timeout=10
wget -q http://127.0.0.1:28001/kill/0
( p ps | grep mysqld | cut -d' ' -f1 | xargs podman stop; echo stopped ) # lp: asserts=stopped
```

### Commit

```bash lp 
git commit -am 'feat: mysql connection'
git tag $ver
```

### Push


```bash lp timeout=100 
p login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"
r="docker://$(pass show reg/domain)/docker-internal/$namespace"
p push --quiet --authfile=$fn_reg_auth $namespace/$app:$ver "$r/$app:$ver" && echo success # lp: assert=success
```


## Cloud Deployment

!!! note

    We follow [this][tut] tutorial, modified for our app.

Again we deploy the app using K8s' solely. First a secret "generator", configured for a static one
(but you [could](https://kubernetes.io/docs/concepts/configuration/secret/) have varying ones at every redeploy):

```bash lp
cat <<EOF >./kustomization.yaml
> secretGenerator:
> - name: mysql-pass
>   literals:
>   - password=myk8ssecret
> resources:
>   - mysql-deployment.yaml
>   - hello2-deployment.yaml
> EOF
```



```bash lp
cat <<EOF >./mysql-deployment.yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: hello2-mysql
>   labels:
>     app: hello2
> spec:
>   ports:
>     - port: 3306
>   selector:
>     app: hello2
>     tier: mysql
>   clusterIP: None
> ---
> apiVersion: v1
> kind: PersistentVolumeClaim
> metadata:
>   name: mysql-pv-claim
>   labels:
>     app: hello2
> spec:
>   accessModes:
>     - ReadWriteOnce
>   resources:
>     requests:
>       storage: 5Gi
> ---
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: hello2-mysql
>   labels:
>     app: hello2
> spec:
>   selector:
>     matchLabels:
>       app: hello2
>       tier: mysql
>   strategy:
>     type: Recreate
>   template:
>     metadata:
>       labels:
>         app: hello2
>         tier: mysql
>     spec:
>       containers:
>       - image: mysql:5.7
>         name: mysql
>         args:
>         - "--ignore-db-dir=lost+found"
>         env:
>         - name: MYSQL_ROOT_HOST
>           value: "%" 
>         - name: MYSQL_DATABASE
>           value: "db" 
>         - name: MYSQL_ROOT_PASSWORD
>           valueFrom:
>             secretKeyRef:
>               name: mysql-pass
>               key: password
>         ports:
>         - containerPort: 3306
>           name: mysql
>         volumeMounts:
>         - name: mysql-persistent-storage
>           mountPath: /var/lib/mysql
>       volumes:
>       - name: mysql-persistent-storage
>         persistentVolumeClaim:
>           claimName: mysql-pv-claim
> EOF
```

!!! warning "`ignore-db-dir` start argument"
    
    On ext4 the mysql5.7 images [refuses](https://stackoverflow.com/a/66027830/4583360) to start due to non empty dir otherwise.



```bash lp
cat <<EOF >./hello2-deployment.yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: hello2
>   labels:
>     app: hello2
>     tier: frontend
> spec:
>   type: LoadBalancer
>   ports:
>     - port: 28001
>   selector:
>     app: hello2
>     tier: frontend
> ---
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: hello2
>   labels:
>     app: hello2
> spec:
>   selector:
>     matchLabels:
>       app: hello2
>       tier: frontend
>   strategy:
>     type: Recreate
>   template:
>     metadata:
>       labels:
>         app: hello2
>         tier: frontend
>     spec:
>       imagePullSecrets:
>       - name: regcred
>       containers:
>       - name: hello2
>         image: $(pass show reg/domain)/docker-internal/$namespace/$app:$ver
>         imagePullPolicy: Always
>         env:
>         - name: dbuser
>           value: "root"
>         - name: dbpass
>           valueFrom:
>             secretKeyRef:
>               name: mysql-pass
>               key: password
>         - name: dbhost
>           value: "hello2-mysql"
>         - name: dbname
>           value: "db"
>         ports:
>         - containerPort: 28001
>           name: hello2
>         resources:
>           requests:
>             cpu: 100m
>             memory: 100Mi
> EOF
```

Now we apply all, with the -k switch, for the kustomize.yaml:

```bash lp timeout=10
kubectl apply -k ./
```

then wait for the loadbalancer and fetch the public IP:

```bash lp timeout=600 fmt=xt_flat
time while true; do sleep 2; k get service hello2 | grep pending >/dev/null || break; done # lp: timeout=600
k -o json get service hello2 | jq .
ip=$(k -o json get service hello2 | jq -r .status.loadBalancer.ingress[0].ip)
```

All environ settings are in the app container:


```bash lp fmt=xt_flat
wget -q http://$ip:28001/env -O - | jq .
```

And the app works:

```bash lp fmt=xt_flat lock_page
wget -q http://$ip:28001/initdb -O - | jq .
wget -q http://$ip:28001/show/brian -O - | jq . # lp: asserts="brian and result"
```

Delete everything:

```bash lp fmt=xt_flat timeout=50 skip_this
kubectl delete -k ./. # lp: asserts="deployment.apps and deleted"
```


## Discussion

- The loadbalancer creation is the time limiting factor at re-deploys from scratch, took often around 4-5 minutes.

    !!! tip
        For CI/CD I'd therefore would keep the loadbalancer standing and just update the app.

- In order to debug, `kubectl get pods` -> `kubectl logs --follow <podname>` was indispensable.
- `kubectl delete -k ./.` did always work nicely, removing all, in the right order. 
- K8s's name resolution is simple: The app could simply connect to the dbhost by `name` attribute of
  the corresponding service deployment.
- On DO (and I guess on other infra providers as well) they use their internal volume creation means
  as default K8s "storage class", i.e. when volumes are to be created for Stateful Sets.  Those
  volumes will survive node failure, [unlike][tut] the `hostPath` based storage class, being set as
  default on local test clusters (e.g. minicube).   

    | DO Dashboard|  K8s Dashboard |
    |-|- |
    | [![](img/stocl1.png)](img/stocl1.png) | [![](img/stocl2.png)](img/stocl2.png) |


[tut]: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/
