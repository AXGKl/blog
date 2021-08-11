# DWM

## Patches

These are my current patches:

```bash lp fmt=mk_console
tree ~/.config/dwm/patches
```

### xfce4-panel

The statusbar is from myself, [got accepted](https://dwm.suckless.org/patches/xfce4-panel/) by the
suckless guys as official patch (hooray). 

![](https://dwm.suckless.org/patches/xfce4-panel/dwm_xfce4-panel.png)

I made it because

- I wanted a systray but the official [systray patch](https://dwm.suckless.org/patches/systray/) is
  massive and collided with other patches, e.g. statuscolors if I remember correctly
- Also statuscolors made dwm eat CPU, strangely, became often visible in htop - which is not
  suckless.

#### Design

It works by simple starting the panel as a normal window - but detecting it by window class name and moving it to the top
right position, plus preventing it showing up in the tag indicators and at cyclewindow actions.
See the diff [here](https://dwm.suckless.org/patches/xfce4-panel/).

[Here](status_bar_fun/2021.05.23_dwm_status_1_a_fancy_status_bar.md) is a description of the ride towards it...

## Hacking DWM: Xephyr

[xnest/Xephyr](https://www.linuxtoday.com/blog/xnest-tutorial/) is totally amazing and one of the many reasons I prefer X11.

!!! important
    Using Xephyr you can test all dwm patches w/o having to restart the actual one. This is far more
    convenient than switching back and forth between different Xsessions.


This

```bash lp mode=show_file fn=/home/gk/bin/xnest
```

allows to start the full Xserver with window manager in a window - and with ctrl-shift it gets ALL
keyboard events, incl. shortcuts of the outer DWM.

Only things not working

- picom - but this you can test anyway nicely outside, did not dig into getting it up
- xfce4-panel - unless I kill it outside before starting xnest:

[![](img/xnest.gif)](img/xnest.gif)


## Drag and Drop

Not using a Desktop Environment but Window Manager only requires some integration for drag and drop,
which you need all the time in the age of web based services.

[dragon](https://github.com/mwh/dragon) is the solution, together with a little
[xdotool/scrot](https://unix.stackexchange.com/a/557100/123121) hack of mine:


[![](img/drag_into.gif)](img/drag_into.gif)

Here the script:
```bash lp 
bat -f /home/gk/bin/drag_into
```

I.e.: Hotkey to start script -> select area -> click into drop area. Done.


It uses scrot to make a screenshot of a selected area, then dragon to create a drag window top left,
then xdotool to click and drag that to the point where you click.


## Services

Via the autostart patch I start these:

```bash lp 
bat -f /home/gk/.config/dwm/autostart.sh
```


## No Gaps - but Gaps

Vanitygaps is bloated plus I wanted a prominent active window indicator.

Solution: I simply use thick borders and have them black for the non active window and white for the active one via dwm, then set them to 0.7 transparent via picom:


    # Opacity of window titlebars and borders. (0.1 - 1.0, disabled by default)
    # frame-opacity = 1.0
    frame-opacity = 0.7;


=> That effects black far more than white.

I.e. there are actually no gaps - but the illusion is given.

[![](img/dwmgaps.png)](img/dwmgaps.png)


## Misc Tips

- On a fresh xfce spin fedora use `lxappearance` for gtk theming.
- Mouse cursor size: .Xresources -> Xcursor.size 40


## Config

For varying shortcuts I don't recompile dwm but use sxhkdrc:

```bash lp 
bat -f /home/gk/.config/sxhkd/sxhkdrc
```





This is my full config

```c lp mode=show_file fn=/home/gk/.config/dwm/config.h
```


