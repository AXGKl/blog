# Creating Resources with Terraform (TF)

Basic Mechanics


## Requirements

- SSH key pair, authorized in DO 
- Valid API key, e.g. available via [pass][pass]
- `terraform` executable locally on your system


<xterm />

    $ ls ~/.ssh/id_rsa* | grep terra
    /home/gk/.ssh/id_rsa_terraform
    /home/gk/.ssh/id_rsa_terraform.pub
    $ pass show DO/pat | head -c 8
    7ba23738
    $ terraform -h | head
    Usage: terraform [global options] <subcommand> [args]
    
    The available commands for execution are listed below.
    The primary workflow commands are given first, followed by
    less common or more advanced commands.
    
    Main commands:
      init          Prepare your working directory for other commands
      validate      Check whether the configuration is valid
      plan          Show changes required by the current configuration



## Initializing

Then configure basic vars:


<xterm />

    $ export D="$DT_PROJECT_ROOT/tmp/clusters/DO/basic"
    $ export TF_VAR_do_token="$(pass show DO/pat)"
    $ alias tf=terraform
    $ mkdir -p "$D"
    $ cd "$D"



Just go sure we are clean on DO and locally, at start of this tutorial:



=== "Cmd"
    
    ```console
    $ tf destroy -auto-approve -lock=false
    $ rm -rf *
    ```

=== "Output"

    
    <xterm />
    
        $ tf destroy -auto-approve -lock=false  
        
        [1mChanges to Outputs:[0m[39m[49m 
        
        You can apply this plan to save these new output values to the Terraform state, 
        without changing any real infrastructure.                                       
        
        [1m[32mDestroy complete! Resources: 0 destroyed.[0m[39m[49m                                       
        $
        $ rm -rf *
    
    




Create a file for DO provider:


```json
$ cat provider.tf
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

data "digitalocean_ssh_key" "terraform" {
      name = "terraform"
}
provider "digitalocean" {
    token = var.do_token
}


variable "do_token" {
    // have run: export TF_VAR_do_token=`pass show DO/pat`
    // cli also possible: -var=do_token=...
}

variable "pvt_key" {
  default = "~/.ssh/id_rsa_terraform"
}

variable "master_size" {
  default = "4gb"
}

variable "node_size" {
  default = "4gb"
}

variable "region" {
  default = "fra1"
}
```

Provider: This encapsulates the translation from the Terraform definition to the DigitalOcean API.



!!! note "Variables"

    - are defined like that to allow further attributes for the terraform UI, e.g. sensitivity,
      type.
    - are "doing nothing" - they just provide static constants for functions within .tf files,
      throughout the directory (see also `var.pvt_key` below)
    - usually defined in an own file or even hierarchy of files 

The provider file allows to init terraform now:



=== "Cmd"
    
    ```console
    $ tf init
    $ tree -lta
    ```

=== "Output"

    
    <xterm />
    
        $ tf init     
        
        [1mInitializing the backend...[0m[39m[49m             
        
        [1mInitializing provider plugins...[0m[39m[49m        
        - Finding digitalocean/digitalocean versions matching "~> 2.0"...               
        - Installing digitalocean/digitalocean v2.10.1...                               
        - Installed digitalocean/digitalocean v2.10.1 (signed by a HashiCorp partner, key ID [1mF82037E524B9C0E8[0m[39m[49m)                  
        
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
        $ tree -lta   
        [1m[34m.[0m[39m[49m                   
        ├── provider.tf     
        ├── [1m[34m.terraform[0m[39m[49m      
        │   └── [1m[34mproviders[0m[39m[49m   
        │       └── [1m[34mregistry.terraform.io[0m[39m[49m       
        │           └── [1m[34mdigitalocean[0m[39m[49m            
        │               └── [1m[34mdigitalocean[0m[39m[49m        
        │                   └── [1m[34m2.10.1[0m[39m[49m          
        │                       └── [1m[34mlinux_amd64[0m[39m[49m 
        │                           ├── CHANGELOG.md                                    
        │                           ├── LICENSE 
        │                           ├── README.md                                       
        │                           └── [1m[32mterraform-provider-digitalocean_v2.10.1[0m[39m[49m         
        └── .terraform.lock.hcl                 
        
        7 directories, 6 files
    
    



## Configuration

### Worker Nodes

Create two more files for worker nodes:


```json
$ cat www-1.tf
resource "digitalocean_droplet" "www-1" {
  image = "ubuntu-20-04-x64"
  name = "www-1"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt -qq update",
      "sudo apt -qq install -yq -o Dpkg::Use-Pty=0 nginx"
    ]
  }
}
```

Second worker:



=== "Cmd"
    
    ```console
    $ sed 's/www-1/www-2/g' www-1.tf > www-2.tf
    ```

=== "Output"

    
    <xterm />
    
        $ sed 's/www-1/www-2/g' www-1.tf > www-2.tf
    
    



### Load Balancer

Also we configure a loadbalancer. Here you see cloud provider specific features of TF:



=== "Cmd"
    
    ```console
    $ cat << EOF > loadbalancer.tf
    resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {
      name = "www-lb-gk-tftest"
      region = "fra1"
    
      forwarding_rule {
        entry_port = 80
        entry_protocol = "http"
    
        target_port = 80
        target_protocol = "http"
      }
    
      healthcheck {
        port = 80 
        protocol = "tcp"
      }
    
      droplet_ids = [digitalocean_droplet.www-1.id, digitalocean_droplet.www-2.id ]
    }
    EOF
    ```

=== "Output"

    
    <xterm />
    
        $ cat << EOF > loadbalancer.tf          
        > resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {                     
        >   name = "www-lb-gk-tftest"           
        >   region = "fra1" 
        >                   
        >   forwarding_rule {                   
        >     entry_port = 80                   
        >     entry_protocol = "http"           
        >                   
        >     target_port = 80                  
        >     target_protocol = "http"          
        >   }               
        >                   
        >   healthcheck {   
        >     port = 80     
        >     protocol = "tcp"                  
        >   }               
        >                   
        >   droplet_ids = [digitalocean_droplet.www-1.id, digitalocean_droplet.www-2.id ]                   
        > }                 
        > EOF               
        $ 
    
    



### Outputs Demo

This way we can information to the `tf apply` output, ready for others to consume:



=== "Cmd"
    
    ```console
    $ cat <<'ENDL' > outputs.tf
    output "ip1" {
        description = "The Droplet www-1 ipv4 address"
        value = "${digitalocean_droplet.www-1.ipv4_address}"
    }
    
    output "ip2" {
        description = "The Droplet www-2 ipv4 address"
        value = "${digitalocean_droplet.www-2.ipv4_address}"
    }
    
    ENDL
    ```

=== "Output"

    
    <xterm />
    
        $ cat <<'ENDL' > outputs.tf             
        > output "ip1" {    
        >     description = "The Droplet www-1 ipv4 address"                            
        >     value = "${digitalocean_droplet.www-1.ipv4_address}"                      
        > }                 
        >                   
        > output "ip2" {    
        >     description = "The Droplet www-2 ipv4 address"                            
        >     value = "${digitalocean_droplet.www-2.ipv4_address}"                      
        > }                 
        >                   
        > ENDL              
        $ 
    
    



## Plan & Apply

`tf plan` shows current state:



=== "Cmd"
    
    ```console
    $ tf plan
    ```

=== "Output"

    
    <xterm />
    
        $ tf plan     
        
        Terraform used the selected providers to generate the following execution plan. 
        Resource actions are indicated with the following symbols:                      
          [32m+[39m create          
        
        Terraform will perform the following actions:                                   
        
        [1m  # digitalocean_droplet.www-1[0m[39m[49m will be created                                  
          [32m+[39m resource "digitalocean_droplet" "www-1" {                                   
              [32m+[39m backups              = false    
              [32m+[39m created_at           = (known after apply)                              
              [32m+[39m disk                 = (known after apply)                              
              [32m+[39m id                   = (known after apply)                              
              [32m+[39m image                = "ubuntu-20-04-x64"                               
              [32m+[39m ipv4_address         = (known after apply)                              
              [32m+[39m ipv4_address_private = (known after apply)                              
              [32m+[39m ipv6                 = false    
              [32m+[39m ipv6_address         = (known after apply)                              
              [32m+[39m locked               = (known after apply)                              
              [32m+[39m memory               = (known after apply)                              
              [32m+[39m monitoring           = false    
              [32m+[39m name                 = "www-1"  
              [32m+[39m price_hourly         = (known after apply)                              
              [32m+[39m price_monthly        = (known after apply)                              
              [32m+[39m private_networking   = true     
              [32m+[39m region               = "fra1"   
              [32m+[39m resize_disk          = true     
              [32m+[39m size                 = "s-1vcpu-1gb"                                    
              [32m+[39m ssh_keys             = [        
                  [32m+[39m "30935145",                 
                ]           
              [32m+[39m status               = (known after apply)                              
              [32m+[39m urn                  = (known after apply)                              
              [32m+[39m vcpus                = (known after apply)                              
              [32m+[39m volume_ids           = (known after apply)                              
              [32m+[39m vpc_uuid             = (known after apply)                              
            }               
        
        [1m  # digitalocean_droplet.www-2[0m[39m[49m will be created                                  
          [32m+[39m resource "digitalocean_droplet" "www-2" {                                   
              [32m+[39m backups              = false    
              [32m+[39m created_at           = (known after apply)                              
              [32m+[39m disk                 = (known after apply)                              
              [32m+[39m id                   = (known after apply)                              
              [32m+[39m image                = "ubuntu-20-04-x64"                               
              [32m+[39m ipv4_address         = (known after apply)                              
              [32m+[39m ipv4_address_private = (known after apply)                              
              [32m+[39m ipv6                 = false    
              [32m+[39m ipv6_address         = (known after apply)                              
              [32m+[39m locked               = (known after apply)                              
              [32m+[39m memory               = (known after apply)                              
              [32m+[39m monitoring           = false    
              [32m+[39m name                 = "www-2"  
              [32m+[39m price_hourly         = (known after apply)                              
              [32m+[39m price_monthly        = (known after apply)                              
              [32m+[39m private_networking   = true     
              [32m+[39m region               = "fra1"   
              [32m+[39m resize_disk          = true     
              [32m+[39m size                 = "s-1vcpu-1gb"                                    
              [32m+[39m ssh_keys             = [        
                  [32m+[39m "30935145",                 
                ]           
              [32m+[39m status               = (known after apply)                              
              [32m+[39m urn                  = (known after apply)                              
              [32m+[39m vcpus                = (known after apply)                              
              [32m+[39m volume_ids           = (known after apply)                              
              [32m+[39m vpc_uuid             = (known after apply)                              
            }               
        
        [1m  # digitalocean_loadbalancer.www-lb-gk-tftest[0m[39m[49m will be created                  
          [32m+[39m resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {                   
              [32m+[39m algorithm                = "round_robin"                                
              [32m+[39m droplet_ids              = (known after apply)                          
              [32m+[39m enable_backend_keepalive = false
              [32m+[39m enable_proxy_protocol    = false
              [32m+[39m id                       = (known after apply)                          
              [32m+[39m ip                       = (known after apply)                          
              [32m+[39m name                     = "www-lb-gk-tftest"                           
              [32m+[39m redirect_http_to_https   = false
              [32m+[39m region                   = "fra1"                                       
              [32m+[39m size                     = "lb-small"                                   
              [32m+[39m status                   = (known after apply)                          
              [32m+[39m urn                      = (known after apply)                          
              [32m+[39m vpc_uuid                 = (known after apply)                          
        
              [32m+[39m forwarding_rule {               
                  [32m+[39m certificate_id   = (known after apply)                              
                  [32m+[39m certificate_name = (known after apply)                              
                  [32m+[39m entry_port       = 80       
                  [32m+[39m entry_protocol   = "http"   
                  [32m+[39m target_port      = 80       
                  [32m+[39m target_protocol  = "http"   
                  [32m+[39m tls_passthrough  = false    
                }           
        
              [32m+[39m healthcheck {                   
                  [32m+[39m check_interval_seconds   = 10                                       
                  [32m+[39m healthy_threshold        = 5
                  [32m+[39m port                     = 80                                       
                  [32m+[39m protocol                 = "tcp"                                    
                  [32m+[39m response_timeout_seconds = 5
                  [32m+[39m unhealthy_threshold      = 3
                }           
        
              [32m+[39m sticky_sessions {               
                  [32m+[39m cookie_name        = (known after apply)                            
                  [32m+[39m cookie_ttl_seconds = (known after apply)                            
                  [32m+[39m type               = (known after apply)                            
                }           
            }               
        
        [1mPlan:[0m[39m[49m 3 to add, 0 to change, 0 to destroy.                                      
        
        [1mChanges to Outputs:[0m[39m[49m 
          [32m+[39m ip1 = (known after apply)           
          [32m+[39m ip2 = (known after apply)           
        
        [90m───────────────────────────────────────────────────────────────────────────────[39m 
        
        Note: You didn't use the -out option to save this plan, so Terraform can't      
        guarantee to take exactly these actions if you run "terraform apply" now.
    
    



Ready to apply, that command will now create the nodes (takes a minute):



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
        
        [1m  # digitalocean_droplet.www-1[0m[39m[49m will be created                                  
          [32m+[39m resource "digitalocean_droplet" "www-1" {                                   
              [32m+[39m backups              = false    
              [32m+[39m created_at           = (known after apply)                              
              [32m+[39m disk                 = (known after apply)                              
              [32m+[39m id                   = (known after apply)                              
              [32m+[39m image                = "ubuntu-20-04-x64"                               
              [32m+[39m ipv4_address         = (known after apply)                              
              [32m+[39m ipv4_address_private = (known after apply)                              
              [32m+[39m ipv6                 = false    
              [32m+[39m ipv6_address         = (known after apply)                              
              [32m+[39m locked               = (known after apply)                              
              [32m+[39m memory               = (known after apply)                              
              [32m+[39m monitoring           = false    
              [32m+[39m name                 = "www-1"  
              [32m+[39m price_hourly         = (known after apply)                              
              [32m+[39m price_monthly        = (known after apply)                              
              [32m+[39m private_networking   = true     
              [32m+[39m region               = "fra1"   
              [32m+[39m resize_disk          = true     
              [32m+[39m size                 = "s-1vcpu-1gb"                                    
              [32m+[39m ssh_keys             = [        
                  [32m+[39m "30935145",                 
                ]           
              [32m+[39m status               = (known after apply)                              
              [32m+[39m urn                  = (known after apply)                              
              [32m+[39m vcpus                = (known after apply)                              
              [32m+[39m volume_ids           = (known after apply)                              
              [32m+[39m vpc_uuid             = (known after apply)                              
            }               
        
        [1m  # digitalocean_droplet.www-2[0m[39m[49m will be created                                  
          [32m+[39m resource "digitalocean_droplet" "www-2" {                                   
              [32m+[39m backups              = false    
              [32m+[39m created_at           = (known after apply)                              
              [32m+[39m disk                 = (known after apply)                              
              [32m+[39m id                   = (known after apply)                              
              [32m+[39m image                = "ubuntu-20-04-x64"                               
              [32m+[39m ipv4_address         = (known after apply)                              
              [32m+[39m ipv4_address_private = (known after apply)                              
              [32m+[39m ipv6                 = false    
              [32m+[39m ipv6_address         = (known after apply)                              
              [32m+[39m locked               = (known after apply)                              
              [32m+[39m memory               = (known after apply)                              
              [32m+[39m monitoring           = false    
              [32m+[39m name                 = "www-2"  
              [32m+[39m price_hourly         = (known after apply)                              
              [32m+[39m price_monthly        = (known after apply)                              
              [32m+[39m private_networking   = true     
              [32m+[39m region               = "fra1"   
              [32m+[39m resize_disk          = true     
              [32m+[39m size                 = "s-1vcpu-1gb"                                    
              [32m+[39m ssh_keys             = [        
                  [32m+[39m "30935145",                 
                ]           
              [32m+[39m status               = (known after apply)                              
              [32m+[39m urn                  = (known after apply)                              
              [32m+[39m vcpus                = (known after apply)                              
              [32m+[39m volume_ids           = (known after apply)                              
              [32m+[39m vpc_uuid             = (known after apply)                              
            }               
        
        [1m  # digitalocean_loadbalancer.www-lb-gk-tftest[0m[39m[49m will be created                  
          [32m+[39m resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {                   
              [32m+[39m algorithm                = "round_robin"                                
              [32m+[39m droplet_ids              = (known after apply)                          
              [32m+[39m enable_backend_keepalive = false
              [32m+[39m enable_proxy_protocol    = false
              [32m+[39m id                       = (known after apply)                          
              [32m+[39m ip                       = (known after apply)                          
              [32m+[39m name                     = "www-lb-gk-tftest"                           
              [32m+[39m redirect_http_to_https   = false
              [32m+[39m region                   = "fra1"                                       
              [32m+[39m size                     = "lb-small"                                   
              [32m+[39m status                   = (known after apply)                          
              [32m+[39m urn                      = (known after apply)                          
              [32m+[39m vpc_uuid                 = (known after apply)                          
        
              [32m+[39m forwarding_rule {               
                  [32m+[39m certificate_id   = (known after apply)                              
                  [32m+[39m certificate_name = (known after apply)                              
                  [32m+[39m entry_port       = 80       
                  [32m+[39m entry_protocol   = "http"   
                  [32m+[39m target_port      = 80       
                  [32m+[39m target_protocol  = "http"   
                  [32m+[39m tls_passthrough  = false    
                }           
        
              [32m+[39m healthcheck {                   
                  [32m+[39m check_interval_seconds   = 10                                       
                  [32m+[39m healthy_threshold        = 5
                  [32m+[39m port                     = 80                                       
                  [32m+[39m protocol                 = "tcp"                                    
                  [32m+[39m response_timeout_seconds = 5
                  [32m+[39m unhealthy_threshold      = 3
                }           
        
              [32m+[39m sticky_sessions {               
                  [32m+[39m cookie_name        = (known after apply)                            
                  [32m+[39m cookie_ttl_seconds = (known after apply)                            
                  [32m+[39m type               = (known after apply)                            
                }           
            }               
        
        [1mPlan:[0m[39m[49m 3 to add, 0 to change, 0 to destroy.                                      
        
        [1mChanges to Outputs:[0m[39m[49m 
          [32m+[39m ip1 = (known after apply)           
          [32m+[39m ip2 = (known after apply)           
        [1mdigitalocean_droplet.www-2: Creating...[0m[39m[49m 
        [1mdigitalocean_droplet.www-1: Creating...[0m[39m[49m 
        [1mdigitalocean_droplet.www-1: Still creating... [10s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-2: Still creating... [10s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-2: Still creating... [20s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1: Still creating... [20s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-2: Still creating... [30s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1: Still creating... [30s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1: Provisioning with 'remote-exec'...[0m[39m[49m                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Connecting to remote host via SSH...  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Host: 161.35.194.251                
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   User: root                          
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Password: false                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Private key: true                   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Certificate: false                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   SSH Agent: true                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Checking Host Key: false            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Target Platform: unix               
        [1mdigitalocean_droplet.www-2: Provisioning with 'remote-exec'...[0m[39m[49m                  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Connecting to remote host via SSH...  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Host: 161.35.194.255                
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   User: root                          
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Password: false                     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Private key: true                   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Certificate: false                  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   SSH Agent: true                     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Checking Host Key: false            
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Target Platform: unix               
        [1mdigitalocean_droplet.www-2: Still creating... [40s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1: Still creating... [40s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Connecting to remote host via SSH...  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Host: 161.35.194.251                
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   User: root                          
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Password: false                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Private key: true                   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Certificate: false                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   SSH Agent: true                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Checking Host Key: false            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Target Platform: unix               
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Connecting to remote host via SSH...  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Host: 161.35.194.255                
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   User: root                          
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Password: false                     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Private key: true                   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Certificate: false                  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   SSH Agent: true                     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Checking Host Key: false            
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   Target Platform: unix               
        [1mdigitalocean_droplet.www-1: Still creating... [50s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-2: Still creating... [50s elapsed][0m[39m[49m                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Connecting to remote host via SSH...  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Host: 161.35.194.251                
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   User: root                          
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Password: false                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Private key: true                   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Certificate: false                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   SSH Agent: true                     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Checking Host Key: false            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   Target Platform: unix               
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Connected!                            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Connected!                            
        [1mdigitalocean_droplet.www-2: Still creating... [1m0s elapsed][0m[39m[49m                    
        [1mdigitalocean_droplet.www-1: Still creating... [1m0s elapsed][0m[39m[49m                    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Traceback (most recent call last):    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   File "/usr/lib/cnf-update-db", line 26, in <module>     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m     col.create(db)                    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   File "/usr/lib/python3/dist-packages/CommandNotFound/db/creator.py", line 94, in create                             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m     self._fill_commands(con)          
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m   File "/usr/lib/python3/dist-packages/CommandNotFound/db/creator.py", line 137, in _fill_commands                    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m     with open(f) as fp:               
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_focal_restricted_cnf_Commands-amd64'              
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m [1m[31mE: [0m[39m[49mProblem executing scripts APT::Update::Post-Invoke-Success 'if /usr/bin/test -w /var/lib/command-not-found/ -a -e /usr/lib/cnf-update-db; then /usr/lib/cnf-update-db > /dev/null; fi'             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m [1m[31mE: [0m[39m[49mSub-process returned an error code 
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preconfiguring packages ...           
                                                  Selecting previously unselected package fonts-dejavu-core.[1m.www-2 (remote-exec):[0m[39m[49m                                       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Traceback (most recent call last):    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   File "/usr/lib/cnf-update-db", line 26, in <module>     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m     col.create(db)                    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   File "/usr/lib/python3/dist-packages/CommandNotFound/db/creator.py", line 94, in create                             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m     self._fill_commands(con)          
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m   File "/usr/lib/python3/dist-packages/CommandNotFound/db/creator.py", line 137, in _fill_commands                    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m     with open(f) as fp:               
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_focal-backports_main_cnf_Commands-amd64'          
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ...                 
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 5%              
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 10%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 15%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 20%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 25%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 30%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 35%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 40%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 45%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 50%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 55%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 60%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 65%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 70%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 75%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 80%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 85%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 90%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 95%             
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 100%            
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m (Reading database ... 63520 files and directories currently installed.)       
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../00-fonts-dejavu-core_2.37-1_all.deb ...               
        [30m[42mProgress: [  1%][39m[49m [..................] [1mc):[0m[39m[49m Unpacking fonts-dejavu-core (2.37-1) ...                  
        [30m[42mProgress: [  3%][39m[49m [..................] [1mc):[0m[39m[49m Selecting previously unselected package fontconfig-config.                    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../01-fontconfig-config_2.13.1-2ubuntu3_all.deb ...      
        [30m[42mProgress: [  4%][39m[49m [..................] [1mc):[0m[39m[49m Unpacking fontconfig-config (2.13.1-2ubuntu3) ...         
        [30m[42mProgress: [  6%][39m[49m [#.................] [1mc):[0m[39m[49m Selecting previously unselected package libfontconfig1:amd64.                 
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../02-libfontconfig1_2.13.1-2ubuntu3_amd64.deb ...       
        [30m[42mProgress: [  7%][39m[49m [#.................] [1mc):[0m[39m[49m Unpacking libfontconfig1:amd64 (2.13.1-2ubuntu3) ...      
        [30m[42mProgress: [  9%][39m[49m [#.................] [1mc):[0m[39m[49m Selecting previously unselected package libjpeg-turbo8:amd64.                 
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../03-libjpeg-turbo8_2.0.3-0ubuntu1.20.04.1_amd64.deb ...                                        
        [30m[42mProgress: [ 10%][39m[49m [#.................] [1mc):[0m[39m[49m Unpacking libjpeg-turbo8:amd64 (2.0.3-0ubuntu1.20.04.1) ...                   
        [30m[42mProgress: [ 12%][39m[49m [##................] [1mc):[0m[39m[49m Selecting previously unselected package libjpeg8:amd64.   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../04-libjpeg8_8c-2ubuntu8_amd64.deb ...                 
        [30m[42mProgress: [ 13%][39m[49m [##................] [1mc):[0m[39m[49m Unpacking libjpeg8:amd64 (8c-2ubuntu8) ...                
        [30m[42mProgress: [ 14%][39m[49m [##................] [1mc):[0m[39m[49m Selecting previously unselected package libjbig0:amd64.   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../05-libjbig0_2.1-3.1build1_amd64.deb ...               
        [30m[42mProgress: [ 16%][39m[49m [##................] [1mc):[0m[39m[49m Unpacking libjbig0:amd64 (2.1-3.1build1) ...              
        [30m[42mProgress: [ 17%][39m[49m [###...............] [1mc):[0m[39m[49m Selecting previously unselected package libwebp6:amd64.   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../06-libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb ...      
        [30m[42mProgress: [ 19%][39m[49m [###...............] [1mc):[0m[39m[49m Unpacking libwebp6:amd64 (0.6.1-2ubuntu0.20.04.1) ...     
        [30m[42mProgress: [ 20%][39m[49m [###...............] [1mc):[0m[39m[49m Selecting previously unselected package libtiff5:amd64.   
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../07-libtiff5_4.1.0+git191117-2ubuntu0.20.04.1_amd64.deb ...                                    
        [30m[42mProgress: [ 22%][39m[49m [###...............] [1mc):[0m[39m[49m Unpacking libtiff5:amd64 (4.1.0+git191117-2ubuntu0.20.04.1) ...               
        [30m[42mProgress: [ 23%][39m[49m [####..............] [1mc):[0m[39m[49m Selecting previously unselected package libxpm4:amd64.    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../08-libxpm4_1%3a3.5.12-1_amd64.deb ...                 
        [30m[42mProgress: [ 25%][39m[49m [####..............] [1mc):[0m[39m[49m Unpacking libxpm4:amd64 (1:3.5.12-1) ...                  
        [30m[42mProgress: [ 26%][39m[49m [####..............] [1mc):[0m[39m[49m Selecting previously unselected package libgd3:amd64.     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../09-libgd3_2.2.5-5.2ubuntu2_amd64.deb ...              
        [30m[42mProgress: [ 28%][39m[49m [####..............] [1mc):[0m[39m[49m Unpacking libgd3:amd64 (2.2.5-5.2ubuntu2) ...             
        [30m[42mProgress: [ 29%][39m[49m [#####.............] [1mc):[0m[39m[49m Selecting previously unselected package nginx-common.     
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../10-nginx-common_1.18.0-0ubuntu1.2_all.deb ...         
        [30m[42mProgress: [ 30%][39m[49m [#####.............] [1mc):[0m[39m[49m Unpacking nginx-common (1.18.0-0ubuntu1.2) ...            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m [1m[31mE: [0m[39m[49mProblem executing scripts APT::Update::Post-Invoke-Success 'if /usr/bin/test -w /var/lib/command-not-found/ -a -e /usr/lib/cnf-update-db; then /usr/lib/cnf-update-db > /dev/null; fi'             
        [30m[42mProgress: [ 32%][39m[49m [#####.............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-http-image-filter.       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m [1m[31mE: [0m[39m[49mSub-process returned an error code 
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../11-libnginx-mod-http-image-filter_1.18.0-0ubuntu1.2_amd64.deb ...                             
        [30m[42mProgress: [ 33%][39m[49m [#####.............] [1mc):[0m[39m[49m Unpacking libnginx-mod-http-image-filter (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 35%][39m[49m [######............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-http-xslt-filter.        
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../12-libnginx-mod-http-xslt-filter_1.18.0-0ubuntu1.2_amd64.deb ...                              
        [30m[42mProgress: [ 36%][39m[49m [######............] [1mc):[0m[39m[49m Unpacking libnginx-mod-http-xslt-filter (1.18.0-0ubuntu1.2) ...               
        [30m[42mProgress: [ 38%][39m[49m [######............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-mail.                    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../13-libnginx-mod-mail_1.18.0-0ubuntu1.2_amd64.deb ...  
        [30m[42mProgress: [ 39%][39m[49m [#######...........] [1mc):[0m[39m[49m Unpacking libnginx-mod-mail (1.18.0-0ubuntu1.2) ...       
        [30m[42mProgress: [ 41%][39m[49m [#######...........] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-stream.                  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../14-libnginx-mod-stream_1.18.0-0ubuntu1.2_amd64.deb ...                                        
        [30m[42mProgress: [ 42%][39m[49m [#######...........] [1mc):[0m[39m[49m Unpacking libnginx-mod-stream (1.18.0-0ubuntu1.2) ...     
        [30m[42mProgress: [ 43%][39m[49m [#######...........] [1mc):[0m[39m[49m Selecting previously unselected package nginx-core.       
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../15-nginx-core_1.18.0-0ubuntu1.2_amd64.deb ...         
        [30m[42mProgress: [ 45%][39m[49m [########..........] [1mc):[0m[39m[49m Unpacking nginx-core (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 46%][39m[49m [########..........] [1mc):[0m[39m[49m Selecting previously unselected package nginx.            
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Preparing to unpack .../16-nginx_1.18.0-0ubuntu1.2_all.deb ...                
        [30m[42mProgress: [ 48%][39m[49m [########..........] [1mc):[0m[39m[49m Unpacking nginx (1.18.0-0ubuntu1.2) ...                   
        [30m[42mProgress: [ 49%][39m[49m [########..........] [1mc):[0m[39m[49m Setting up libxpm4:amd64 (1:3.5.12-1) ...                 
        [30m[42mProgress: [ 52%][39m[49m [#########.........] [1mc):[0m[39m[49m Setting up nginx-common (1.18.0-0ubuntu1.2) ...           
        [30m[42mProgress: [ 54%][39m[49m [#########.........] [1mc):[0m[39m[49m                                       
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.        
        [1mdigitalocean_droplet.www-1: Still creating... [1m10s elapsed][0m[39m[49m                   
        [1mdigitalocean_droplet.www-2: Still creating... [1m10s elapsed][0m[39m[49m                   
        [30m[42mProgress: [ 55%][39m[49m [#########.........] [1mc):[0m[39m[49m Setting up libjbig0:amd64 (2.1-3.1build1) ...             
        [30m[42mProgress: [ 58%][39m[49m [##########........] [1mc):[0m[39m[49m Setting up libnginx-mod-http-xslt-filter (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 61%][39m[49m [##########........] [1mc):[0m[39m[49m Setting up libwebp6:amd64 (0.6.1-2ubuntu0.20.04.1) ...    
        [30m[42mProgress: [ 64%][39m[49m [###########.......] [1mc):[0m[39m[49m Setting up fonts-dejavu-core (2.37-1) ...                 
        [30m[42mProgress: [ 67%][39m[49m [###########.......] [1mc):[0m[39m[49m Setting up libjpeg-turbo8:amd64 (2.0.3-0ubuntu1.20.04.1) ...                  
        [30m[42mProgress: [ 70%][39m[49m [############......] [1mc):[0m[39m[49m Setting up libjpeg8:amd64 (8c-2ubuntu8) ...               
        [30m[42mProgress: [ 72%][39m[49m [#############.....] [1mc):[0m[39m[49m Setting up libnginx-mod-mail (1.18.0-0ubuntu1.2) ...      
        [30m[42mProgress: [ 75%][39m[49m [#############.....] [1mc):[0m[39m[49m Setting up fontconfig-config (2.13.1-2ubuntu3) ...        
        [30m[42mProgress: [ 78%][39m[49m [##############....] [1mc):[0m[39m[49m Setting up libnginx-mod-stream (1.18.0-0ubuntu1.2) ...    
        [30m[42mProgress: [ 81%][39m[49m [##############....] [1mc):[0m[39m[49m Setting up libtiff5:amd64 (4.1.0+git191117-2ubuntu0.20.04.1) ...              
        [30m[42mProgress: [ 84%][39m[49m [###############...] [1mc):[0m[39m[49m Setting up libfontconfig1:amd64 (2.13.1-2ubuntu3) ...     
        [30m[42mProgress: [ 87%][39m[49m [###############...] [1mc):[0m[39m[49m Setting up libgd3:amd64 (2.2.5-5.2ubuntu2) ...            
        [30m[42mProgress: [ 90%][39m[49m [################..] [1mc):[0m[39m[49m Setting up libnginx-mod-http-image-filter (1.18.0-0ubuntu1.2) ...             
        [30m[42mProgress: [ 93%][39m[49m [################..] [1mc):[0m[39m[49m Setting up nginx-core (1.18.0-0ubuntu1.2) ...             
        [30m[42mProgress: [ 94%][39m[49m [################..] [1mc):[0m[39m[49m                                       
        [30m[42mProgress: [ 96%][39m[49m [#################.] [1mc):[0m[39m[49m Setting up nginx (1.18.0-0ubuntu1.2) ...                  
        [30m[42mProgress: [ 99%][39m[49m [#################.] [1mc):[0m[39m[49m Processing triggers for ufw (0.36-6) ...                  
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Processing triggers for systemd (245.4-4ubuntu3.6) ...    
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Processing triggers for man-db (2.9.1-1) ...              
        [1mdigitalocean_droplet.www-2 (remote-exec):[0m[39m[49m Processing triggers for libc-bin (2.31-0ubuntu9.2) ...    
        
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preconfiguring packages ...           
                                                  Selecting previously unselected package fonts-dejavu-core.[1m.www-1 (remote-exec):[0m[39m[49m                                       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ...                 
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 5%              
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 10%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 15%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 20%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 25%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 30%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 35%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 40%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 45%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 50%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 55%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 60%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 65%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 70%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 75%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 80%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 85%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 90%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 95%             
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 100%            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m (Reading database ... 63520 files and directories currently installed.)       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../00-fonts-dejavu-core_2.37-1_all.deb ...               
        [30m[42mProgress: [  1%][39m[49m [..................] [1mc):[0m[39m[49m Unpacking fonts-dejavu-core (2.37-1) ...                  
        [30m[42mProgress: [  3%][39m[49m [..................] [1mc):[0m[39m[49m Selecting previously unselected package fontconfig-config.                    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../01-fontconfig-config_2.13.1-2ubuntu3_all.deb ...      
        [30m[42mProgress: [  4%][39m[49m [..................] [1mc):[0m[39m[49m Unpacking fontconfig-config (2.13.1-2ubuntu3) ...         
        [30m[42mProgress: [  6%][39m[49m [#.................] [1mc):[0m[39m[49m Selecting previously unselected package libfontconfig1:amd64.                 
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../02-libfontconfig1_2.13.1-2ubuntu3_amd64.deb ...       
        [30m[42mProgress: [  7%][39m[49m [#.................] [1mc):[0m[39m[49m Unpacking libfontconfig1:amd64 (2.13.1-2ubuntu3) ...      
        [30m[42mProgress: [  9%][39m[49m [#.................] [1mc):[0m[39m[49m Selecting previously unselected package libjpeg-turbo8:amd64.                 
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../03-libjpeg-turbo8_2.0.3-0ubuntu1.20.04.1_amd64.deb ...                                        
        [30m[42mProgress: [ 10%][39m[49m [#.................] [1mc):[0m[39m[49m Unpacking libjpeg-turbo8:amd64 (2.0.3-0ubuntu1.20.04.1) ...                   
        [30m[42mProgress: [ 12%][39m[49m [##................] [1mc):[0m[39m[49m Selecting previously unselected package libjpeg8:amd64.   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../04-libjpeg8_8c-2ubuntu8_amd64.deb ...                 
        [30m[42mProgress: [ 13%][39m[49m [##................] [1mc):[0m[39m[49m Unpacking libjpeg8:amd64 (8c-2ubuntu8) ...                
        [30m[42mProgress: [ 14%][39m[49m [##................] [1mc):[0m[39m[49m Selecting previously unselected package libjbig0:amd64.   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../05-libjbig0_2.1-3.1build1_amd64.deb ...               
        [30m[42mProgress: [ 16%][39m[49m [##................] [1mc):[0m[39m[49m Unpacking libjbig0:amd64 (2.1-3.1build1) ...              
        [30m[42mProgress: [ 17%][39m[49m [###...............] [1mc):[0m[39m[49m Selecting previously unselected package libwebp6:amd64.   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../06-libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb ...      
        [30m[42mProgress: [ 19%][39m[49m [###...............] [1mc):[0m[39m[49m Unpacking libwebp6:amd64 (0.6.1-2ubuntu0.20.04.1) ...     
        [30m[42mProgress: [ 20%][39m[49m [###...............] [1mc):[0m[39m[49m Selecting previously unselected package libtiff5:amd64.   
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../07-libtiff5_4.1.0+git191117-2ubuntu0.20.04.1_amd64.deb ...                                    
        [30m[42mProgress: [ 22%][39m[49m [###...............] [1mc):[0m[39m[49m Unpacking libtiff5:amd64 (4.1.0+git191117-2ubuntu0.20.04.1) ...               
        [30m[42mProgress: [ 23%][39m[49m [####..............] [1mc):[0m[39m[49m Selecting previously unselected package libxpm4:amd64.    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../08-libxpm4_1%3a3.5.12-1_amd64.deb ...                 
        [30m[42mProgress: [ 25%][39m[49m [####..............] [1mc):[0m[39m[49m Unpacking libxpm4:amd64 (1:3.5.12-1) ...                  
        [30m[42mProgress: [ 26%][39m[49m [####..............] [1mc):[0m[39m[49m Selecting previously unselected package libgd3:amd64.     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../09-libgd3_2.2.5-5.2ubuntu2_amd64.deb ...              
        [30m[42mProgress: [ 28%][39m[49m [####..............] [1mc):[0m[39m[49m Unpacking libgd3:amd64 (2.2.5-5.2ubuntu2) ...             
        [30m[42mProgress: [ 29%][39m[49m [#####.............] [1mc):[0m[39m[49m Selecting previously unselected package nginx-common.     
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../10-nginx-common_1.18.0-0ubuntu1.2_all.deb ...         
        [30m[42mProgress: [ 30%][39m[49m [#####.............] [1mc):[0m[39m[49m Unpacking nginx-common (1.18.0-0ubuntu1.2) ...            
        [30m[42mProgress: [ 32%][39m[49m [#####.............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-http-image-filter.       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../11-libnginx-mod-http-image-filter_1.18.0-0ubuntu1.2_amd64.deb ...                             
        [30m[42mProgress: [ 33%][39m[49m [#####.............] [1mc):[0m[39m[49m Unpacking libnginx-mod-http-image-filter (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 35%][39m[49m [######............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-http-xslt-filter.        
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../12-libnginx-mod-http-xslt-filter_1.18.0-0ubuntu1.2_amd64.deb ...                              
        [30m[42mProgress: [ 36%][39m[49m [######............] [1mc):[0m[39m[49m Unpacking libnginx-mod-http-xslt-filter (1.18.0-0ubuntu1.2) ...               
        [30m[42mProgress: [ 38%][39m[49m [######............] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-mail.                    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../13-libnginx-mod-mail_1.18.0-0ubuntu1.2_amd64.deb ...  
        [30m[42mProgress: [ 39%][39m[49m [#######...........] [1mc):[0m[39m[49m Unpacking libnginx-mod-mail (1.18.0-0ubuntu1.2) ...       
        [30m[42mProgress: [ 41%][39m[49m [#######...........] [1mc):[0m[39m[49m Selecting previously unselected package libnginx-mod-stream.                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../14-libnginx-mod-stream_1.18.0-0ubuntu1.2_amd64.deb ...                                        
        [30m[42mProgress: [ 42%][39m[49m [#######...........] [1mc):[0m[39m[49m Unpacking libnginx-mod-stream (1.18.0-0ubuntu1.2) ...     
        [30m[42mProgress: [ 43%][39m[49m [#######...........] [1mc):[0m[39m[49m Selecting previously unselected package nginx-core.       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../15-nginx-core_1.18.0-0ubuntu1.2_amd64.deb ...         
        [30m[42mProgress: [ 45%][39m[49m [########..........] [1mc):[0m[39m[49m Unpacking nginx-core (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 46%][39m[49m [########..........] [1mc):[0m[39m[49m Selecting previously unselected package nginx.            
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Preparing to unpack .../16-nginx_1.18.0-0ubuntu1.2_all.deb ...                
        [30m[42mProgress: [ 48%][39m[49m [########..........] [1mc):[0m[39m[49m Unpacking nginx (1.18.0-0ubuntu1.2) ...                   
        [30m[42mProgress: [ 49%][39m[49m [########..........] [1mc):[0m[39m[49m Setting up libxpm4:amd64 (1:3.5.12-1) ...                 
        [30m[42mProgress: [ 52%][39m[49m [#########.........] [1mc):[0m[39m[49m Setting up nginx-common (1.18.0-0ubuntu1.2) ...           
        [30m[42mProgress: [ 54%][39m[49m [#########.........] [1mc):[0m[39m[49m                                       
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.        
        [30m[42mProgress: [ 55%][39m[49m [#########.........] [1mc):[0m[39m[49m Setting up libjbig0:amd64 (2.1-3.1build1) ...             
        [30m[42mProgress: [ 58%][39m[49m [##########........] [1mc):[0m[39m[49m Setting up libnginx-mod-http-xslt-filter (1.18.0-0ubuntu1.2) ...              
        [30m[42mProgress: [ 61%][39m[49m [##########........] [1mc):[0m[39m[49m Setting up libwebp6:amd64 (0.6.1-2ubuntu0.20.04.1) ...    
        [30m[42mProgress: [ 64%][39m[49m [###########.......] [1mc):[0m[39m[49m Setting up fonts-dejavu-core (2.37-1) ...                 
        [30m[42mProgress: [ 67%][39m[49m [###########.......] [1mc):[0m[39m[49m Setting up libjpeg-turbo8:amd64 (2.0.3-0ubuntu1.20.04.1) ...                  
        [30m[42mProgress: [ 70%][39m[49m [############......] [1mc):[0m[39m[49m Setting up libjpeg8:amd64 (8c-2ubuntu8) ...               
        [30m[42mProgress: [ 72%][39m[49m [#############.....] [1mc):[0m[39m[49m Setting up libnginx-mod-mail (1.18.0-0ubuntu1.2) ...      
        [30m[42mProgress: [ 75%][39m[49m [#############.....] [1mc):[0m[39m[49m Setting up fontconfig-config (2.13.1-2ubuntu3) ...        
        [30m[42mProgress: [ 78%][39m[49m [##############....] [1mc):[0m[39m[49m Setting up libnginx-mod-stream (1.18.0-0ubuntu1.2) ...    
        [30m[42mProgress: [ 81%][39m[49m [##############....] [1mc):[0m[39m[49m Setting up libtiff5:amd64 (4.1.0+git191117-2ubuntu0.20.04.1) ...              
        [30m[42mProgress: [ 84%][39m[49m [###############...] [1mc):[0m[39m[49m Setting up libfontconfig1:amd64 (2.13.1-2ubuntu3) ...     
        [30m[42mProgress: [ 87%][39m[49m [###############...] [1mc):[0m[39m[49m Setting up libgd3:amd64 (2.2.5-5.2ubuntu2) ...            
        [30m[42mProgress: [ 90%][39m[49m [################..] [1mc):[0m[39m[49m Setting up libnginx-mod-http-image-filter (1.18.0-0ubuntu1.2) ...             
        [30m[42mProgress: [ 93%][39m[49m [################..] [1mc):[0m[39m[49m Setting up nginx-core (1.18.0-0ubuntu1.2) ...             
        [30m[42mProgress: [ 94%][39m[49m [################..] [1mc):[0m[39m[49m                                       
        [30m[42mProgress: [ 96%][39m[49m [#################.] [1mc):[0m[39m[49m Setting up nginx (1.18.0-0ubuntu1.2) ...                  
        [30m[42mProgress: [ 99%][39m[49m [#################.] [1mc):[0m[39m[49m Processing triggers for ufw (0.36-6) ...                  
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Processing triggers for systemd (245.4-4ubuntu3.6) ...    
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Processing triggers for man-db (2.9.1-1) ...              
        [1mdigitalocean_droplet.www-1 (remote-exec):[0m[39m[49m Processing triggers for libc-bin (2.31-0ubuntu9.2) ...    
        [1mdigitalocean_droplet.www-2: Creation complete after 1m17s [id=257772107][0m[39m[49m        
        
        [1mdigitalocean_droplet.www-1: Still creating... [1m20s elapsed][0m[39m[49m                   
        [1mdigitalocean_droplet.www-1: Creation complete after 1m22s [id=257772106][0m[39m[49m        
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Creating...[0m[39m[49m                         
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [10s elapsed][0m[39m[49m     
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [20s elapsed][0m[39m[49m     
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [30s elapsed][0m[39m[49m     
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [40s elapsed][0m[39m[49m     
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [50s elapsed][0m[39m[49m     
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m0s elapsed][0m[39m[49m    
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m10s elapsed][0m[39m[49m   
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m20s elapsed][0m[39m[49m   
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m30s elapsed][0m[39m[49m   
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m40s elapsed][0m[39m[49m   
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Still creating... [1m50s elapsed][0m[39m[49m   
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Creation complete after 1m52s [id=9f829c83-7426-4a4c-97dd-ae4d8086d38f][0m[39m[49m     
        
        [1m[32mApply complete! Resources: 3 added, 0 changed, 0 destroyed.[0m[39m[49m                     
        
        [1m[32mOutputs:[0m[39m[49m            
        
        ip1 = "161.35.194.251"                  
        ip2 = "161.35.194.255"                  
        
        real    3m14.975s   
        user    0m1.834s    
        sys     0m0.422s
    
    



!!! important "Builtin Infrastructure Dependency Management"
    
    When you study the output of the apply you'll notice that 
    1. The output vars are in deed output
    1. TF deployed the LB only AFTER the droplets were up(!) Why? Because the LB had droplet
       specific variables declared - i.e. the site won't be up until the resources are.

    **2. is a main feature of Terraform.**
    


!!! tip "Concurrency"
    There is a parallelism flag with default 10. They claim they resolve interdependencies correctly
    and order accordingly.

Since we have a statefile the next apply is idempotent but also fast:


<xterm />

    $ time tf apply -auto-approve -parallelism=5          
    [1mdigitalocean_droplet.www-2: Refreshing state... [id=257772107][0m[39m[49m                  
    [1mdigitalocean_droplet.www-1: Refreshing state... [id=257772106][0m[39m[49m                  
    [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Refreshing state... [id=9f829c83-7426-4a4c-97dd-ae4d8086d38f][0m[39m[49m               
    
    [1m[36mNote:[39m Objects have changed outside of Terraform[0m[39m[49m                                 
    
    Terraform detected the following changes made outside of Terraform since the    
    last "terraform apply":                 
    
    [1m  # digitalocean_droplet.www-2[0m[39m[49m has been changed                                 
      [33m~[39m resource "digitalocean_droplet" "www-2" {                                   
            id                   = "257772107"                                      
            name                 = "www-2"  
          [32m+[39m tags                 = []       
            [90m# (22 unchanged attributes hidden)[39m                                      
        }               
    [1m  # digitalocean_droplet.www-1[0m[39m[49m has been changed                                 
      [33m~[39m resource "digitalocean_droplet" "www-1" {                                   
            id                   = "257772106"                                      
            name                 = "www-1"  
          [32m+[39m tags                 = []       
            [90m# (22 unchanged attributes hidden)[39m                                      
        }               
    
    Unless you have made equivalent changes to your configuration, or ignored the   
    relevant attributes using ignore_changes, the following plan may include        
    actions to undo or respond to these changes.                                    
    
    [90m───────────────────────────────────────────────────────────────────────────────[39m 
    
    [1m[32mNo changes.[39m Your infrastructure matches the configuration.[0m[39m[49m                      
    
    Your configuration already matches the changes detected above. If you'd like to 
    update the Terraform state to match, create and apply a refresh-only plan:      
      terraform apply -refresh-only         
    
    [1m[32mApply complete! Resources: 0 added, 0 changed, 0 destroyed.[0m[39m[49m                     
    
    [1m[32mOutputs:[0m[39m[49m            
    
    ip1 = "161.35.194.251"                  
    ip2 = "161.35.194.255"                  
    
    real    0m2.233s    
    user    0m0.877s    
    sys     0m0.114s



Result so far: Nginx servers up:



=== "Cmd"
    
    ```console
    $ tf show
    $ tfvar () { tf state show -no-color 'digitalocean_droplet.'$1' ' | grep ''$2' '  | cut -d '=' -f 2 | xargs; }
    $ wget "http://$(tfvar www-1 ipv4_address)/" -O - | grep -i nginx
    ```

=== "Output"

    
    <xterm />
    
        $ tf show     
        # data.digitalocean_ssh_key.terraform:  
        data "digitalocean_ssh_key" "terraform" {                                       
            fingerprint = "ea:80:64:ab:58:83:14:48:90:4c:5f:ad:4b:6e:c7:9e"             
            id          = 30935145              
            name        = "terraform"           
            public_key  = <<-EOT                
                ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDF1bQhthBX6dsAc/mLY4JxJMOjlBnU0xCu4j+iZrNI4TcTnXO4ZsWRuBPch/zveofpsA4El6d9/xgeDk8OtSjS9yTT6ihnpyWmWUW5SA+Rgk6DXS1maDmcAjByz93PsEnw7I2yIe8M2dR/nFoXzRgaYXReHdAVlYDK7QtrPhZtlzqFfev0ZOU4wGgyui9KxFGlV9H1IEXbMQqe1NZ4mejcLz1xAeFwFBuhXHJS2LRis7QeGbVK+AvcP24lZzIIJ/eyA7uQZhYtLxqK6UVS0bJzgYQQ9VIXQ7FBr8GEX4cyKt7htM470OFq1gIdvXm2G7qx8dqY9EBWUsfiX+0JjkTYcggHAx5FdN4evjXOpg7NdurvNBIYlu8C+tN7hg1rwKH4Kc9A0erGbCoFIoX6hu2Goxx/UD9ofebQ1OugGrL42rnOn4SOyIYHlABmnzydr+UZhmW54a9+NVfg7hX5U2taPmIKFtLCkaKwLVRf6XELwwL6C/XEZsl3aSkCcc0kVb8= gk@axgk            
            EOT             
        }                   
        
        # digitalocean_droplet.www-1:           
        resource "digitalocean_droplet" "www-1" {                                       
            backups              = false        
            created_at           = "2021-08-03T21:57:21Z"                               
            disk                 = 25           
            id                   = "257772106"  
            image                = "ubuntu-20-04-x64"                                   
            ipv4_address         = "161.35.194.251"                                     
            ipv4_address_private = "10.135.158.48"                                      
            ipv6                 = false        
            locked               = false        
            memory               = 1024         
            monitoring           = false        
            name                 = "www-1"      
            price_hourly         = 0.00744      
            price_monthly        = 5            
            private_networking   = true         
            region               = "fra1"       
            resize_disk          = true         
            size                 = "s-1vcpu-1gb"                                        
            ssh_keys             = [            
                "30935145", 
            ]               
            status               = "active"     
            tags                 = []           
            urn                  = "do:droplet:257772106"                               
            vcpus                = 1            
            volume_ids           = []           
            vpc_uuid             = "f71384e0-dc84-11e8-8b13-3cfdfea9f160"               
        }                   
        
        # digitalocean_droplet.www-2:           
        resource "digitalocean_droplet" "www-2" {                                       
            backups              = false        
            created_at           = "2021-08-03T21:57:21Z"                               
            disk                 = 25           
            id                   = "257772107"  
            image                = "ubuntu-20-04-x64"                                   
            ipv4_address         = "161.35.194.255"                                     
            ipv4_address_private = "10.135.158.49"                                      
            ipv6                 = false        
            locked               = false        
            memory               = 1024         
            monitoring           = false        
            name                 = "www-2"      
            price_hourly         = 0.00744      
            price_monthly        = 5            
            private_networking   = true         
            region               = "fra1"       
            resize_disk          = true         
            size                 = "s-1vcpu-1gb"                                        
            ssh_keys             = [            
                "30935145", 
            ]               
            status               = "active"     
            tags                 = []           
            urn                  = "do:droplet:257772107"                               
            vcpus                = 1            
            volume_ids           = []           
            vpc_uuid             = "f71384e0-dc84-11e8-8b13-3cfdfea9f160"               
        }                   
        
        # digitalocean_loadbalancer.www-lb-gk-tftest:                                   
        resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {                       
            algorithm                = "round_robin"                                    
            droplet_ids              = [        
                257772106,  
                257772107,  
            ]               
            enable_backend_keepalive = false    
            enable_proxy_protocol    = false    
            id                       = "9f829c83-7426-4a4c-97dd-ae4d8086d38f"           
            ip                       = "165.227.245.46"                                 
            name                     = "www-lb-gk-tftest"                               
            redirect_http_to_https   = false    
            region                   = "fra1"   
            size                     = "lb-small"                                       
            status                   = "active" 
            urn                      = "do:loadbalancer:9f829c83-7426-4a4c-97dd-ae4d8086d38f"               
            vpc_uuid                 = "f71384e0-dc84-11e8-8b13-3cfdfea9f160"           
        
            forwarding_rule {                   
                entry_port      = 80            
                entry_protocol  = "http"        
                target_port     = 80            
                target_protocol = "http"        
                tls_passthrough = false         
            }               
        
            healthcheck {   
                check_interval_seconds   = 10   
                healthy_threshold        = 5    
                port                     = 80   
                protocol                 = "tcp"                                        
                response_timeout_seconds = 5    
                unhealthy_threshold      = 3    
            }               
        
            sticky_sessions {                   
                cookie_ttl_seconds = 0          
                type               = "none"     
            }               
        }                   
        
        
        Outputs:            
        
        ip1 = "161.35.194.251"                  
        ip2 = "161.35.194.255"
        $ tfvar () { tf state show -no-color 'digitalocean_droplet.'$1' ' | grep ''$2' '  | cut -d '=' -f 2 | xargs; }          
        $
        $ wget "http://$(tfvar www-1 ipv4_address)/" -O - | grep -i nginx               
        --2021-08-04 00:00:57--  http://161.35.194.251/                                 
        Connecting to 161.35.194.251:80... connected.                                   
        HTTP request sent, awaiting response... 200 OK                                  
        Length: 612 [text/html]                 
        Saving to: ‘STDOUT’ 
        
        -                   100%[===================>]     612  --.-KB/s    in 0s       
        
        2021-08-04 00:00:58 (177 MB/s) - written to stdout [612/612]                    
        
        <title>Welcome to [1m[31mnginx[0m[39m[49m!</title>        
        <h1>Welcome to [1m[31mnginx[0m[39m[49m!</h1>              
        <p>If you see this page, the [1m[31mnginx[0m[39m[49m web server is successfully installed and     
        <a href="http://[1m[31mnginx[0m[39m[49m.org/">[1m[31mnginx[0m[39m[49m.org</a>.<br/>                                 
        <a href="http://[1m[31mnginx[0m[39m[49m.com/">[1m[31mnginx[0m[39m[49m.com</a>.</p>                                  
        <p><em>Thank you for using [1m[31mnginx[0m[39m[49m.</em></p>                                      
        $
    
    



The tfvar function just greps values from `tf state show`. We could have used the output vars of the
apply as well. 

This is all for this chapter, so we destroy everything again:



=== "Cmd"
    
    ```console
    $ tf destroy -auto-approve -lock=false
    ```

=== "Output"

    
    <xterm />
    
        $ tf destroy -auto-approve -lock=false                
        [1mdigitalocean_droplet.www-2: Refreshing state... [id=257772107][0m[39m[49m                  
        [1mdigitalocean_droplet.www-1: Refreshing state... [id=257772106][0m[39m[49m                  
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Refreshing state... [id=9f829c83-7426-4a4c-97dd-ae4d8086d38f][0m[39m[49m               
        
        Terraform used the selected providers to generate the following execution plan. 
        Resource actions are indicated with the following symbols:                      
          [31m-[39m destroy         
        
        Terraform will perform the following actions:                                   
        
        [1m  # digitalocean_droplet.www-1[0m[39m[49m will be [1m[31mdestroyed[0m[39m[49m                                
          [31m-[39m resource "digitalocean_droplet" "www-1" {                                   
              [31m-[39m backups              = false [90m->[39m [90mnull[39m                                    
              [31m-[39m created_at           = "2021-08-03T21:57:21Z" [90m->[39m [90mnull[39m                   
              [31m-[39m disk                 = 25 [90m->[39m [90mnull[39m                                       
              [31m-[39m id                   = "257772106" [90m->[39m [90mnull[39m                              
              [31m-[39m image                = "ubuntu-20-04-x64" [90m->[39m [90mnull[39m                       
              [31m-[39m ipv4_address         = "161.35.194.251" [90m->[39m [90mnull[39m                         
              [31m-[39m ipv4_address_private = "10.135.158.48" [90m->[39m [90mnull[39m                          
              [31m-[39m ipv6                 = false [90m->[39m [90mnull[39m                                    
              [31m-[39m locked               = false [90m->[39m [90mnull[39m                                    
              [31m-[39m memory               = 1024 [90m->[39m [90mnull[39m                                     
              [31m-[39m monitoring           = false [90m->[39m [90mnull[39m                                    
              [31m-[39m name                 = "www-1" [90m->[39m [90mnull[39m                                  
              [31m-[39m price_hourly         = 0.00744 [90m->[39m [90mnull[39m                                  
              [31m-[39m price_monthly        = 5 [90m->[39m [90mnull
        [39m      [31m-[39m private_networking   = true [90m->[39m [90mnull[39m                                     
              [31m-[39m region               = "fra1" [90m->[39m [90mnull[39m                                   
              [31m-[39m resize_disk          = true [90m->[39m [90mnull[39m                                     
              [31m-[39m size                 = "s-1vcpu-1gb" [90m->[39m [90mnull[39m                            
              [31m-[39m ssh_keys             = [        
                  [31m-[39m "30935145",                 
                ] [90m->[39m [90mnull[39m   
              [31m-[39m status               = "active" [90m->[39m [90mnull[39m                                 
              [31m-[39m tags                 = [] [90m->[39m [90mnull[39m                                       
              [31m-[39m urn                  = "do:droplet:257772106" [90m->[39m [90mnull[39m                   
              [31m-[39m vcpus                = 1 [90m->[39m [90mnull
        [39m      [31m-[39m volume_ids           = [] [90m->[39m [90mnull[39m                                       
              [31m-[39m vpc_uuid             = "f71384e0-dc84-11e8-8b13-3cfdfea9f160" [90m->[39m [90mnull[39m   
            }               
        
        [1m  # digitalocean_droplet.www-2[0m[39m[49m will be [1m[31mdestroyed[0m[39m[49m                                
          [31m-[39m resource "digitalocean_droplet" "www-2" {                                   
              [31m-[39m backups              = false [90m->[39m [90mnull[39m                                    
              [31m-[39m created_at           = "2021-08-03T21:57:21Z" [90m->[39m [90mnull[39m                   
              [31m-[39m disk                 = 25 [90m->[39m [90mnull[39m                                       
              [31m-[39m id                   = "257772107" [90m->[39m [90mnull[39m                              
              [31m-[39m image                = "ubuntu-20-04-x64" [90m->[39m [90mnull[39m                       
              [31m-[39m ipv4_address         = "161.35.194.255" [90m->[39m [90mnull[39m                         
              [31m-[39m ipv4_address_private = "10.135.158.49" [90m->[39m [90mnull[39m                          
              [31m-[39m ipv6                 = false [90m->[39m [90mnull[39m                                    
              [31m-[39m locked               = false [90m->[39m [90mnull[39m                                    
              [31m-[39m memory               = 1024 [90m->[39m [90mnull[39m                                     
              [31m-[39m monitoring           = false [90m->[39m [90mnull[39m                                    
              [31m-[39m name                 = "www-2" [90m->[39m [90mnull[39m                                  
              [31m-[39m price_hourly         = 0.00744 [90m->[39m [90mnull[39m                                  
              [31m-[39m price_monthly        = 5 [90m->[39m [90mnull
        [39m      [31m-[39m private_networking   = true [90m->[39m [90mnull[39m                                     
              [31m-[39m region               = "fra1" [90m->[39m [90mnull[39m                                   
              [31m-[39m resize_disk          = true [90m->[39m [90mnull[39m                                     
              [31m-[39m size                 = "s-1vcpu-1gb" [90m->[39m [90mnull[39m                            
              [31m-[39m ssh_keys             = [        
                  [31m-[39m "30935145",                 
                ] [90m->[39m [90mnull[39m   
              [31m-[39m status               = "active" [90m->[39m [90mnull[39m                                 
              [31m-[39m tags                 = [] [90m->[39m [90mnull[39m                                       
              [31m-[39m urn                  = "do:droplet:257772107" [90m->[39m [90mnull[39m                   
              [31m-[39m vcpus                = 1 [90m->[39m [90mnull
        [39m      [31m-[39m volume_ids           = [] [90m->[39m [90mnull[39m                                       
              [31m-[39m vpc_uuid             = "f71384e0-dc84-11e8-8b13-3cfdfea9f160" [90m->[39m [90mnull[39m   
            }               
        
        [1m  # digitalocean_loadbalancer.www-lb-gk-tftest[0m[39m[49m will be [1m[31mdestroyed[0m[39m[49m                
          [31m-[39m resource "digitalocean_loadbalancer" "www-lb-gk-tftest" {                   
              [31m-[39m algorithm                = "round_robin" [90m->[39m [90mnull[39m                        
              [31m-[39m droplet_ids              = [    
                  [31m-[39m 257772106,                  
                  [31m-[39m 257772107,                  
                ] [90m->[39m [90mnull[39m   
              [31m-[39m enable_backend_keepalive = false [90m->[39m [90mnull[39m                                
              [31m-[39m enable_proxy_protocol    = false [90m->[39m [90mnull[39m                                
              [31m-[39m id                       = "9f829c83-7426-4a4c-97dd-ae4d8086d38f" [90m->[39m [90mnull[39m                   
              [31m-[39m ip                       = "165.227.245.46" [90m->[39m [90mnull[39m                     
              [31m-[39m name                     = "www-lb-gk-tftest" [90m->[39m [90mnull[39m                   
              [31m-[39m redirect_http_to_https   = false [90m->[39m [90mnull[39m                                
              [31m-[39m region                   = "fra1" [90m->[39m [90mnull[39m                               
              [31m-[39m size                     = "lb-small" [90m->[39m [90mnull[39m                           
              [31m-[39m status                   = "active" [90m->[39m [90mnull[39m                             
              [31m-[39m urn                      = "do:loadbalancer:9f829c83-7426-4a4c-97dd-ae4d8086d38f" [90m->[39m [90mnull[39m   
              [31m-[39m vpc_uuid                 = "f71384e0-dc84-11e8-8b13-3cfdfea9f160" [90m->[39m [90mnull[39m                   
        
              [31m-[39m forwarding_rule {               
                  [31m-[39m entry_port      = 80 [90m->[39m [90mnull
        [39m          [31m-[39m entry_protocol  = "http" [90m->[39m [90mnull[39m                                    
                  [31m-[39m target_port     = 80 [90m->[39m [90mnull
        [39m          [31m-[39m target_protocol = "http" [90m->[39m [90mnull[39m                                    
                  [31m-[39m tls_passthrough = false [90m->[39m [90mnull[39m                                     
                }           
        
              [31m-[39m healthcheck {                   
                  [31m-[39m check_interval_seconds   = 10 [90m->[39m [90mnull[39m                               
                  [31m-[39m healthy_threshold        = 5 [90m->[39m [90mnull[39m                                
                  [31m-[39m port                     = 80 [90m->[39m [90mnull[39m                               
                  [31m-[39m protocol                 = "tcp" [90m->[39m [90mnull[39m                            
                  [31m-[39m response_timeout_seconds = 5 [90m->[39m [90mnull[39m                                
                  [31m-[39m unhealthy_threshold      = 3 [90m->[39m [90mnull[39m                                
                }           
        
              [31m-[39m sticky_sessions {               
                  [31m-[39m cookie_ttl_seconds = 0 [90m->[39m [90mnull[39m                                      
                  [31m-[39m type               = "none" [90m->[39m [90mnull[39m                                 
                }           
            }               
        
        [1mPlan:[0m[39m[49m 0 to add, 0 to change, 3 to destroy.                                      
        
        [1mChanges to Outputs:[0m[39m[49m 
          [31m-[39m ip1 = "161.35.194.251" [90m->[39m [90mnull[39m      
          [31m-[39m ip2 = "161.35.194.255" [90m->[39m [90mnull[39m      
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Destroying... [id=9f829c83-7426-4a4c-97dd-ae4d8086d38f][0m[39m[49m 
        [1mdigitalocean_loadbalancer.www-lb-gk-tftest: Destruction complete after 1s[0m[39m[49m       
        [1mdigitalocean_droplet.www-2: Destroying... [id=257772107][0m[39m[49m                        
        [1mdigitalocean_droplet.www-1: Destroying... [id=257772106][0m[39m[49m                        
        [1mdigitalocean_droplet.www-1: Still destroying... [id=257772106, 10s elapsed][0m[39m[49m     
        [1mdigitalocean_droplet.www-2: Still destroying... [id=257772107, 10s elapsed][0m[39m[49m     
        [1mdigitalocean_droplet.www-1: Still destroying... [id=257772106, 20s elapsed][0m[39m[49m     
        [1mdigitalocean_droplet.www-2: Still destroying... [id=257772107, 20s elapsed][0m[39m[49m     
        [1mdigitalocean_droplet.www-2: Destruction complete after 22s[0m[39m[49m                      
        [1mdigitalocean_droplet.www-1: Destruction complete after 22s[0m[39m[49m                      
        
        [1m[32mDestroy complete! Resources: 3 destroyed.[0m[39m[49m
    
    



## Discussion

The `remote-exec` provisioning method, requiring to configure the private SSH key into TF is
definitely ansible territory. See the [ansible](./ansible.md) chapter about TF and Ansible
interplaying.



[pass]: https://www.passwordstore.org/