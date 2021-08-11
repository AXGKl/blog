# Why Suckless

I love [suckless software](https://suckless.org/).

I have a pretty emotional relation with my machine and its OS, spending so much time with it. And
although I had a "perfect" OSX setup (not that I'm smart but I fiddled over a decade to improve it
via BTT, Alfred, Hammerspoon, (...), I got more and more ...irritated by the general behaviour of Apple, the
megacorp, especially after Steve Jobs passed away from us.

It was not not even their crap hardware they released at time of my switch in 2018 (F keys
removed for an emojibar, no self repairability, throttling, broken keyboards, dongle hell). Because the
machine which I used and loved was anyway a 2015 15' retina MBP, which I consider still a perfect
pro-hardware for software devs in my area of work.  
And in 2020 they solved *a lot* of their problems in admittedly impressive ways, with M1.

No, rationally there were good reasons to work on Linux directly and not in VMs or Containers,
with the software in my area of work running on Linux.

But why suckless?

Switching to Linux, just to get a cheap attempt to be more "fancy" than OSX and also even more
"politically correct" than Apple, was no option...

Then I stumbled over [Luke Smith][ls1] and [DT][dt2] and learned with great excitement that there is
this other, lean and clean but still very efficient way of interacting with the machine: *The Window
Manager only* way. And looking around whats there, you sooner or later hit suckless. Most WMs are
derived from it, e.g. XMonad. The whole WM is only 2k sloc(!) and it compiles in < 1 second(!)

*Yes qtile was actually the more sensible choice for a python guy like me but dwm code was so easy
to read that I could, even as a C noob, even hack into it - plus: it's directly on the X11 libs and not
hidden, like with qtile, by large frameworks in between.*

So: You can [read](http://git.suckless.org/dwm/file/dwm.c.html) the code and learn how a WM under
X11 actually works. 

And its not just the WM:

- You learn that it was suckless who really invented how fzf, rofi and all these pipe-able list
  selection tools work - with [dmenu](http://tools.suckless.org/dmenu/).

- Then you'll learn how a terminal works - using [st](https://st.suckless.org/). If you ever tried
  to compile a [VTE based](https://wiki.gnome.org/Apps/Terminal/VTE), and I did because I wanted to
  change sth in terminator, you'll understand how simple (in the best sense possible) st is. And
  what bloat free really means, in terms of direct advantages.

- and they have so many more lean and clean tools like [tabbed](https://tools.suckless.org/tabbed/).


[ls1]: https://www.youtube.com/watch?v=unqsQJaECv0
[dt2]: https://www.youtube.com/watch?v=Obzf9ppODJU
