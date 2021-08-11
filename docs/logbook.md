# Logbook

- [2021-08-11 12:59] 
Crazy nvim bug/config problem(?): **You edit a file, write, content gone**.

Especially when write+quitting this can kill your day.

Reason: If you managed to create a file with name '-' (a single dash) - then the formatter (run on
write by nvim) sees this obviously as input and changes the buffer accordingly.

Solution: Delete the file, all works again: `rm -- -` 


- [2021-08-11 12:38] 
Politics aside but **Microsoft Edge**/Linux seems currently the technical best browser for me.
And FF is anyway totally [political](https://blog.mozilla.org/en/mozilla/we-need-more-than-deplatforming/) meanwhile as well

- [2021-05-01 11:37] 
Fedora 34 fresh.
Sound: Remove pipewire like described by fedora - then removed old .config/pulse(!). `systemctl --user restart pulseaudio` -> alsamixer worked, could connect, the rest as well

- [2021-02-11 12:36] 
nvim: Do not install the package mgr version - the app image (from their github) works perfect:

    /home/gk/inst/nvim.appimage README.md



