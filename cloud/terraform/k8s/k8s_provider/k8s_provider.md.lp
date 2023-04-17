```page lp session=k8s
```

# The Terraform(TF) Kubernetes Provider

This is the terraform tool to connect to a running kubernetes cluster.


## Requirements

- The kubernetes cluster we [created](../k8s_on_do.md) on DO.
- The completed [generic k8s tutorial](../../../k8s/2_hello_mysql/index.md), with the container
  image for the app on our private registry.

```bash lp timeout=10 fmt=mk_console
kubectl get nodes
```

- The cloud provider specific client tool (here doctl, which tf uses under the hood)


```bash lp skip_other
# prepare working directory:
D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s_provider"
mkdir -p "$D"
cd "$D" || exit 1
ls -la | xargs rm -rf
cat << EOF > environ
> set -ae
> namespace=devapps
> app=hello_app
> ver=0.2
> alias tf=terraform k=kubectl
> [[ "\$0" = *bash* ]] && s=bash || s=zsh
> source <(kubectl completion \$s)
> set +ae
> EOF
source environ
```

## Configuration

When we [did set up](../k8s_on_do.md) the kubernetes cluster on DigitalOcean(DO), we pulled the K8s
config, incl. certificates, into our local `~/.kube/config` (using the cloud infra specific tool
`doctl`: `doctl kubernetes cluster kubeconfig save "$clustername"`).

That file is being used by the TF K8s provider.

!!! note
    There are [other][tfdoc] means to connect as well. [Here](./do_k8s.md) we show how to configure
    the kubernetes provider with only the cloud provider's API token and *no* kubectl config file.


## Create Namespace

Here a basic first use case: Lets create a namespace on K8s, using TF:

```json lp mode=make_file fn=namespace.tf

provider "kubernetes" {
  config_path    = "~/.kube/config"
}

resource "kubernetes_namespace" "tfprov" {
  metadata {
    name = "tfprov-namespace"
  }
}

```

```bash lp timeout=20
terraform init
terraform apply -auto-approve # lp: asserts="Apply complete"
```

Resulting in a new namespace on K8s:

[![](./img/ns.png)](./img/ns.png)


## Deploy Stateful Application

In a previous [generic k8s tutorial](../../../k8s/2_hello_mysql/index.md), we did create a stateful
app backed by mysql, using only `kubectl` and necessary yaml files.



Lets do this now, using Terraform.











[tfdoc]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
