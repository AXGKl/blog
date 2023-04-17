# Scanning 1000s of Dias with Linux and Android Phone

(The cheap way)

## Prepare Projector

- Open it
- Remove the forward one of the two inner lenses. Leave the heat shielding glas between the two
  lenses !!
- Put a litte Plastic inside, to cover the direct light. I cut it out from a yogurt container (see
  picture). Keep the plastic at distance from the glas, it would melt!
- Remove the objective and place the mobile phone there, cam pointing to inside, where the Dia is.

## Remote control cam

- Put phone to developer mode and activate USB debugging, so that ADB works
- Install like here: https://www.xda-developers.com/install-adb-windows-macos-linux/
- Install scrcpy from snapstore and start like

      scrcpy --hid-mouse

  (to get mouse support - release with alt or super)

- Now you can control the cam from the computer, e.g. take pics

## Transferring

We use jmtpfs to mount the phone via fuse.

Then we run this to rename and flip the images into a local folder, then delete on the phone:

```python
#!/usr/bin/env python

import sys
import os
import shutil
import time

now = time.time

d_src = '/home/gk/mtp/Interner gemeinsamer Speicher/DCIM/Camera'
d_dest = '/home/gk/waldcloud/lois' # plus sys.argv[1] is dest folder


def die(msg='error'):
    print(f'{msg}\nsorry, bye.')
    sys.exit(1)


def main():
    t0 = now()
    n = sys.argv[1]
    d = f'{d_dest}/{n}'
    die(f'exists: {d}') if os.path.exists(d) else os.makedirs(d)
    print(f'copying {d_src} -> {d}')
    files = sorted(os.listdir(d_src))
    i = 0
    for fn in files:
        i += 1
        j = str(i).zfill(3)
        print(f'{d_src}/{fn} -> {d}/{n}_{j}.jpg')
        os.system(f'convert "{d_src}/{fn}" -flip "{d}/{n}_{j}.jpg"')
    print('removing all sources')
    for fn in files:
        os.unlink(f'{d_src}/{fn}')
    print(f'Done [{now() - t0}s].')


if __name__ == '__main__':
    main()
```
