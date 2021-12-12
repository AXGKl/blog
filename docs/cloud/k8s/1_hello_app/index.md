


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

<!-- id: 28213a4ccf9b72ecdcb68e77d4a2396f -->
```bash
$ kubectl get nodes                                       
NAME                 STATUS   ROLES    AGE   VERSION                                
app-pool-849ri       Ready    <none>   28m   v1.21.2                                
app-pool-849rv       Ready    <none>   28m   v1.21.2                                
default-pool-849j0   Ready    <none>   31m   v1.21.2                                
default-pool-849j1   Ready    <none>   32m   v1.21.2
```


```bash
$ kubectl get secrets                                     
NAME                  TYPE                                  DATA   AGE              
default-token-7jjc4   kubernetes.io/service-account-token   3      35m              
regcred               kubernetes.io/dockerconfigjson        1      27m
```
<!-- id: 28213a4ccf9b72ecdcb68e77d4a2396f -->

- Have the following values present (we use [`pass`](https://www.passwordstore.org/) to retrieve them):

    - `reg/domain`  domain name of your registry
    - `reg/user`    username for your registry
    - `reg/passw`   your registry password


- podman or docker and kubectl. Here we will use podman to build and push a container image.

### Preparation

<!-- id: 9a0af911e6c608eecfac473c911a7349 -->

=== "Cmd"
    
    ```console
    $ type kubectl podman # asserts: podman and kubectl
    $ app="hello_app"       # app (container) name
    $ D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s/$app"
    $ mkdir -p "$D" || exit 1
    $ cd "$D"
    $ ls -a | xargs rm -rf 2>/dev/null
    $ git init
    $ podman rmi --force $app 2>/dev/null || true
    ```

=== "Output"

    
    <xterm />
    
        $ type kubectl podman # asserts: podman and kubectl                                 
        kubectl is hashed (/usr/local/bin/kubectl)                                          
        podman is hashed (/usr/bin/podman)        
        $ 
        $ app="hello_app"       # app (container) name                                      
        $ 
        $ D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s/$app"
        $ mkdir -p "$D" || exit 1
        $ cd "$D"
        $ ls -a | xargs rm -rf 2>/dev/null
        $ git init      
        [33mhint: Using 'master' as the name for the initial branch. This default branch name[39m   
        [33mhint: is subject to change. To configure the initial branch name to use in all[39m      
        [33mhint: of your new repositories, which will suppress this warning, call:[39m             
        [33mhint: [39m               
        [33mhint: [39m  [33mgit config --global init.defaultBranch <name>[39m                               
        [33mhint: [39m               
        [33mhint: Names commonly chosen instead of 'master' are 'main', 'trunk' and[39m             
        [33mhint: 'development'. The just-created branch can be renamed via this command:[39m       
        [33mhint: [39m               
        [33mhint: [39m  [33mgit branch -m <name>[39m              
        Initialized empty Git repository in /home/gk/repos/blog/tmp/clusters/DO/k8s/hello_app/.git/
        $ podman rmi --force $app 2>/dev/null || true             
        Untagged: localhost/devapps/hello_app:0.2
    
    


<!-- id: 9a0af911e6c608eecfac473c911a7349 -->



## Environ

As usual we create an `environ` file, which sets up our working environ, when sourced - convenient for new shells:

<!-- id: 37000e0d2e577fc4c44f64b4a81374be -->
```bash
$ cat environ
set -ae
alias k=kubectl p=podman

[[ "$0" = *bash* ]] && s=bash || s=zsh
source <(kubectl completion $s)

D="/home/gk/repos/blog/tmp/clusters/DO/k8s/hello_app"
namespace="devapps"                                  # namespace of our app in registry
fn_reg_auth="$XDG_RUNTIME_DIR/containers/auth.json"  # where podman stores creds
app="hello_app"                                    # app (container) name
ver="0.2"
cd "$D"
set +ae
```
<!-- id: 37000e0d2e577fc4c44f64b4a81374be -->

<!-- id: e9081053b0fef30de850787fcd421f9a -->

=== "Cmd"
    
    ```console
    $ source ./environ
    ```

=== "Output"

    
    <xterm />
    
        $ source ./environ
    
    


<!-- id: e9081053b0fef30de850787fcd421f9a -->

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

<!-- id: 369d0132692c58d99ebe410df2316e8d -->
```python
$ cat server.py
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
<!-- id: 369d0132692c58d99ebe410df2316e8d -->


### Containerize


<!-- id: 133a9fbd70b19d8a3696d925753be51b -->
```docker
$ cat Dockerfile
FROM         docker.io/python:3.8
MAINTAINER   gk
RUN          mkdir -p /app
WORKDIR      /app
COPY         server.py /app/server.py
ENV          APP_ENV development
EXPOSE       28001
CMD          ["python", "server.py"]
```
<!-- id: 133a9fbd70b19d8a3696d925753be51b -->

<!-- id: 607a9bdf55e10c9e70828644c1bf2e2c -->

=== "Cmd"
    
    ```console
    $ p build --quiet -t $app  .
    $ p tag "$app:latest" "$namespace/$app:$ver"
    ```

=== "Output"

    
    <xterm />
    
        $ p build --quiet -t $app  .                              
        084853fe41554ceb4094d20d6f202e23a14be169c1ec252abfd5111be62bc5d9
        $ p tag "$app:latest" "$namespace/$app:$ver"
    
    


<!-- id: 607a9bdf55e10c9e70828644c1bf2e2c -->

### Test

<!-- id: 0d8dd6deed60237d4078723ed9618bee -->

=== "Cmd"
    
    ```console
    $ p run -d --rm -p28001:28001 $namespace/$app:$ver
    $ wget --retry-connrefused http://localhost:28001/stop -O - # lp: asserts=PATH
    ```

=== "Output"

    
    <xterm />
    
        $ p run -d --rm -p28001:28001 $namespace/$app:$ver        
        cd8c94247f5849f6c04e8db1049ebb0b8110b449bc22eca7ddc9ef8351ca8f7d
        $ wget --retry-connrefused http://localhost:28001/stop -O -                    
        --2021-08-16 14:40:37--  http://localhost:28001/stop                                
        Resolving localhost (localhost)... ::1, 127.0.0.1                                   
        Connecting to localhost (localhost)|::1|:28001... connected.                        
        HTTP request sent, awaiting response... 200 OK                                      
        Length: unspecified [application/json]    
        Saving to: ‘STDOUT’  
        
        -                        [<=>                    ]       0  --.-KB/s               {
            "at": 1629117637.1792567,             
            "env": {         
                "APP_ENV": "development",         
                "GPG_KEY": "E3FF2839C048B25C084DEBE9B26995E310250568",                      
                "HOME": "/root",                  
                "HOSTNAME": "cd8c94247f58",       
                "LANG": "C.UTF-8",                
                "PATH": "/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",           
                "PYTHON_GET_PIP_SHA256": "fa6f3fb93cce234cd4e8dd2beb54a51ab9c247653b52855a48dd44e6b21ff28b",     
                "PYTHON_GET_PIP_URL": "https://github.com/pypa/get-pip/raw/c20b0cfd643cd4a19246ccf204e2997af70f6b21/public/get-pip.py",                                         
                "PYTHON_PIP_VERSION": "21.2.3",   
                "PYTHON_VERSION": "3.8.11",       
                "TERM": "xterm",                  
                "container": "podman"             
            }                
        -                        [ <=>                   ]     692  --.-KB/s    in 0s       
        
        2021-08-16 14:40:37 (1.36 MB/s) - written to stdout [692]
    
    


<!-- id: 0d8dd6deed60237d4078723ed9618bee -->

### Commit App

<!-- id: cedbe869f1067899a67639a1fb240fca -->

=== "Cmd"
    
    ```console
    $ git add server.py Dockerfile environ
    $ git commit -am 'feat: First version of hello world server'
    $ git tag $ver || true
    ```

=== "Output"

    
    <xterm />
    
        $ git add server.py Dockerfile environ
        $ git commit -am 'feat: First version of hello world server'                   
        [master (root-commit) cf30264] feat: First version of hello world server            
         3 files changed, 50 insertions(+)        
         create mode 100644 Dockerfile            
         create mode 100644 environ               
         create mode 100755 server.py
        $ git tag $ver || true
    
    


<!-- id: cedbe869f1067899a67639a1fb240fca -->

### Push to (Private) Registry


<!-- id: 23ed0b2db0dbe69c84c7a76c93ac10e5 -->

=== "Cmd"
    
    ```console
    $ p login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"
    $ r="docker://$(pass show reg/domain)/docker-internal/$namespace"
    $ p push --quiet --authfile=$fn_reg_auth $namespace/$app:$ver "$r/$app:$ver" && echo success # lp: assert=success
    ```

=== "Output"

    
    <xterm />
    
        $ p login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"            
        Login Succeeded!
        $ r="docker://$(pass show reg/domain)/docker-internal/$namespace"
        $ p push --quiet --authfile=$fn_reg_auth $namespace/$app:$ver "$r/$app:$ver" && echo success        
        success
    
    


<!-- id: 23ed0b2db0dbe69c84c7a76c93ac10e5 -->


## Cloud Deployment

Lets deploy the container using K8s' builtin weapons:

The app is stateless, so we deploy, ...well..., a ["Deployment"](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/):

<!-- id: 872b0271a9b7e9c0ce92a2e6373bf6a9 -->

=== "Cmd"
    
    ```console
    $ cat << EOF > frontend-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: frontend
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: pyhello
          tier: frontend
      template:
        metadata:
          labels:
            app: pyhello
            tier: frontend
        spec:
          imagePullSecrets:
          - name: regcred
          containers:
          - name: py-hello1
            image: $(pass show reg/domain)/docker-internal/$namespace/$app:$ver
            imagePullPolicy: Always
            env:
            - name: FOO
              value: "BAR"
            ports:
            - containerPort: 28001
            resources:
              requests:
                cpu: 100m
                memory: 100Mi
    EOF
    $ k apply -f frontend-deployment.yaml
    $ sleep 1
    $ k get pods -l app=pyhello -l tier=frontend
    ```

=== "Output"

    
    <xterm />
    
        $ cat << EOF > frontend-deployment.yaml   
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
        $ 
        $ k apply -f frontend-deployment.yaml                     
        deployment.apps/frontend unchanged
        $ sleep 1
        $ k get pods -l app=pyhello -l tier=frontend              
        NAME                       READY   STATUS    RESTARTS   AGE                         
        frontend-9d9756598-tgkxj   1/1     Running   0          14m                         
        frontend-9d9756598-w2dck   1/1     Running   0          14m
    
    


<!-- id: 872b0271a9b7e9c0ce92a2e6373bf6a9 -->


<!-- id: e353ee1d2e8916e8d96cd3bbc24a8889 -->

=== "Cmd"
    
    ```console
    $ cat << EOF > frontend-service.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: frontend
      labels:
        app: pyhello
        tier: frontend
    spec:
      type: LoadBalancer
      ports:
      - port: 28001
      selector:
        app: pyhello
        tier: frontend
    EOF
    $ k apply -f frontend-service.yaml
    $ sleep 1
    $ k get service frontend
    ```

=== "Output"

    
    <xterm />
    
        $ cat << EOF > frontend-service.yaml      
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
        $ 
        $ k apply -f frontend-service.yaml                        
        service/frontend unchanged
        $ sleep 1
        $ k get service frontend                                  
        NAME       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)           AGE   
        frontend   LoadBalancer   10.245.204.64   104.248.103.121   28001:31927/TCP   14m
    
    


<!-- id: e353ee1d2e8916e8d96cd3bbc24a8889 -->

On DO the loadbalancer needs a few minutes when you first configure one, on a *new* k8s cluster (`k describe service frontend` shows details).

Let's wait until up:

<!-- id: 444aba1d65ac8125d1bb736e98846551 -->

=== "Cmd"
    
    ```console
    $ while true; do sleep 2; k get service frontend | grep pending || break; done # lp: timeout=600
    $ k -o json get service frontend | jq .
    $ ip=$(k -o json get service frontend | jq -r .status.loadBalancer.ingress[0].ip)
    ```

=== "Output"

    
    <xterm />
    
        $ while true; do sleep 2; k get service frontend | grep pending || break; done
        $ k -o json get service frontend | jq .                   
        [1m{[0m[39m[49m                    
        [1m  [34m"apiVersion"[39m: [0m[32m[49m"v1"[1m[39m,
          [34m"kind"[39m: [0m[32m[49m"Service"[1m[39m,[0m[39m[49m 
        [1m  [34m"metadata"[39m: {[0m[39m[49m      
        [1m    [34m"annotations"[39m: {[0m[39m[49m 
        [1m      [34m"kubectl.kubernetes.io/last-applied-configuration"[39m: [0m[32m[49m"{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"pyhello\",\"tier\":\"frontend\"},\"name\":\"frontend\",\"namespace\":\"default\"},\"spec\":{\"ports\":[{\"port\":28001}],\"selector\":{\"app\":\"pyhello\",\"tier\":\"frontend\"},\"type\":\"LoadBalancer\"}}\n"[1m[39m,[0m[39m[49m           
        [1m      [34m"kubernetes.digitalocean.com/load-balancer-id"[39m: [0m[32m[49m"6781507a-afb4-49b0-b411-f0269483efb4"[39m             
        [1m    },[0m[39m[49m               
        [1m    [34m"creationTimestamp"[39m: [0m[32m[49m"2021-08-16T12:26:31Z"[1m[39m,[0m[39m[49m                                    
        [1m    [34m"finalizers"[39m: [[0m[39m[49m  
        [1m      [0m[32m[49m"service.kubernetes.io/load-balancer-cleanup"[39m                                 
        [1m    ],[0m[39m[49m               
        [1m    [34m"labels"[39m: {[0m[39m[49m      
        [1m      [34m"app"[39m: [0m[32m[49m"pyhello"[1m[39m,[0m[39m[49m                   
        [1m      [34m"tier"[39m: [0m[32m[49m"frontend"[39m                  
        [1m    },[0m[39m[49m               
        [1m    [34m"name"[39m: [0m[32m[49m"frontend"[1m[39m,[0m[39m[49m                   
        [1m    [34m"namespace"[39m: [0m[32m[49m"default"[1m[39m,[0m[39m[49m               
        [1m    [34m"resourceVersion"[39m: [0m[32m[49m"3707"[1m[39m,[0m[39m[49m            
        [1m    [34m"uid"[39m: [0m[32m[49m"ac18b950-82cd-4b6b-8aa1-59f3dcf94af5"[39m                                   
        [1m  },[0m[39m[49m                 
        [1m  [34m"spec"[39m: {[0m[39m[49m          
        [1m    [34m"clusterIP"[39m: [0m[32m[49m"10.245.204.64"[1m[39m,[0m[39m[49m         
        [1m    [34m"clusterIPs"[39m: [[0m[39m[49m  
        [1m      [0m[32m[49m"10.245.204.64"
        [1m[39m    ],[0m[39m[49m               
        [1m    [34m"externalTrafficPolicy"[39m: [0m[32m[49m"Cluster"[1m[39m,[0m[39m[49m   
        [1m    [34m"ipFamilies"[39m: [[0m[39m[49m  
        [1m      [0m[32m[49m"IPv4"[39m         
        [1m    ],[0m[39m[49m               
        [1m    [34m"ipFamilyPolicy"[39m: [0m[32m[49m"SingleStack"[1m[39m,[0m[39m[49m      
        [1m    [34m"ports"[39m: [[0m[39m[49m       
        [1m      {[0m[39m[49m              
        [1m        [34m"nodePort"[39m: [0m[39m[49m31927[1m,[0m[39m[49m                
        [1m        [34m"port"[39m: [0m[39m[49m28001[1m,[0m[39m[49m                    
        [1m        [34m"protocol"[39m: [0m[32m[49m"TCP"[1m[39m,[0m[39m[49m                
        [1m        [34m"targetPort"[39m: [0m[39m[49m28001               
        [1m      }[0m[39m[49m              
        [1m    ],[0m[39m[49m               
        [1m    [34m"selector"[39m: {[0m[39m[49m    
        [1m      [34m"app"[39m: [0m[32m[49m"pyhello"[1m[39m,[0m[39m[49m                   
        [1m      [34m"tier"[39m: [0m[32m[49m"frontend"[39m                  
        [1m    },[0m[39m[49m               
        [1m    [34m"sessionAffinity"[39m: [0m[32m[49m"None"[1m[39m,[0m[39m[49m            
        [1m    [34m"type"[39m: [0m[32m[49m"LoadBalancer"[39m                
        [1m  },[0m[39m[49m                 
        [1m  [34m"status"[39m: {[0m[39m[49m        
        [1m    [34m"loadBalancer"[39m: {
              [34m"ingress"[39m: [[0m[39m[49m   
        [1m        {[0m[39m[49m            
        [1m          [34m"ip"[39m: [0m[32m[49m"104.248.103.121"[39m         
        [1m        }[0m[39m[49m            
        [1m      ][0m[39m[49m              
        [1m    }[0m[39m[49m                
        [1m  }[0m[39m[49m                  
        [1m}[0m[39m[49m
        $ ip=$(k -o json get service frontend | jq -r .status.loadBalancer.ingress[0].ip)
    
    


<!-- id: 444aba1d65ac8125d1bb736e98846551 -->

The pods are up now - we can access the service from the internet via `$ip`.
Loadbalancer distributes requests over pods:

<!-- id: 47f81a430ec26bb830009a63bb3d62a6 -->
<xterm />

    $ wget -q http://$ip:28001/ -O - | jq .                   
    [1m{[0m[39m[49m                    
    [1m  [34m"at"[39m: [0m[39m[49m1629117652.7117255[1m,[0m[39m[49m               
    [1m  [34m"env"[39m: {[0m[39m[49m           
    [1m    [34m"APP_ENV"[39m: [0m[32m[49m"development"[1m[39m,[0m[39m[49m             
    [1m    [34m"FOO"[39m: [0m[32m[49m"BAR"[1m[39m,[0m[39m[49m    
    [1m    [34m"FRONTEND_PORT"[39m: [0m[32m[49m"tcp://10.245.204.64:28001"[1m[39m,[0m[39m[49m                                   
    [1m    [34m"FRONTEND_PORT_28001_TCP"[39m: [0m[32m[49m"tcp://10.245.204.64:28001"[1m[39m,[0m[39m[49m                         
    [1m    [34m"FRONTEND_PORT_28001_TCP_ADDR"[39m: [0m[32m[49m"10.245.204.64"[1m[39m,[0m[39m[49m                                
    [1m    [34m"FRONTEND_PORT_28001_TCP_PORT"[39m: [0m[32m[49m"28001"[1m[39m,[0m[39m[49m                                        
    [1m    [34m"FRONTEND_PORT_28001_TCP_PROTO"[39m: [0m[32m[49m"tcp"[1m[39m,[0m[39m[49m                                         
    [1m    [34m"FRONTEND_SERVICE_HOST"[39m: [0m[32m[49m"10.245.204.64"[1m[39m,[0m[39m[49m                                       
    [1m    [34m"FRONTEND_SERVICE_PORT"[39m: [0m[32m[49m"28001"[1m[39m,[0m[39m[49m     
    [1m    [34m"GPG_KEY"[39m: [0m[32m[49m"E3FF2839C048B25C084DEBE9B26995E310250568"[1m[39m,[0m[39m[49m                          
    [1m    [34m"HOME"[39m: [0m[32m[49m"/root"[1m[39m,[0m[39m[49m 
    [1m    [34m"HOSTNAME"[39m: [0m[32m[49m"frontend-9d9756598-tgkxj"[1m[39m,[0m[39m[49m                                         
    [1m    [34m"KUBERNETES_PORT"[39m: [0m[32m[49m"tcp://10.245.0.1:443"[1m[39m,[0m[39m[49m                                      
    [1m    [34m"KUBERNETES_PORT_443_TCP"[39m: [0m[32m[49m"tcp://10.245.0.1:443"[1m[39m,[0m[39m[49m                              
    [1m    [34m"KUBERNETES_PORT_443_TCP_ADDR"[39m: [0m[32m[49m"10.245.0.1"[1m[39m,[0m[39m[49m                                   
    [1m    [34m"KUBERNETES_PORT_443_TCP_PORT"[39m: [0m[32m[49m"443"[1m[39m,
        [34m"KUBERNETES_PORT_443_TCP_PROTO"[39m: [0m[32m[49m"tcp"[1m[39m,[0m[39m[49m                                         
    [1m    [34m"KUBERNETES_SERVICE_HOST"[39m: [0m[32m[49m"10.245.0.1"[1m[39m,[0m[39m[49m                                        
    [1m    [34m"KUBERNETES_SERVICE_PORT"[39m: [0m[32m[49m"443"[1m[39m,[0m[39m[49m     
    [1m    [34m"KUBERNETES_SERVICE_PORT_HTTPS"[39m: [0m[32m[49m"443"[1m[39m,[0m[39m[49m                                         
    [1m    [34m"LANG"[39m: [0m[32m[49m"C.UTF-8"[1m[39m,[0m[39m[49m                    
    [1m    [34m"PATH"[39m: [0m[32m[49m"/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"[1m[39m,[0m[39m[49m               
    [1m    [34m"PYTHON_GET_PIP_SHA256"[39m: [0m[32m[49m"fa6f3fb93cce234cd4e8dd2beb54a51ab9c247653b52855a48dd44e6b21ff28b"[1m[39m,[0m[39m[49m         
    [1m    [34m"PYTHON_GET_PIP_URL"[39m: [0m[32m[49m"https://github.com/pypa/get-pip/raw/c20b0cfd643cd4a19246ccf204e2997af70f6b21/public/get-pip.py"[1m[39m,[0m[39m[49m   
    [1m    [34m"PYTHON_PIP_VERSION"[39m: [0m[32m[49m"21.2.3"[1m[39m,[0m[39m[49m       
    [1m    [34m"PYTHON_VERSION"[39m: [0m[32m[49m"3.8.11"[39m            
    [1m  }[0m[39m[49m                  
    [1m}[0m[39m[49m


<!-- id: 47f81a430ec26bb830009a63bb3d62a6 -->

<!-- id: de6aa5535195585fc63c0b7f289880f8 -->
```bash
$ for i in {1..10}; do wget -q http://$ip:28001/ -O - | jq -r .env.HOSTNAME; done | sort | uniq     
frontend-9d9756598-tgkxj                  
frontend-9d9756598-w2dck
```
<!-- id: de6aa5535195585fc63c0b7f289880f8 -->

Dashboard says:

[![](img/k8s.png){style="max-width: 300px"}](img/k8s.png)


!!! note "K8s HA"

    === "Crashing the App"

        We can watch K8s respawning pods when we cause the service to crash:


        <!-- id: 62f43f6f857b3ba713d9805bdcc17490 -->
                        ```bash
                        $ for i in 1 2; do wget -qt1T1 http://$ip:28001/err -O /dev/null; done
                        ```
                        
                        
                        ```bash
                        $ sleep 2
                        ```
                        
                        
                        ```bash
                        $ k get pods    
                        NAME                       READY   STATUS    RESTARTS   AGE                         
                        frontend-9d9756598-tgkxj   1/1     Running   1          14m                         
                        frontend-9d9756598-w2dck   1/1     Running   1          14m
                        ```
                       
               
        <!-- id: 62f43f6f857b3ba713d9805bdcc17490 -->

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

<!-- id: e52d27ccab1dfbb0e3084837c0ec4aa7 -->
```bash
$ k delete -f frontend-service.yaml                       
service "frontend" deleted
```


```bash
$ k delete -f frontend-deployment.yaml                    
deployment.apps "frontend" deleted
```
<!-- id: e52d27ccab1dfbb0e3084837c0ec4aa7 -->




<!-- id: c5c877457cd009969c6f3dbeaf57c52c -->
<xterm />

    


<!-- id: c5c877457cd009969c6f3dbeaf57c52c -->
