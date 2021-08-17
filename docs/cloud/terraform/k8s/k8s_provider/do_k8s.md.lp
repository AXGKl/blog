# Attaching to [`kubernetes`][ds0] Provider Using Infra Provider's Specific Auth Plugin

This is a quick verification of the cloud infra provider specific K8s support, example DigitalOcean.
This erradicates the need to even have a kubectl config local, you just need the Cloud Provider token.

I.e. it illustrates the implementation of [this][ds2] statement in the terraform docs about configuring the
kubernetes provider:

!!! quote
    There are many ways to configure the Kubernetes provider. We recommend them in the following order (most recommended first, least recommended last):

    1. **Use cloud-specific auth plugins (for example, eks get-token, az get-token, gcloud config)**
    1. Use oauth2 token
    1. Use TLS certificate credentials
    1. Use kubeconfig file by setting both config_path and config_context
    1. Use username and password (HTTP Basic Authorization)



In general: When there is an externally managed K8s cluster, which you did not set up and have no
config local and you want to gather information about it, you can use the specific cloud infra tf
provider's kubernetes support (here: [digitalocean_kubernetes_cluster][ds1] "data source"):


```bash lp timeout=10 session=k8s_datasource cwd=$DT_PROJECT_ROOT lock_page
mkdir -p tmp/datasource_test && cd $_ 

cat << EOF > query.tf
> terraform {
>   required_providers {
>     digitalocean = {
>       source = "digitalocean/digitalocean"
>       version = "~> 2.0"
>     }
>   }
> }
> 
> variable "do_token" {}
> 
> # Configure the DigitalOcean Provider
> provider "digitalocean" {
>   token = var.do_token
> }
> 
> 
> data "digitalocean_kubernetes_cluster" "example" {
>     name = "tf-do-cluster-d1"
> }
> // this way we can manage it, using "only" the token - no kubectl config required: 
> provider "kubernetes" {
>   host             = data.digitalocean_kubernetes_cluster.example.endpoint
>   token            = data.digitalocean_kubernetes_cluster.example.kube_config[0].token
>   cluster_ca_certificate = base64decode(
>     data.digitalocean_kubernetes_cluster.example.kube_config[0].cluster_ca_certificate
>   )
> }
> // output some values: 
> output "endpoint" {
>      value = data.digitalocean_kubernetes_cluster.example.endpoint
> }
> output "token" {
>      value =  data.digitalocean_kubernetes_cluster.example.kube_config[0].token
>      sensitive = true
> }
> EOF
export TF_VAR_do_token=$(pass show DO/pat)
terraform init
terraform apply -auto-approve
rm query.tf
```


!!! note "AWS"

    [Here](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes) a comparable way to do it on AWS:

    ```json
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      exec {
        api_version = "client.authentication.k8s.io/v1alpha1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          data.aws_eks_cluster.cluster.name
        ]
      }
    }
    ```



[ds0]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started
[ds1]: https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/data-sources/kubernetes_cluster
[ds2]: https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/kubernetes&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS&_ga=2.244784832.473698869.1629142132-1982289529.1629142132#configure-the-provider
