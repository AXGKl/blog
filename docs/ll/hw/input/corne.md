# My Corne Keyboard


## Environment

Install the environment and create the firmware like in the newbs guide: https://docs.qmk.fm/#/newbs_getting_started

I forked and cloned like explained here: https://docs.qmk.fm/#/getting_started_github

```bash
10025  cd qmk_firmware
10032  qmk json2c btk-corne
10033  qmk json2c btk-corne.json
10035  qmk json2c btk-corne.json > keymap.c
10038  qmk compile btk-corne.c
10040  qmk compile btk-corne.json
```
```bash
10045  qmk setup AXGKl/qmk_firmware
10046  cd qmk_firmware
10047  qmk compile -kb crkbd/rev1/legacy -km default
10048  qmk config user.keyboard=crkbd/rev1/legacy
10049  qmk config user.keymap=AXGKl
10052  vi /home/gk/.config/qmk/qmk.ini
10053  qmk config user.keyboard=crkbd/rev1/legacy
10056  qmk new-keymap
10057  qmk config user.keymap=AXGKl
10058  qmk new-keymap
10059  vi /home/gk/inst/qmk_firmware/keyboards/crkbd/keymaps/AXGKl/keymap.c
10060  qmk compile
```



## Flashing

You have to do this as root. So we transfer the qmk install for root:

systemctl stop ModemManager # (not sure if needed, I stopped it)

```bash
~/bin ❯ cat /usr/local/bin/qmkflash                                                                                          tools
#!/usr/bin/env bash

test $(whoami) != 'root' && { echo "run me with sudo"; exit 1; }
source /ho

source /home/gk/miniconda3/etc/profile.d/conda.sh
conda activate /home/gk/miniconda3/envs/tools/
export PYTHONPATH=/home/gk/.local/lib/python3.8/site-packages
/home/gk/.local/bin/qmk flash
```

Then `qmk flash` works (had to do 2 times, sides were reversed once. Worked after usb cable left,
then right then left again, always flashing.

Reset button (over the sides connector cable) press/release then flashing worked. 

