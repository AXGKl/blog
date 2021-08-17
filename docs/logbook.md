# Logbook


### [`kmcaster`](https://github.com/DaveJarvis/kmcaster/): Best screenkey recorder
[2021-08-17 11:11] 


### openjdk install
[2021-08-17 11:09] 

```console
sudo yum -y install curl
curl -O https://download.java.net/java/GA/jdk14/076bab302c7b4508975440c56f6cc26a/36/GPL/openjdk-14_linux-x64_bin.tar.gz
tar xvf openjdk-14_linux-x64_bin.tar.gz
sudo mv jdk-14 /opt/
```

Unlike [here](https://computingforgeeks.com/install-oracle-java-openjdk-14-on-centosfedora-linux/)
we don't export set any profiles in /etc/profile.d for this but use it per app like:

`alias screenkeyjs='/opt/jdk-14/bin/java -jar /home/gk/inst/kmcaster.jar -d 60'`


### gpg-agent cache timeout
[2021-08-17 10:34] 

After a fedora security update I got an annoyingly short gpg timeout for the pass utility. Fix:

```bash
❯ cat /home/gk/.gnupg/gpg-agent.conf
default-cache-ttl 7200
```

and `systemctl --user restart gpg-agent`


### Grub: See the system booting
[2021-08-16 10:34] 

On Fedora34 fiddling with removing `quiet` and `rhgb`, then grub2-mkconfig did not work, guess I was
"holding it wrong".
[This](https://docs.fedoraproject.org/en-US/fedora/rawhide/system-administrators-guide/kernel-module-driver-configuration/Working_with_the_GRUB_2_Boot_Loader/) helped, use RedHat's grubby.

```bash
grubby --default-kernel
grubby --remove-args="rhgb quiet" --update-kernel /boot/vmlinuz-5.13.8-200.fc34.x86_64
```

No mkconfig necessary.


!!! warning
    Do **not** add console=tty... as suggested in the example in the tutorial - I had no output
    anymore
    

### Nvim: Filedir in galaxyline
[2021-08-11 18:00] 

Seeing only index.md in the statusline on multiple markdown files is not really cool. galaxyline allows functions:

Fixed, with embarrassingly low lua skills, we see the first parent directory level now, enough in
most cases for unique file identification:

=== "Result"
    The directory is shown:

    ![](img/galaxyline.png)

=== "Code"
    ```lua
    gls.left[5] = {
        FileDir = {
            provider = function()
                local fn = vim.fn.expand("%:p")
                local fn, a = string.match(fn, "(.*)%/(.*)")
                local a, fn = string.match(fn, "(.*)%/(.*)")
                return fn .. "/"
            end,
            condition = condition.buffer_not_empty,
            highlight = {colors.fg, colors.bg}
        }
    }

    gls.left[6] = {
        FileName = {
            provider = function()
                local fn = vim.fn.expand("%:p")
                local a, b = string.match(fn, "(.*)%/(.*)")
                return b .. " "
            end,
            condition = condition.buffer_not_empty,
            highlight = {colors.magenta, colors.bg, "bold"}
        }
    }

    ```



### Nvim: Lost content on file save
[2021-08-11 12:59] 

Crazy nvim bug/config problem(?): **You edit a file, write, content gone**.
Especially when write+quitting this can kill your day.

Reason: If you managed to create a file with name '-' (a single dash) - then the formatter (run on
write by nvim) sees this obviously as input and changes the buffer accordingly.

Solution: Delete the file, all works again: `rm -- -` 


### Edge Browser
[2021-08-11 12:38] 

Politics aside but **Microsoft Edge**/Linux seems currently the technical best browser for me.
FF is anyway totally [political](https://blog.mozilla.org/en/mozilla/we-need-more-than-deplatforming/) meanwhile as well

### pipewire -> pulse
[2021-05-01 11:37] 

Fedora 34 fresh.
Sound: Remove pipewire like described by fedora - then removed old .config/pulse(!). `systemctl --user restart pulseaudio` -> alsamixer worked, could connect, the rest as well

### Nvim: Appimage 
[2021-02-11 12:36] 

nvim: Do not install the package mgr version on a stable distro, nvims' dev speed is crazy (e.g.
lua support) - the app image (from their github) works perfect.

    /home/gk/inst/nvim.appimage README.md



