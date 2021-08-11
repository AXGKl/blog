# My Linux Distribution

My Distro is Fedora (again).

It was the natural choice when I switched to Linux because our customers use RH and Fedora is today
what RH is tomorrow. At least it was like that in 2018, when I switched. Especially in container
tech you can be sure you have the newest tech nicely packaged. E.g. podman/user mode or
systemd-nspawn.

I do have my gripes with Gnome and Gnome is their default DE - but it is simple to skip it and
install e.g. the XFCE spin and then reconfigure to start [dwm](sl/dwm.md) in your xsession.

## Arch

After a year or so I switched to Arch though - since most of my [YT channels](../inet/videos.md)
heavily promote it. I chose [Arco Linux](https://www.youtube.com/c/ErikDubois/videos) and it was
pretty amazing that there really really was no tool whatsoever, which you could not directly install
via pacman or yay and I never had a failure installing it.

BUT: The constant updates of that rolling distro went on my nerves. *You constantly have the feeling
of being outdated and should update*.

But with a lot of software installed, incl. a few browsers, you every single day had a few hundred
megs of downloads, to be up to date for a few hours. Plus the installation time, which went into
well over a minute with [grub-btrfs](https://github.com/Antynea/grub-btrfs)...

So, when the first update broke, with an obscure kernel boot error (I could fix it but still...) I
went back to Fedora (34) and I found my peace of mind again, now knowing the fast paced side...

My takeaways:

- Linux channels use Arch - because they are Linux channels and need to talk about new software all
  the time
- When I need top notch software or software not in the Fedora repos, there are good technologies to
  install distro independent versions in sandboxes. Containers, miniconda, chroot, self compiles and the
  flatpak/snap/appimage trio (which I actually never need). If you can handle that, I don't see much need
  for a rolling distro. 


To me Fedora, allthough some say it is going to be replaced by RH streams, is the ideal distro.

- Up to date enough
- Newest container tech
- All the "big" tools have RPM versions
- For most "situations" you find a Fedora specific solution out there.
- And the small stuff when not in their repos, I take care of myself.

Only downside, maybe: IBM / Red Hat - we do not know what their plans are with this distro. And
sometimes, the bigger the company, the stranger the decisions they make... 








