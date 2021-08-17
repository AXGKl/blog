# Kubernetes with Terraform

Terraform offers two strictly seperate integrations for/with Kubernetes:

1. You can create Kubernetes Instances (clusters) on pretty much any cloud infra offering,
   using the cloud infra provider's specific terraform provider plugin. See
   [k8s_on_do](./k8s_on_do.md) for a live demo of getting to a Kubernetes cluster on DigitalOcean.
1. Once you have management access to a Kubernetes Cluster, you can, instead of using raw kubectl,
   also use terraform to configure resources on it, using the [kubernetes provider][k2]. See
   [k8s_provider tutorial](./k8s_provider/k8s_provider.md) for a live session.


[k2]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
