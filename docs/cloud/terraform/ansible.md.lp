# Terraform and Ansible

## Preparation

Ansible and TF client installed, then:

```bash lp new_session=ans
export D="$DT_PROJECT_ROOT/tmp/clusters/DO/ansible"
export TF_VAR_do_token="$(pass show DO/pat)"
alias tf=terraform
mkdir -p "$D"
cd "$D"
```

## Config

### Provider:

```json lp mode=make_file fn=provider.tf cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/ansible
terraform { 
 required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

data "digitalocean_ssh_key" "terraform" { name = "terraform" }
provider "digitalocean" { token = var.do_token }
variable "do_token" { }
variable "pvt_key" { default = "~/.ssh/id_rsa_terraform" }
```

### Worker:

```json lp mode=make_file fn=worker.tf cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/ansible
resource "digitalocean_droplet" "worker" {
  image = "ubuntu-20-04-x64"
  name = "worker"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [ data.digitalocean_ssh_key.terraform.id ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello World'"]
  }
    provisioner "local-exec" {
      command = "ansible-playbook -i '${digitalocean_droplet.worker.ipv4_address},' playbook.yml"
    }
}
```

### Ansible:

```yaml lp mode=make_file fn=playbook.yml cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/ansible
---
- hosts: all
  become: yes
  become_user: root
  become_method: sudo
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: latest
    - name: Restart Nginx
      service: name=nginx state=restarted
      become: yes
```
and 

```ini lp mode=make_file fn=ansible.cfg cwd=$DT_PROJECT_ROOT/tmp/clusters/DO/ansible
[defaults]
host_key_checking = False
remote_user = root
```

## Deploy

```bash lp timeout=300 session=ans
tf init
tf apply -auto-approve
```

And we have the playbook deployed:

```bash lp asserts=Welcome session=ans lock_page
ip=$(tf show | grep ipv4 | head -n 1 | cut -d = -f 2 | xargs)
wget "http://$ip/" -O -  | grep -i welcome
```

## Discussion

- The remote exec is ugly. We have to give TF our private key, otherwise not required.
- We had to do it to make sure the worker is up when ansible takes over.
- A yet more "ugly" alternative would be a sleep.

- Cleaner for sure would be to use dedicated ansible plugins for TF:

    - [jonmorehouse/terraform-provisioner-ansible](https://github.com/jonmorehouse/terraform-provisioner-ansible)
      A Terraform Provisioner that runs Ansible-Local on a target machine at creation-time.

    - [nbering/terraform-provider-ansible/)](https://github.com/nbering/terraform-provider-ansible/)
      A Terraform provider serving as an interop layer for an Ansible dynamic inventory script.

    - [adammck/terraform-inventory](https://github.com/adammck/terraform-inventory) A very similar
      solution to terraform-provider-ansible, without the Logical provider. Depends on specific
      Terraform resource types, and relies heavily on cloud-providers' tag implementations.

    - [Ansible Module: Terraform](http://docs.ansible.com/ansible/devel/modules/terraform_module.html) An Ansible
      module that runs Terraform plans and deployments. I.e. the "inside out" solution.


Lets' focus on the dynamic inventory based approach:

This script https://github.com/nbering/terraform-inventory/blob/master/terraform.py simply walks the TF
state file after a successfull apply, pulling out ansible specific information configured directly
within the TF resource configs, e.g.:

```json
resource "ansible_host" "example" {
    inventory_hostname = "example.com"
    groups = ["web"]
    vars = {
        ansible_user = "admin"
    }
}

resource "ansible_group" "web" {
  inventory_group_name = "web"
  children = ["foo", "bar", "baz"]
  vars = {
    foo = "bar"
    bar = 2
  }
}
```

So in essence you do sth like this at (re-)provisioning time:

```console
$ tf apply && ansible-playbook -i /etc/ansible/terraform.py playbook.yml
```

