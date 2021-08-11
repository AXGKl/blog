# Awesome Apps - Not only Linux

Those I install pretty early after a distro hop or hardware replacement

I omit the usual stuff like git, htop, tmux, ripgrep, fzf ...


- [edge](https://blogs.windows.com/msedgedev/2020/10/20/microsoft-edge-dev-linux/) Pretty well
  thought through browser, actually
- [gimp](https://www.gimp.org/)
- [lazygit](https://github.com/jesseduffield/lazygit) Perfect terminal git tool. Also for vim: No
  more fugitive, just open in vim-floatterm
- [miniconda](https://docs.conda.io/en/latest/miniconda.html) Tons of disposable distro independent
  apps, not only from the python world. Default python, ruby, npm and java env wrapper, for their
  subsequent tools landscape
- [simplescreenrecorder](https://www.maartenbaert.be/simplescreenrecorder/) with 

            ffmpeg -ss 0.0 -i "$fn" -filter_complex "[0:v] fps=12,scale=760:-1,split [a][b];[a] palettegen \
                        [p];[b][p] paletteuse" $fn.gif` also for animated gifs from the recordings.

- [vimium ](https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en)
  Drives browsing via vim keys.

  ```
    unmap h
    unmap l
    map h goBack
    map l goForward
  ```
  Alternative vim-vixen
- [z.lua](https://github.com/skywind3000/z.lua) Perfect directory jumper
- zsh: Yes. It is better, especialy completion




## Apropos...

### ADB: Android File Transfer to/from Linux via USB

pacman -S android-tools

Then on the phone find About -> Build Number -> Tab 3 times on it -> you are "developer" - hooray!


On the laptop this should work then:

```
~ ❯ adb devices
List of devices attached
CQ3001R1EL  device
```


Then git clone & make this: https://github.com/spion/adbfs-rootless


And mount: ./adbfs ~/droid

Ignore the permission errors, you have a mounted phone SD card in $HOME/droid. copy / sync your stuff and it's far
faster than e.g. KDE connect via the network.



Then just 

~/dr/st/self/primary/DCIM/100ANDRO ❯ rm -rf *
zsh: sure you want to delete more than 100 files in /home/gk/droid/storage/self/primary/DCIM/100ANDRO [yn]? y


and you have a clean phone again.

### ZSH: Best *Interactive* Shell

#### Global aliases

```bash
alias -g pg='| grep -i '
alias -g pclip='| xclip -i -selection clipboard'
```

Then

```console
$ cat foo pclip # and you have it in the clipboard
$ ps ax pg node
   1215 ?        Ss     0:00 fusermount -o rw,nosuid,nodev,fsname=portal,auto_unmount,subtype=portal --
/run/user/1000/doc
 300617 ?        Ssl    0:03 /usr/bin/node --no-warnings /home/gk/.vim/plugged/coc.nvim/build/index.js
 3010
```