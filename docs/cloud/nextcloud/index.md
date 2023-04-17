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

```
(base) root@nextcloud-ubuntu-4gb-hel1-2:~# cat build_arch.sh
#!/usr/bin/env bash



tar cfv nccustom.tar \
    /etc/systemd/system/nextcloud.service \
    docker/nc25/etc/apache2/ports.conf \
    docker/nc25/etc/apache2/sites-available/000-default.conf \
    docker/nc25/etc/hosts \
    docker/nc25/etc/resolv.conf  \
    docker/nc25/var/www/run_cron.sh \
    docker/nc25/var/www/html/config/config.php \
    docker/nc25/var/www/html/.htaccess \
    docker/nc25/start \
    docker/nc25/etc/redis/redis.conf \
    docker/nc25/etc/ImageMagick-6/policy.xml


echo -e 'To apply to fresh vm:
- podman export to docker/nc25
- chroot into
    - apt-get update
    - apt-get install redis-server socat ghostscript vim-tiny cron
- tar xfv nccustom.tar
- rm -rf docker/nc25/var/www/html
- nspawn it
    - /start # /var/www is built, with config
    - cp /var/www/html/config/config.php /oldconfig.php
- tar xfv nccustom.tar # again (for final config.php)
- chown -R 33:33 docker/nc25/var/www
- nspawn into it
    - echo "*/5 * * * * /var/www/run_cron.sh"  | crontab -u www-data -
    - /start
    - set cron to unix

then it should work...
```

---

For now I continue with version 24. Good enough.
