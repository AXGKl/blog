
```page lp session=hello
```

# A First Hello World Python App Run on K8s

 We create a hello world app, which we containerize, then deploy on k8s.

!!! note

    There are thousands of "better" tutorials regarding how to do this already out there since long.
    But you have to start somewhere and I wanted an automatically[^1] reproducable baseline, for the more
    complex things, we'll eventually address in other tutorials around here.

!!! tip "kubernetes playground"
    
    If you can't install a cloud kubernetes server you can test most of the stuff below using this
    playground: https://labs.play-with-k8s.com/

[^1]: All the code in this tutorial is run by a markdown preprocessor.

First example is stateless:

## Requirements

- Having a [k8s cluster and configured kubectl command](../../terraform/k8s/k8s_on_do.md), with access to our private container image registry.

```bash lp fmt=mk_console
kubectl get nodes
kubectl get secrets
```

- Have the following values present (we use [`pass`](https://www.passwordstore.org/) to retrieve them):

    - `reg/domain`  domain name of your registry
    - `reg/user`    username for your registry
    - `reg/passw`   your registry password


- podman or docker and kubectl. Here we will use podman to build and push a container image.

### Preparation

```bash lp
type kubectl podman # asserts: podman and kubectl
# prepare working directory:
app="hello_app"       # app (container) name
D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s/$app"
mkdir -p "$D" || exit 1
cd "$D"
# Start from scratch
ls -a | xargs rm -rf 2>/dev/null
git init
podman rmi --force $app 2>/dev/null || true
```



## Environ

As usual we create an `environ` file, which sets up our working environ, when sourced - convenient for new shells:

```bash lp mode=make_file fn=environ replace cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/k8s/hello_app
set -ae
alias k=kubectl p=podman

[[ "$0" = *bash* ]] && s=bash || s=zsh
source <(kubectl completion $s)

D="%(cwd)s"
namespace="devapps"                                  # namespace of our app in registry
fn_reg_auth="$XDG_RUNTIME_DIR/containers/auth.json"  # where podman stores creds
app="hello_app"                                    # app (container) name
ver="0.2"
cd "$D"
set +ae
```

```bash lp
source ./environ
```

!!! tip

    === "Automatic Sourcing on `cd`"

        You can tell your shell to automatically source the environ file, when you cd into the folder, by overwritting the builtin cd function.

    === "Recipe"

        In your `.bashrc` or `.zshrc`:

        ```bash
        function cd {
            local m f d="${1:-$HOME}"
            # useful as well: cd into dir when a file is given:
            test -d "$d" || {
                test "$d" != "-" && {
                    f="$d"
                    d="$(dirname "$d")"
                    test -e "$f" && m="Is a file" || m="Not exists"
                    echo -e "\x1b[38;5;245m$m: $f - going to \x1b[0m$d"
                }
            }
            builtin cd "$d"
            test -e "./.cd.rc" && {
                echo -e "\x1b[38;5;245m$(cat "./.cd.rc")\x1b[0m"
                source "./.cd.rc"
            }
            true
        }
        ```
        Now you can add `source environ` into a `.cd.rc` file within the same folder.


## Server App

A simple webserver, returning its process environ to the client and supports getting shut down from
remote:

```python lp mode=make_file fn=server.py chmod=755
#!/usr/bin/env python
import os, sys, time, json as j
from http.server import HTTPServer, BaseHTTPRequestHandler as Handler

now = time.time
die = sys.exit

nfo = lambda: {'at': now(), 'env': dict(os.environ)}
rsp = lambda: j.dumps(nfo(), indent=4, sort_keys=True)


def get(h):
    h.send_response(200)
    h.send_header('Content-type', 'application/json')
    h.end_headers()
    w = lambda s, h=h: h.wfile.write(bytes(s, 'utf-8'))
    w(rsp())
    # we allow the client to stop the server via those URL paths:
    p = h.path.split('?', 1)[0]
    die(0) if p == '/stop' else die(1) if p == '/err' else 0


Handler.do_GET = get

def run(bind='0.0.0.0', port=28001):
    print(f'Starting httpd server on {bind}:{port}')
    HTTPServer((bind, port), Handler).serve_forever()

run() if __name__ == '__main__' else 0
```


### Containerize


```docker lp mode=make_file fn=Dockerfile
FROM         python:3.8
MAINTAINER   gk
RUN          mkdir -p /app
WORKDIR      /app
COPY         server.py /app/server.py
ENV          APP_ENV development
EXPOSE       28001
#            VOLUME ["/app-data"]
CMD          ["python", "server.py"]
```

```bash lp timeout=100
p build --quiet -t $app  .
p tag "$app:latest" "$namespace/$app:$ver"
```

### Test

```bash lp timeout=3
p run -d --rm -p28001:28001 $namespace/$app:$ver
wget --retry-connrefused http://localhost:28001/stop -O - # lp: asserts=PATH
```

### Commit App

```bash lp 
git add server.py Dockerfile environ
git commit -am 'feat: First version of hello world server'
```

### Push to (Private) Registry


```bash lp timeout=100
p login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"
r="docker://$(pass show reg/domain)/docker-internal/$namespace"
p push --quiet --authfile=$fn_reg_auth $namespace/$app:$ver "$r/$app:$ver" && echo success # lp: assert=success
```


## Cloud Deployment

Lets deploy the container using K8s' builtin weapons:

The app is stateless, so we deploy, ...well..., a ["Deployment"](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/):

```bash lp timeout=5
cat << EOF > frontend-deployment.yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: frontend
> spec:
>   replicas: 2
>   selector:
>     matchLabels:
>       app: pyhello
>       tier: frontend
>   template:
>     metadata:
>       labels:
>         app: pyhello
>         tier: frontend
>     spec:
>       imagePullSecrets:
>       - name: regcred
>       containers:
>       - name: py-hello1
>         image: $(pass show reg/domain)/docker-internal/$namespace/$app:$ver
>         imagePullPolicy: Always
>         env:
>         - name: FOO
>           value: "BAR"
>         ports:
>         - containerPort: 28001
>         resources:
>           requests:
>             cpu: 100m
>             memory: 100Mi
> EOF

k apply -f frontend-deployment.yaml
sleep 1
k get pods -l app=pyhello -l tier=frontend

```


```bash lp timeout=5
cat << EOF > frontend-service.yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: frontend
>   labels:
>     app: pyhello
>     tier: frontend
> spec:
>   type: LoadBalancer
>   ports:
>   - port: 28001
>   selector:
>     app: pyhello
>     tier: frontend
> EOF
k apply -f frontend-service.yaml
sleep 1
k get service frontend
```

On DO the loadbalancer needs a minute when you first configure one, on a *new* k8s cluster (`k describe service frontend` shows details).

Let's wait until up:

```bash lp
while true; do sleep 2; k get service frontend | grep pending || break; done # lp: timeout=200
k -o json get service frontend | jq .
ip=$(k -o json get service frontend | jq -r .status.loadBalancer.ingress[0].ip)
```

The pods are up now - we can access the service from the internet via `$ip`.
Loadbalancer distributes requests over pods:

```bash lp fmt=xt_flat
wget -q http://$ip:28001/ -O - | jq .
```

```bash lp  fmt=mk_console
for i in {1..10}; do wget -q http://$ip:28001/ -O - | jq -r .env.HOSTNAME; done | sort | uniq
```

Dashboard says:

[![](img/k8s.png){style="max-width: 300px"}](img/k8s.png)


!!! note "K8s HA"

    === "Crashing the App"

        We can watch K8s respawning pods when we cause the service to crash:

        ```bash lp fmt=mk_console timeout=4
        for i in 1 2; do wget -qt1T1 http://$ip:28001/err -O /dev/null; done
        sleep 2
        k get pods
        ```

    === "Backoff Behaviour"

        When crashing it a few times in a row, K8s reacts reasonably by default:
        ```console
        $ k get pods
        NAME                        READY   STATUS   RESTARTS   AGE
        frontend-67bc4f75c8-26prb   0/1     Error    2          2m54s
        frontend-67bc4f75c8-d57vg   0/1     Error    2          2m54s
        (...)
        NAME                        READY   STATUS             RESTARTS   AGE
        frontend-67bc4f75c8-26prb   0/1     CrashLoopBackOff   2          2m54s
        frontend-67bc4f75c8-d57vg   0/1     CrashLoopBackOff   2          2m54s
        (...)
        NAME                        READY   STATUS    RESTARTS   AGE
        frontend-67bc4f75c8-26prb   1/1     Running   3          3m35s
        frontend-67bc4f75c8-d57vg   1/1     Running   3          3m35s
        ```

Bring it down again:

```bash lp fmt=mk_console timeout=4
k delete -f frontend-service.yaml
k delete -f frontend-deployment.yaml
```




```bash lp lock_page
```


