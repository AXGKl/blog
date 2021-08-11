

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
    - podman or docker (here only for registry logins)
    - The pass utility if you don't want sensitive values within your command history

- Have an API token for DO  
- Optional: Private container registry url with creds

<!-- id: 50399f954c9194e6f1a5d146710df984 -->

=== "Cmd"
    
    ```console
    $ type doctl terraform kubectl podman pass
    $ pass show DO/pat | head -c 5
    $ D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s"
    $ mkdir -p "$D"
    $ cd "$D" || exit 1
    $ export TF_VAR_do_token="$(pass show DO/pat)"
    $ terraform destroy -auto-approve -lock=false      # lp: expect=complete timeout=100
    $ ls -a | xargs rm -rf 2>/dev/null
    ```

=== "Output"

    
    <xterm />
    
        $ type doctl terraform kubectl podman pass            
        doctl is hashed (/usr/local/bin/doctl)  
        terraform is hashed (/usr/local/bin/terraform)                                  
        kubectl is hashed (/usr/local/bin/kubectl)                                      
        podman is hashed (/usr/bin/podman)      
        pass is /usr/bin/pass
        $ pass show DO/pat | head -c 5                        
        7ba23
        $ D="$DT_PROJECT_ROOT/tmp/clusters/DO/k8s"
        $ mkdir -p "$D"
        $ cd "$D" || exit 1
        $ export TF_VAR_do_token="$(pass show DO/pat)"
        $ terraform destroy -auto-approve -lock=false                                   
        
        [1m[32mNo changes.[39m No objects need to be destroyed.[0m[39m[49m                                    
        
        Either you have not created any objects yet or the existing objects were        
        already deleted outside of Terraform.   
        
        [1m[32mDestroy complete! Resources: 0 destroyed.[0m[39m[49m                                       
        $
        $ ls -a | xargs rm -rf 2>/dev/null
    
    


<!-- id: 50399f954c9194e6f1a5d146710df984 -->


## Environ

Lets create a file which sets up our working environ, when sourced - convenient for new shells:

<!-- id: 5b43033370d9d912789240700c624970 -->
```bash
$ cat environ
set -ae
alias tf=terraform k=kubectl

[[ "$0" = *bash* ]] && s=bash || s=zsh
source <(kubectl completion $s)

export D="/home/gk/repos/blog/tmp/clusters/DO/k8s"
cd "$D"
TF_VAR_do_token="$(pass show DO/pat)"
clustername="tf-do-cluster-d1"
latest_k8s_ver="$(doctl kubernetes options versions | grep -A 1 Slug | tail -n 1 | cut -d  ' ' -f1 | xargs)"
set +ae
```
<!-- id: 5b43033370d9d912789240700c624970 -->

## Config


<!-- id: 3c362fb0c0ee9ad86517cc916fb36af3 -->

=== "Cmd"
    
    ```console
    $ source environ
    $ cat << EOF > provider.tf
    terraform {
      required_providers {
        digitalocean = {
          source = "digitalocean/digitalocean"
          version = "~> 2.0"
        }
      }
    }
      
    variable "do_token" { }
      
    data "digitalocean_ssh_key" "terraform" {
          name = "terraform"
    }
    provider "digitalocean" {
        token = var.do_token
    }
    EOF
    ```

=== "Output"

    
    <xterm />
    
        $ source environ
        $ cat << EOF > provider.tf              
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
        $ 
    
    


<!-- id: 3c362fb0c0ee9ad86517cc916fb36af3 -->

<!-- using q unique name -->

<!-- id: b964b95a7aa3eb40b84d420180ae1c0d -->

=== "Cmd"
    
    ```console
    $ cat << EOF > do-kubernetes.tf
    resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
      name    = "$clustername"
      region  = "fra1"
      version = "$latest_k8s_ver"
    
      tags = ["my-tag", "d1"]
    
      # This default node pool is mandatory
      node_pool {
        name       = "default-pool"
        size       = "s-1vcpu-2gb" # minimum size, list available options with doctl compute size list
        auto_scale = false
        node_count = 2
        tags       = ["node-pool-tag"]
        labels = {
        }
      }
    
    }
    
    # A node pool for applications
    resource "digitalocean_kubernetes_node_pool" "app_node_pool" {
      cluster_id = digitalocean_kubernetes_cluster.kubernetes_cluster.id
    
      name = "app-pool"
      size = "s-2vcpu-4gb"
      tags = ["applications"]
    
      # you can setup autoscaling
      auto_scale = true
      min_nodes  = 2
      max_nodes  = 10
      labels = {
        service  = "apps"
        priority = "high"
      }
    }
    EOF
    ```

=== "Output"

    
    <xterm />
    
        $ cat << EOF > do-kubernetes.tf         
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
        $ 
    
    


<!-- id: b964b95a7aa3eb40b84d420180ae1c0d -->

## Init - Plan - Apply

<!-- id: a83f4712457c517166019262b44fbf7a -->

=== "Cmd"
    
    ```console
    $ tf init # lp: asserts="successfully initialized"
    $ tf plan # lp: asserts="to add"
    ```

=== "Output"

    
    <xterm />
    
        $ tf init     
        
        [1mInitializing the backend...[0m[39m[49m             
        
        [1mInitializing provider plugins...[0m[39m[49m        
        - Finding digitalocean/digitalocean versions matching "~> 2.0"...               
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
        $ tf plan     
        
        Terraform used the selected providers to generate the following execution plan. 
        Resource actions are indicated with the following symbols:                      
          [32m+[39m create          
        
        Terraform will perform the following actions:                                   
        
        [1m  # digitalocean_kubernetes_cluster.kubernetes_cluster[0m[39m[49m will be created          
          [32m+[39m resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {           
              [32m+[39m cluster_subnet = (known after apply)                                    
              [32m+[39m created_at     = (known after apply)                                    
              [32m+[39m endpoint       = (known after apply)                                    
              [32m+[39m id             = (known after apply)                                    
              [32m+[39m ipv4_address   = (known after apply)                                    
              [32m+[39m kube_config    = (sensitive value)                                      
              [32m+[39m name           = "tf-do-cluster-d1"                                     
              [32m+[39m region         = "fra1"         
              [32m+[39m service_subnet = (known after apply)                                    
              [32m+[39m status         = (known after apply)                                    
              [32m+[39m surge_upgrade  = true           
              [32m+[39m tags           = [              
                  [32m+[39m "d1",   
                  [32m+[39m "my-tag",                   
                ]           
              [32m+[39m updated_at     = (known after apply)                                    
              [32m+[39m urn            = (known after apply)                                    
              [32m+[39m version        = "1.21.2-do.2"  
              [32m+[39m vpc_uuid       = (known after apply)                                    
        
              [32m+[39m maintenance_policy {            
                  [32m+[39m day        = (known after apply)                                    
                  [32m+[39m duration   = (known after apply)                                    
                  [32m+[39m start_time = (known after apply)                                    
                }           
        
              [32m+[39m node_pool { 
                  [32m+[39m actual_node_count = (known after apply)                             
                  [32m+[39m auto_scale        = false   
                  [32m+[39m id                = (known after apply)                             
                  [32m+[39m name              = "default-pool"                                  
                  [32m+[39m node_count        = 2       
                  [32m+[39m nodes             = (known after apply)                             
                  [32m+[39m size              = "s-1vcpu-2gb"                                   
                  [32m+[39m tags              = [       
                      [32m+[39m "node-pool-tag",        
                    ]       
                }           
            }               
        
        [1m  # digitalocean_kubernetes_node_pool.app_node_pool[0m[39m[49m will be created             
          [32m+[39m resource "digitalocean_kubernetes_node_pool" "app_node_pool" {              
              [32m+[39m actual_node_count = (known after apply)                                 
              [32m+[39m auto_scale        = true        
              [32m+[39m cluster_id        = (known after apply)                                 
              [32m+[39m id                = (known after apply)                                 
              [32m+[39m labels            = {           
                  [32m+[39m "priority" = "high"         
                  [32m+[39m "service"  = "apps"         
                }           
              [32m+[39m max_nodes         = 10          
              [32m+[39m min_nodes         = 2           
              [32m+[39m name              = "app-pool"  
              [32m+[39m nodes             = (known after apply)                                 
              [32m+[39m size              = "s-2vcpu-4gb"                                       
              [32m+[39m tags              = [           
                  [32m+[39m "applications",             
                ]           
            }               
        
        [1mPlan:[0m[39m[49m 2 to add, 0 to change, 0 to destroy.                                      
        
        [90m───────────────────────────────────────────────────────────────────────────────[39m 
        
        Note: You didn't use the -out option to save this plan, so Terraform can't      
        guarantee to take exactly these actions if you run "terraform apply" now.
    
    


<!-- id: a83f4712457c517166019262b44fbf7a -->

Create it:

<!-- have seen 5minutes for mgmt pool -->
<!-- id: da37cc47e3563b6b6b1ec93c56c844a4 -->

=== "Cmd"
    
    ```console
    $ time tf apply -auto-approve
    ```

=== "Output"

    
    <xterm />
    
        $ time tf apply -auto-approve                         
        
        Terraform used the selected providers to generate the following execution plan. 
        Resource actions are indicated with the following symbols:                      
          [32m+[39m create          
        
        Terraform will perform the following actions:                                   
        
        [1m  # digitalocean_kubernetes_cluster.kubernetes_cluster[0m[39m[49m will be created          
          [32m+[39m resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {           
              [32m+[39m cluster_subnet = (known after apply)                                    
              [32m+[39m created_at     = (known after apply)                                    
              [32m+[39m endpoint       = (known after apply)                                    
              [32m+[39m id             = (known after apply)                                    
              [32m+[39m ipv4_address   = (known after apply)                                    
              [32m+[39m kube_config    = (sensitive value)                                      
              [32m+[39m name           = "tf-do-cluster-d1"                                     
              [32m+[39m region         = "fra1"         
              [32m+[39m service_subnet = (known after apply)                                    
              [32m+[39m status         = (known after apply)                                    
              [32m+[39m surge_upgrade  = true           
              [32m+[39m tags           = [              
                  [32m+[39m "d1",   
                  [32m+[39m "my-tag",                   
                ]           
              [32m+[39m updated_at     = (known after apply)                                    
              [32m+[39m urn            = (known after apply)                                    
              [32m+[39m version        = "1.21.2-do.2"  
              [32m+[39m vpc_uuid       = (known after apply)                                    
        
              [32m+[39m maintenance_policy {            
                  [32m+[39m day        = (known after apply)                                    
                  [32m+[39m duration   = (known after apply)                                    
                  [32m+[39m start_time = (known after apply)                                    
                }           
        
              [32m+[39m node_pool { 
                  [32m+[39m actual_node_count = (known after apply)                             
                  [32m+[39m auto_scale        = false   
                  [32m+[39m id                = (known after apply)                             
                  [32m+[39m name              = "default-pool"                                  
                  [32m+[39m node_count        = 2       
                  [32m+[39m nodes             = (known after apply)                             
                  [32m+[39m size              = "s-1vcpu-2gb"                                   
                  [32m+[39m tags              = [       
                      [32m+[39m "node-pool-tag",        
                    ]       
                }           
            }               
        
        [1m  # digitalocean_kubernetes_node_pool.app_node_pool[0m[39m[49m will be created             
          [32m+[39m resource "digitalocean_kubernetes_node_pool" "app_node_pool" {              
              [32m+[39m actual_node_count = (known after apply)                                 
              [32m+[39m auto_scale        = true        
              [32m+[39m cluster_id        = (known after apply)                                 
              [32m+[39m id                = (known after apply)                                 
              [32m+[39m labels            = {           
                  [32m+[39m "priority" = "high"         
                  [32m+[39m "service"  = "apps"         
                }           
              [32m+[39m max_nodes         = 10          
              [32m+[39m min_nodes         = 2           
              [32m+[39m name              = "app-pool"  
              [32m+[39m nodes             = (known after apply)                                 
              [32m+[39m size              = "s-2vcpu-4gb"                                       
              [32m+[39m tags              = [           
                  [32m+[39m "applications",             
                ]           
            }               
        
        [1mPlan:[0m[39m[49m 2 to add, 0 to change, 0 to destroy.                                      
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Creating...[0m[39m[49m                 
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [10s elapsed][0m[39m[49m                    
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [20s elapsed][0m[39m[49m                    
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [30s elapsed][0m[39m[49m                    
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [40s elapsed][0m[39m[49m                    
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [50s elapsed][0m[39m[49m                    
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [1m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [2m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [3m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [4m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [5m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [6m50s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [7m0s elapsed][0m[39m[49m                   
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [7m10s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [7m20s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [7m30s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Still creating... [7m40s elapsed][0m[39m[49m                  
        [1mdigitalocean_kubernetes_cluster.kubernetes_cluster: Creation complete after 7m43s [id=c8d707ee-e897-48a6-8c03-81f53bb66315][0m[39m[49m     
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Creating...[0m[39m[49m                                           
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [10s elapsed][0m[39m[49m                       
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [20s elapsed][0m[39m[49m                       
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [30s elapsed][0m[39m[49m                       
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [40s elapsed][0m[39m[49m                       
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [50s elapsed][0m[39m[49m                       
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [1m0s elapsed][0m[39m[49m                      
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [1m10s elapsed][0m[39m[49m                     
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [1m20s elapsed][0m[39m[49m                     
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Still creating... [1m30s elapsed][0m[39m[49m                     
        [1mdigitalocean_kubernetes_node_pool.app_node_pool: Creation complete after 1m31s [id=570843a6-fd87-4483-9e31-44a2727b7388][0m[39m[49m        
        
        [1m[32mApply complete! Resources: 2 added, 0 changed, 0 destroyed.[0m[39m[49m                                            
        
        real    9m15.960s        
        user    0m1.665s         
        sys     0m0.322s
    
    


<!-- id: da37cc47e3563b6b6b1ec93c56c844a4 -->

Should be done in a few minutes. Large variations, I saw between 5 and 15 minutes...

## Configure `kubectl`

!!! note "why?"
    No matter how much we'll do in terraform or other tools, a configured kubectl is a must - and if it is
    only to crosscheck.

<!-- id: c02ab9a58c50c40f86596e478c319c35 -->

=== "Cmd"
    
    ```console
    $ doctl kubernetes cluster kubeconfig save "$clustername" # lp: asserts="Adding cluster"
    $ kubectl cluster-info                                    # lp: asserts="control plane"
    $ k cluster-info dump | wc -l                             # hf ;-)
    ```

=== "Output"

    
    <xterm />
    
        $ doctl kubernetes cluster kubeconfig save "$clustername"                    
        [32mNotice[39m: Adding cluster credentials to kubeconfig file found in "/home/gk/.kube/config"                 
        [32mNotice[39m: Setting current-context to do-fra1-tf-do-cluster-d1
        $ kubectl cluster-info                                                       
        [32mKubernetes control plane[39m is running at [33mhttps://c8d707ee-e897-48a6-8c03-81f53bb66315.k8s.ondigitalocean.com[39m                      
        [32mCoreDNS[39m is running at [33mhttps://c8d707ee-e897-48a6-8c03-81f53bb66315.k8s.ondigitalocean.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy[39m       
        
        To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
        $ k cluster-info dump | wc -l                             # hf ;-)                                     
        13850                    
        $ 
    
    


<!-- id: c02ab9a58c50c40f86596e478c319c35 -->

The first command configures the default cluster for `kubectl`, no need to specify the name then, when you
work "only" with one.


<!-- id: 5f0194057674c1687fd6b6f37d1b78f4 -->
<xterm />

    $ k get nodes            
    NAME                 STATUS     ROLES    AGE     VERSION                                               
    app-pool-84uox       NotReady   <none>   8s      v1.21.2                                               
    app-pool-84uoy       NotReady   <none>   3s      v1.21.2                                               
    default-pool-84ux8   Ready      <none>   3m24s   v1.21.2                                               
    default-pool-84uxu   Ready      <none>   4m57s   v1.21.2


<!-- id: 5f0194057674c1687fd6b6f37d1b78f4 -->


### [Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) Image Pulling 

You want the container orchestrator (here Kubernetes) to pull from your private registry. The simplest way to do so
is:

- "Docker login" there
- Tell K8s about it

<!-- id: a7e8e9072e53c5d92136435df12687fa -->

=== "Cmd"
    
    ```console
    $ podman login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"
    $ fn=$XDG_RUNTIME_DIR/containers/auth.json # podman's location. docker: elsewhere
    $ k create secret generic regcred --from-file=".dockerconfigjson=$fn"  --type=kubernetes.io/dockerconfigjson # lp: asserts=regcred
    ```

=== "Output"

    
    <xterm />
    
        $ podman login "$(pass show reg/domain)" -u $(pass show reg/user) -p "$(pass show reg/passw)"         
        Login Succeeded!
        $ fn=$XDG_RUNTIME_DIR/containers/auth.json # podman's location. docker: elsewhere                      
        $ 
        $ k create secret generic regcred --from-file=".dockerconfigjson=$fn"  --type=kubernetes.io/dockerconfigjson                    
        secret/regcred created
    
    


<!-- id: a7e8e9072e53c5d92136435df12687fa -->

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




