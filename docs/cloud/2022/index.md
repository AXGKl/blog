# 2022 DevOps

## Learned

- https://www.youtube.com/watch?v=DsQu66ZMG4M (Secret
  - Daemonset: Means: Runs on all nodes (pod for the driver in any node)
  - CSI: Container Storage Interface (i.e. Volumnes mounted into pods)
  - datree: validates (lints) k8s yaml files.
  - Operator Ext Secrets: https://www.youtube.com/watch?v=SyRZe5YVCVk

https://kubernetes.io/docs/reference/kubectl/cheatsheet/

## Todo

- Argo: App of app = Application Sets (repo organziation, from devtron vid https://www.youtube.com/watch?v=ZKcfZC-zSMM&t=189s)

- Tilt Dev Envs -> automate save - build ship deploy
  https://tilt.dev/ can also file sync only (extension https://github.com/tilt-dev/tilt-extensions)

- arkade: better helm
  plus: arkade get helm kubectl tilt (...)
- telepresence: reroute svc traffic into your laptop.

- microservices: https://www.youtube.com/watch?v=F-37_gV2tMs

## Python CRD Lib

Stephan: Too hard: https://github.com/nolar/kopf/tree/main/examples

## Kind

Ideal for local k8s and Testing. Nodes are containers, as many as you want.

Works with podman, just set dockerhub only in /etc/containers/registries.conf

## k3s

Better than minikube regarding resources and deploy time

- HA k3s on TF https://registry.terraform.io/modules/aigisuk/ha-k3s/digitalocean/latest https://colinwilson.uk/2021/04/04/deploy-a-ha-k3s-cluster-on-digitalocean-in-10-minutes-using-terraform/

## Minikube

Create a Fedora 36 server WITH MIN 2 CORES. User script:

```bash

#!/bin/bash
user=gk
GU="https://packages.cloud.google.com/yum/"
function add_user {
    adduser $user
    cp -a /root/.ssh /home/$user/
    chown -R $user /home/$user/.ssh
    echo "$user	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers
}
function set_shell_env {
    for d in /root /home/$user; do
        echo 'alias vi=nvim' >> $d/.bashrc
        echo 'alias ff="fd --no-ignore --hidden"' >> $d/.bashrc
    done
}
function inst_packages {
    dnf -y update
    dnf -y install neovim podman git ripgrep fzf netcat fd-find
}
function inst_kubectl {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=$GU/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$GU/doc/yum-key.gpg $GU/doc/rpm-package-key.gpg
EOF
     yum install -y kubectl
}
function inst_minicube {
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
    rpm -Uhv ./minikube-latest.x86_64.rpm
}
function main {
    add_user
    set_shell_env
    inst_packages
    inst_kubectl
    inst_minicube
}
main

```

## Elakstic via Operator

1. Deploy 3 node k3s
2. wget https://download.elastic.co/downloads/eck/2.3.0/crds.yaml and wget https://download.elastic.co/downloads/eck/2.3.0/operator.yaml
3. create -f the crds and apply the operator
4. annotate all nodes: for n in k2server k21 k22 k23; do kubectl patch node $n -p '{"metadata":{"annotations":{"topology.kubernetes.io/zone": "fra1"}}}'; done
5. apply:

```
---
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
spec:
  version: 8.2.0
  nodeSets:
    - name: default
      config:
        node.roles: ["master", "data", "ingest", "ml"]
        node.store.allow_mmap: false
        cluster.routing.allocation.awareness.attributes: k8s_node_name
      podTemplate:
        spec:
          containers:
            - name: elasticsearch
              resources:
                limits:
                  memory: 4Gi
                  cpu: 1
              env:
                - name: ES_JAVA_OPTS
                  value: "-Xms2g -Xmx2g"
      count: 3
```

6. port forward and connect (ssl). Admin creds from elastic std k8s docs.

## Redis via Helm

helm install my-redis bitnami/redis-cluster

helm get manifest|notes my-redis

### Values: show vs get

helm show values bitnami/redis-cluster # show works on repo, get on install:

helm install --set service.ports.redis=2222 fubar bitnami/redis-cluster

helm get values fubar

```
USER-SUPPLIED VALUES:
service:
  ports:
    redis: 2222
```

Did not find how to really have it on different port.

kubectl get svc

## ssh

kubectl run --rm -i --tty c4 --image=docksal/ssh-agent -- bash

and you have ssh to other images
