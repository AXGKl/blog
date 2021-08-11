# DNSMasq for Testing Cloud Setups


!!! quote "[OpenShift Provisining](https://cloud.redhat.com/blog/how-to-install-openshift-4.6-on-vmware-with-upi)"

    That said, DNS is extremely important to the success of the OpenShift 4 installer. Pay close
    attention to the records you create and verify each one before installation, especially the
    first time.

!!! quote "[Prerequisites Terraform on DO](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean)"

    - A personal domain pointed to DigitalOcean’s nameservers. See How To Point to DigitalOcean
      Nameservers From Common Domain Registrars or How to Add Domains using DigitalOcean’s Control
      Panel.
    - Note: Use your own, unique domain name or Terraform will be unable to deploy the DNS
      resources. Be sure your domain is pointed to DigitalOcean nameservers.

DNS is in many cases a practical and simple solution for *cluster internal* service routing.

But Cloud Infrastructure Providers and even container orchestrators, in many cases, want to also own
resolution of *external* DNS queries, for the resources run on their Infrastructure.

Registered propagated domains are a time and resource bottleneck, when you think about many
developers working on the same codebases, which is to be deployed and tested by them, CI/CD and so on.

On AWS you have Route53 for quick test DNS services but a more generic approach is to use dnsmasq on
the test machines.

In dnsmasq, you can do:

    address=/myfakedomain.com/10.16.1.20

to redirect queries for myfakedomain.com to the IP address specified. You can even do things like:

    address=/plex/10.16.1.55


## [Basic][YT] Setup

```bash
~ ❯ cat /etc/dnsmasq.d/tftest.net
no-dhcp-interface=enp56s0u1u2i5
bogus-priv
domain=tftest.net
expand-hosts
# not works for me:
#addn-hosts=/home/gk/tfhosts
local=/tftest.net/
domain-needed
no-resolv
no-poll
server=8.8.8.8
server=8.8.4.4
```

and 

```bash

~ ❯ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.30   hp
10.0.0.84   gk
10.0.0.1    fritz

```


Then `systemctl restart dnsmasq`

You get resolution then:

```bash
~ ❯ nslookup gk 127.0.0.1
Server:     127.0.0.1
Address:    127.0.0.1#53

Name:   gk
Address: 10.0.0.84

~ ❯ nslookup gk.tftest.net 127.0.0.1
Server:     127.0.0.1
Address:    127.0.0.1#53

Name:   gk.tftest.net
Address: 10.0.0.84

```

and with 

```bash
~ ❯ sudo systemd-resolve --set-dns 127.0.0.1 --interface=enp56s0u1u2i5
[sudo] password for gk:
```
this also works:

```
~ ❯ ping gk.tftest.net
PING gk.tftest.net (10.0.0.84) 56(84) bytes of data.
```

## Forwarding

Now configure

    address=/tftest.net/<ip of cloud provider's dns>

and they'll get the resolution requests.


## Resources:
- [Youtube][YT] good explanation for all config vars
- DO: https://serverpilot.io/docs/how-to-configure-dns-on-digitalocean/
- DO: https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars
- https://serverfault.com/questions/1031180/dns-server-for-fake-domain-for-internal-testing-usage-only-on-linux

[YT]: https://www.youtube.com/watch?v=P2kiinwg00c
