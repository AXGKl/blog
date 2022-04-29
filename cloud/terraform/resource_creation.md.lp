# Creating Resources with Terraform (TF)

Basic Mechanics


## Requirements

- SSH key pair, authorized in DO 
- Valid API key, e.g. available via [pass][pass]
- `terraform` executable locally on your system

```bash lp fmt=xt_flat asserts=id_rsa
ls ~/.ssh/id_rsa* | grep terra
pass show DO/pat | head -c 8
terraform -h | head
```

## Initializing

Then configure basic vars:

```bash lp fmt=xt_flat new_session=DO
export D="$DT_PROJECT_ROOT/tmp/clusters/DO/basic"
export TF_VAR_do_token="$(pass show DO/pat)"
alias tf=terraform
mkdir -p "$D"
cd "$D"
```

Just go sure we are clean on DO and locally, at start of this tutorial:

```bash lp session=DO
[
{'cmd': 'tf destroy -auto-approve -lock=false', 'expect': 'complete', 'timeout': 40},
{'cmd': 'rm -rf *'}
]
```


Create a file for DO provider:

```json lp mode=make_file fn=provider.tf cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/basic
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

```bash lp session=DO timeout=20
tf init
tree -lta
```

## Configuration

### Worker Nodes

Create two more files for worker nodes:

```json lp mode=make_file fn=www-1.tf cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/basic
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

```bash lp  session=DO
sed 's/www-1/www-2/g' www-1.tf > www-2.tf
```

### Load Balancer

Also we configure a loadbalancer. Here you see cloud provider specific features of TF:

```bash lp session=DO
cat << EOF > loadbalancer.tf
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
```

### Outputs Demo

This way we can information to the `tf apply` output, ready for others to consume:

```bash lp session=DO
cat <<'ENDL' > outputs.tf
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

## Plan & Apply

`tf plan` shows current state:

```bash lp session=DO timeout=10
tf plan
```

Ready to apply, that command will now create the nodes (takes a minute):

```bash lp session=DO timeout=600
time tf apply -auto-approve
```

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

```bash lp session=DO timeout=200 fmt=xt_flat
time tf apply -auto-approve -parallelism=5
```

Result so far: Nginx servers up:

```bash lp session=DO asserts=nginx timeout=10
[{'cmd': 'tf show'},
 {'cmd': "tfvar () { tf state show -no-color 'digitalocean_droplet.'$1' ' | grep ''$2' '  | cut -d '=' -f 2 | xargs; }", 'expect':""},
 {'cmd': 'wget "http://$(tfvar www-1 ipv4_address)/" -O - | grep -i nginx', 'expect':"Welcome"}]
```

The tfvar function just greps values from `tf state show`. We could have used the output vars of the
apply as well. 

This is all for this chapter, so we destroy everything again:

```bash lp session="DO", asserts="3 destroyed", timeout=40, lock_page=1
tf destroy -auto-approve -lock=false
```

## Discussion

The `remote-exec` provisioning method, requiring to configure the private SSH key into TF is
definitely ansible territory. See the [ansible](./ansible.md) chapter about TF and Ansible
interplaying.



[pass]: https://www.passwordstore.org/
