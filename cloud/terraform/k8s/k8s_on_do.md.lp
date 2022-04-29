```page lp session=k8s
```

# K8s With Terraform

Here we learn how to get to a K8s instance running on a cloud provider. 

We use Digitial Ocean(DO) as cloud provider, AWS is well documented.


!!! tip "Local K8s Test Instances"

    When you do not have a cloud infra provider or want something for CI then use ["kind"](https://kind.sigs.k8s.io/docs/user/quick-start).
    On the Terraform page there is a [nice example](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes) how to use it.
    


## Requirements

- Have local:
    - The cloud provider client (here: `doctl`)
    - The terraform binary
    - podman or docker (here only to configure access to our private registry for k8s, via their
      auth file they create after login). I.e. only for convenience.
    - Optional: We use the `pass` utility since we don't want sensitive values being shown

- Have an API token for DO  
- Optional: Private container registry url with creds

```bash lp session=k8s
# tools:
type doctl terraform kubectl podman pass

# this is how the pass utility works, storing our private values:
# you add kvs like pass insert foo/bar<enter>
pass show DO/pat | head -c 5

# prepare working directory:
D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s"
mkdir -p "$D"
cd "$D" || exit 1

# Start from scratch
export TF_VAR_do_token="$(pass show DO/pat)"
terraform destroy -auto-approve -lock=false      # lp: expect=complete timeout=100
ls -a | xargs rm -rf 2>/dev/null
```


## Environ

Lets create a file which sets up our working environ, when sourced - convenient for new shells:

```bash lp mode=make_file fn=environ replace cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/k8s
set -ae
alias tf=terraform k=kubectl

# completion:
[[ "$0" = *bash* ]] && s=bash || s=zsh
source <(kubectl completion $s)

export D="%(cwd)s"
cd "$D"
TF_VAR_do_token="$(pass show DO/pat)"
clustername="tf-do-cluster-d1"
latest_k8s_ver="$(doctl kubernetes options versions | grep -A 1 Slug | tail -n 1 | cut -d  ' ' -f1 | xargs)"
set +ae
```

## Config


```bash lp timeout=10
source environ
cat << EOF > provider.tf
> terraform {
>   required_providers {
>     digitalocean = {
>       source = "digitalocean/digitalocean"
>       version = "~> 2.0"
>     }
>   }
> }
>   
> variable "do_token" { }
>   
> data "digitalocean_ssh_key" "terraform" {
>       name = "terraform"
> }
> provider "digitalocean" {
>     token = var.do_token
> }
> EOF
```

<!-- using q unique name -->

```bash lp
cat << EOF > do-kubernetes.tf
> resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
>   name    = "$clustername"
>   region  = "fra1"
>   version = "$latest_k8s_ver"
> 
>   tags = ["my-tag", "d1"]
> 
>   # This default node pool is mandatory
>   node_pool {
>     name       = "default-pool"
>     size       = "s-1vcpu-2gb" # minimum size, list available options with doctl compute size list
>     auto_scale = false
>     node_count = 2
>     tags       = ["node-pool-tag"]
>     labels = {
>     }
>   }
> 
> }
> 
> # A node pool for applications
> resource "digitalocean_kubernetes_node_pool" "app_node_pool" {
>   cluster_id = digitalocean_kubernetes_cluster.kubernetes_cluster.id
> 
>   name = "app-pool"
>   size = "s-2vcpu-4gb"
>   tags = ["applications"]
> 
>   # you can setup autoscaling
>   auto_scale = true
>   min_nodes  = 2
>   max_nodes  = 10
>   labels = {
>     service  = "apps"
>     priority = "high"
>   }
> }
> EOF
```

## Init - Plan - Apply

```bash lp timeout=10
tf init # lp: asserts="successfully initialized"
tf plan # lp: asserts="to add"
```

Create it:

<!-- have seen 5minutes for mgmt pool -->
```bash lp timeout=1500 asserts=complete lock_page
time tf apply -auto-approve
```

Should be done in a few minutes. Large variations, I saw between 5 and 15 minutes...

## Configure `kubectl`

!!! note "why?"
    No matter how much we'll do in terraform or other tools, a configured kubectl is simply a must have for clusters you created - and if it is
    only to [crosscheck](../../k8s/index.md).

```bash lp assert=Adding timeout=20
doctl kubernetes cluster kubeconfig save "$clustername" # lp: asserts="Adding cluster"
kubectl cluster-info                                    # lp: asserts="control plane"
k cluster-info dump | wc -l                             # hf ;-)
```

The first command configures the default cluster for `kubectl`, no need to specify the name then, when you
work "only" with one.

!!! note
    Using terraform you do *NOT* necessarily require a local `~/.kube/config` file. You can use the
    tf k8s provider also [using the token alone](./k8s_provider/do_k8s.md).


```bash lp asserts=app-pool timeout=4 fmt=xt_flat
k get nodes
```


### [Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) Image Pulling 

You want the container orchestrator (here Kubernetes) to pull from your private registry. The simplest way to do so
is:

- "Docker login" there
- Tell K8s about it

```bash lp timeout=10
podman login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"

fn=$XDG_RUNTIME_DIR/containers/auth.json # podman's location. docker: elsewhere
k create secret generic regcred --from-file=".dockerconfigjson=$fn"  --type=kubernetes.io/dockerconfigjson # lp: asserts=regcred
```

Now at subsequent deploys you can specify sth like:

```yaml
# (...)
image: <your image at private registry>
imagePullSecrets:
- name: regcred
```


!!! tip
    - The value for `reg/domain` is like `your.private.registry.example.com`
    - The value for `image` is like `your.private.registry.example.com/janedoe/jdoe-private:v1`





## Discussion

- "digitalocean_kubernetes_cluster" is from the Terraform Registry:
  https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster. 

- Here you find many recipes ("modules") for systems deploys on K8s, not only for Dig.Ocean, e.g.
  https://registry.terraform.io/modules/rivernews/kubernetes-microservice/digitalocean/latest

!!! quote "Not only for DO"
        
    This module currently assumes the use of Digitalocean Kubernetes Service. However, you may
    easily change your favored kubernetes vendor by forking this repo and modify the content of
    kubernetes-cluster.tf.

    Repo is on Github: https://github.com/rivernews/terraform-digitalocean-kubernetes-microservice

- Hitlist: https://registry.terraform.io/providers/digitalocean/digitalocean/latest

- Here more: https://registry.terraform.io/browse/providers 

### Raw Kubernetes is Hard

Have a look into `kubectl cluster-info dump`...

### Config / Security

On the web frontend of the cloud provider you can download a cluster config file, incl. a
`cluster_ca_certificate` value. That config, incl. the certificate is also found in the local [`./terraform.tfstate`](https://www.terraform.io/docs/language/state/index.html), i.e. that file is sensitive. There are means to have that [stored remotely](https://www.google.com/search?q=terraform+remote+state).

### Apply Errors Do Happen

At apply I did get

```
│ Error: Error creating Kubernetes cluster: Error trying to read cluster state: GET https://api.digitalocean.com/v2/kubernetes/clusters/587b36f7-1a1b-4b80-acd5-a933bac44125: 500 Server Error
│
│   with digitalocean_kubernetes_cluster.kubernetes_cluster,
│   on do-kubernetes.tf line 1, in resource "digitalocean_kubernetes_cluster" "kubernetes_cluster":
```

or 

```

│ Error: Error creating Kubernetes cluster: Error trying to read cluster state: Get "https://api.digitalocean.com/v2/kubernetes/clusters/85ff2d69-a0c3-4b38-bb59-3f3dca1dc09c": read tcp 10.0.0.84:47880->104.16.182.15:443: read: connection reset by peer
│
```

after 6 minutes of installation time... 

This I consider sth not TF to blame for (rather DO), i.e. you have to take apply errors into account writing your
infrastructure provisioning machinery anyway.

But **this** I do consider a bug:

A subsequent run (after a `tf destroy`(!)) error-ed out with `│ Error: Error creating Kubernetes cluster: POST https://api.digitalocean.com/v2/kubernetes/clusters: 422 a cluster with this name already exists`.

Had to delete the k8s cluster manually on the DO UI -> TF was clearly out of sync here.

!!! note

    I consider this a bug of the digitalocean_kubernetes_cluster resource implementation, at the destroy
    implementation.

!!! tip "Use deploy unique names"

    Especially with very complex resources like a k8s cluster it makes a lot of sense to not use the
    same names for re-deploys after destroy. I did see people appending unixtimestamps to resource
    names...

    The infrastructure provider, while having acked the
    destroy seems to still have some ongoing cleanup jobs (or maybe DNS timeouts?) going on.

    At deploys with unique names I never got problems at apply - so far.


## Further Readings

- Tanzu with Terraform: https://williamlam.com/2020/11/using-terraform-to-deploy-a-tanzu-kubernetes-grid-tkg-cluster-in-vsphere-with-tanzu.html
- https://www.hashicorp.com/blog/deploy-any-resource-with-the-new-kubernetes-provider-for-hashicorp-terraform

### K8s -> OS
- https://techbloc.net/archives/3428
- https://medium.com/@fabiojose/platform-as-code-with-openshift-terraform-1da6af7348ce
- https://github.com/cptmorgan-rh/install-oc-tools
- https://registry.terraform.io/providers/llomgui/openshift/latest/docs/guides/getting-started
- http://www.matthiassommer.it/programming/deploying-grafana-openshift-terraform/

### Svc Mesh

- https://platform9.com/blog/kubernetes-service-mesh-a-comparison-of-istio-linkerd-and-consul/






