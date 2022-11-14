# Nextcloud

Hetzner delivers a nice version 24 setup, which simply works.

I wanted to have the newest version and used the docker filesystem for 25 via snpawn - but it did
crash at heavy load.

The adaption scripts are within this folder, for potential later re-use after analysis why it
crashed.

They feature

- cron replacmentn within nc
- redis within nc
- a maint script usr/local/bin/m
- a backdoor into the running container, via socat

---

For now I continue with version 24. Good enough.
