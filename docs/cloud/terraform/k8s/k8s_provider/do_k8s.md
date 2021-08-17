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


<!-- id: 8f5b9b662a3d46252f0067d2e1fc1c0e -->

=== "Cmd"
    
    ```console
    $ mkdir -p tmp/datasource_test && cd $_ 
    $ cat << EOF > query.tf
    terraform {
      required_providers {
        digitalocean = {
          source = "digitalocean/digitalocean"
          version = "~> 2.0"
        }
      }
    }
    
    variable "do_token" {}
    
    # Configure the DigitalOcean Provider
    provider "digitalocean" {
      token = var.do_token
    }
    
    
    data "digitalocean_kubernetes_cluster" "example" {
        name = "tf-do-cluster-d1"
    }
    // this way we can manage it, using "only" the token - no kubectl config required: 
    provider "kubernetes" {
      host             = data.digitalocean_kubernetes_cluster.example.endpoint
      token            = data.digitalocean_kubernetes_cluster.example.kube_config[0].token
      cluster_ca_certificate = base64decode(
        data.digitalocean_kubernetes_cluster.example.kube_config[0].cluster_ca_certificate
      )
    }
    // output some values: 
    output "endpoint" {
         value = data.digitalocean_kubernetes_cluster.example.endpoint
    }
    output "token" {
         value =  data.digitalocean_kubernetes_cluster.example.kube_config[0].token
         sensitive = true
    }
    EOF
    $ export TF_VAR_do_token=$(pass show DO/pat)
    $ terraform init
    $ terraform apply -auto-approve
    $ rm query.tf
    ```

=== "Output"

    
    <xterm />
    
        $ mkdir -p tmp/datasource_test && cd $_ 
        $ cat << EOF > query.tf                 
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
        $ 
        $ export TF_VAR_do_token=$(pass show DO/pat)
        $ terraform init                                      
        
        [1mInitializing the backend...[0m[39m[49m             
        
        [1mInitializing provider plugins...[0m[39m[49m        
        - Finding latest version of hashicorp/kubernetes...                             
        - Finding digitalocean/digitalocean versions matching "~> 2.0"...               
        - Installing hashicorp/kubernetes v2.4.1...                                     
        - Installed hashicorp/kubernetes v2.4.1 (signed by HashiCorp)                   
        - Installing digitalocean/digitalocean v2.11.0...                               
        - Installed digitalocean/digitalocean v2.11.0 (signed by a HashiCorp partner, key ID [1mF82037E524B9C0E8[0m[39m[49m)                  
        
        Partner and community providers are signed by their developers.                 
        If you'd like to know more about provider signing, you can read about it here:  
        https://www.terraform.io/docs/cli/plugins/signing.html                          
        
        Terraform has created a lock file [1m.terraform.lock.hcl[0m[39m[49m to record the provider    
        selections it made above. Include this file in your version control repository  
        so that Terraform can guarantee to make the same selections by default when     
        you run "terraform init" in the future. 
        
        [1m[32mTerraform has been successfully initialized![0m[39m[49m                                    
        
        [32mYou may now begin working with Terraform. Try running "terraform plan" to see[39m   
        [32many changes that are required for your infrastructure. All Terraform commands[39m   
        [32mshould now work.[39m    
        
        [32mIf you ever set or change modules or backend configuration for Terraform,[39m       
        [32mrerun this command to reinitialize your working directory. If you forget, other[39m 
        [32mcommands will detect it and remind you to do so if necessary.[39m
        $ terraform apply -auto-approve                       
        
        [1mChanges to Outputs:[0m[39m[49m 
          [32m+[39m endpoint = "https://f87c35a9-2545-4d28-a982-c42a70deb997.k8s.ondigitalocean.com"                
          [32m+[39m token    = (sensitive value)        
        
        You can apply this plan to save these new output values to the Terraform state, 
        without changing any real infrastructure.                                       
        
        [1m[32mApply complete! Resources: 0 added, 0 changed, 0 destroyed.[0m[39m[49m                     
        
        [1m[32mOutputs:[0m[39m[49m            
        
        endpoint = "https://f87c35a9-2545-4d28-a982-c42a70deb997.k8s.ondigitalocean.com"
        token = <sensitive>
        $ rm query.tf
    
    


<!-- id: 8f5b9b662a3d46252f0067d2e1fc1c0e -->


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