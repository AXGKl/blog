# My Move to Arco Linux


## Edit: And why I moved back to Fedora

[2022-01-24 02:29]

Ok. A rolling distro is nothing for me. 3 times a week a few gig download, that's just too much.
Also need some reliability and Fedora has both: Well maintained packages AND recent ones.

I kept a few configs from Arch, especially around gtk / qt consistency.

I leave this for future ref. only:

---

## Arch

[2021-09-20 20:19] 

So I did it. With Covid I got ppp: *pretty p*ssed & political*

As with OSX I could not stand IBM anymore. I spare you the details but the RMS cancellation was a
bit too much.

Plus problems and inconsistencies accumulated, which that move seems to have all fixed.

Examples:

- Style inconsistencies between gtk.x, qt, xfce, dunst (...) apps
- pulseaudio way too much cpu  (6% av)
- teamviewer not working
- mailspring super high cpu
- mailspring required gdm with all the gnome crap
- all a bit outdated


Over the years I followed and liked arco linux, arch based. Their Eric D. is doing an amazing job keeping all up to date
and consistent - with style. Check DT's vids.


Which one:

First tried arcoD - but some KDE stuff I chose in calamares was not working well with xfce - but got activated.

So I rather took Arcolinux default and from XFCE installed my DWM in addition.


## Achievements

- well tuned tools landscape all nicely styled and integrated but still totally transparent (.config, skel)
- way faster (than dnf) pacman / pamac, also cool for container img builds
- yay (user mode packages)



## Burning

Fastest way still:

```
dd if=<iso> of=/dev/sdx bs=1M status=progress
```

Then with the iso up, clean the HD with gparted - completely. Then calamares will do it's job nicely.


- Chose LTS Kernel

## Sound

NOT! working - new intel hardware, guys changed driver. blah.

From `https://bugzilla.redhat.com/show_bug.cgi?id=1772498`

Tough - had to use a fedora 34 usb iso, then query installed packages | grep alsa, and install same packages from arch - e.g. some sof (sound open firmware) via pamac

Then it worked.

## Display Manager

Switched from sddm to lightdm, since sddm to fully shine needs tons of plasma libs. It's for KDE, not for me.

How to switch: `tolightdm` (from `alias |grep light` - thanks eric)

`~ ❯❯❯ /usr/bin/lightdm-gtk-greeter-settings-pkexec`  made config simple - thanks, arch


## dwm

Used my old one from fedora.

arco's autostart.sh I liked and patched in, but had to put into `$HOME/.dwm/autostart.sh`



## Launcher

pacman -S ulauncher bound to ctrl-space in dwm

then 

```bash
cp /home/gk/fedora/home/gk/.local/share/ulauncher/extensions/com.github.dflock.ulauncher-w
indow-switcher/main.py /home/gk/.local/share/ulauncher/extensions/com.github.dflock.ulauncher-window-swi
tcher/main.py
```

from https://github.com/dflock/ulauncher-window-switcher/issues/2



## NotifyD

Instead of dunst I try XFCEs' one, nicely styled.

`xfce4-notifyd-config` to configure.

BUT: 
- does not support -u (urgency) but icons. So:
- does not support -r (replacing) -> volume change creates 100 notifications.

So: https://forum.xfce.org/viewtopic.php?id=14009

And $HOME/bin/notify-send as a python program which keeps a mapping of -r to last id returned from dbus.



## Browsing

### Firefox
    - VimVixen (with h<->H and l<->L, not scrolling vertical all the time but history all the time)
    - Context menu stay open after double clikc: `about:config` -> after_mouseup -> true  to avoid context menu closes at touchpad click




## Vim

- Installed neovim with pacman copied .config/nvim.
- Copied old .vim .vimrc works in prob

It autocreated new .config/coc

Fixed problems with :CheckHealth

fzf[.vim] did not work, had to `rm -rf .vim/plugged/fzf*`, then PlugInstall (reinstall them)


## Miniconda installation plus env/tools

- There pip install neovim
- pip install -e axblack

-> vim worked, :CheckHealth good now, axblack worked



## timeshift

Runs as root -> can't open browse or view logs due to missing desktop entries.
Creating the file /root/.local/share/applications/defaults.list was a working solution for me.


You may need to adjust the file contents to suit your desktop environment, just run $ xdg-mime query default inode/directory as your normal user account to get the value your desktop environment uses. In my case it was nemo.desktop.

So the defaults.list file contains the following two lines for me:

```
inode/directory=thunar.desktop
x-directory/normal=thunar.desktop
```


### grub-btrfs

Enabled grub-btrfs.path and modiefied monitored folder to timeshift as their github repo suggested. Not yet seen in
grub, guess grub-mkconfig missing


## Luks

Made an error - /boot is on main partition, i.e. encrypted. grub has only software decryption, weakly implemented. Takes
42 secs to decrypt kernel, thenk grub prompt shows. 

Only benefit: Attacker cannot install hacked kernel on my system. 

-> Created at slot 0 (must be first one!) a new one with lousy itertime:


```bash
cryptsetup luksDump /dev/nvme0n1p2
cryptsetup -v luksKillSlot /dev/nvme0n1p2 0
cryptsetup -v luksAddKey /dev/nvme0n1p2 -S 0 --iter-time 10

Key Slot 0: ENABLED
    Iterations:             11742  # was 2353704 before!
```

Means: HD will be decryptable easily, see https://diverto.github.io/2019/11/18/Cracking-LUKS-passphrases

Good: There is another key still in, with high iter times -> Will they try one wrong password grub will try that as well
- and hangs 40 seconds until throwing into rescue prompt. -> They might then *think* I have a decent iter time - and give up.

But if they really try the above with dictionary they'll succeed instantly - I guess, since my passphrase is short. If
long plus ONE typo it will suck totally waiting 40 secs then end in rescue prompt.

Solution: Create a HW stick with big passphrase - and have a loooong passphrase when I don't have the stick around.

Better solution: Create unencrypted boot partition. 

Maybe only encrypt $HOME - but think about leaking private stuff outside of it (caches, var directories, temp) 


## teamviewer

Nicely set up, in fedora had some install hassles.

Only had to do: 

systemctl disable --now teamviewerd.service

To make it not loading after reboots (even when start with login was disabled it was running)


## Conky

Too much CPU, all 8%:
Best: 
conky -c $HOME/.config/conky/AUR-Lazuli.conkyrc
conky -c $HOME/.config/conky/AUR-Allinone.conkyrc
conky -c $HOME/.config/conky/Arco-Redux-LUA.conkyrc


## Thunderbird

copied back $HOME/.thunderbird, then via help-> troubleshooting found profile folder.
Close TB, then rm -rf all in that folder, then move all from old profile folder to this one. works.


## Clipboard

copyq

But after install I had kwayland and kwin deps in -> removed that via pamac. Easy!


## podman
### user mode

cgroupv2 already present


    # usermod --add-subuids 100000-165536 --add-subgids 100000-165536 gk
    $ podman system migrate
    $ podman pull docker.io/archlinux

    ~/.config ❯❯❯ whoami; p run -ti -v /home/gk:/home/gk dbe48d42e6fa whoami
    gk
    root

and all file ids nicely mapped inside(root) vs outside (user)

And storage driver btrfs.
    
## Mime:    


/usr/share/applications
.local/share/applications

xdg-mime default thunar.desktop inode/directory

to use xpdf as the default PDF viewer:

$ xdg-mime default xpdf.desktop application/pdf

This should create an entry

[Default Applications]
application/pdf=xpdf.desktop

in your local MIME database ~/.config/mimeapps.list.


