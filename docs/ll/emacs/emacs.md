# Emacs

Just a few findings - mainly for org mode

## Spelling

- pm -S aspell aspell-de aspell-en
- ispell-change-dictionary -> select e.g. en
- flyspell-mode (toggle on)

-> all wrong words underlined now.

Note: Could not change dictionary within the doc the second try, had to change like this:

```
config.el
70:(defvar ispell-dictionary)
72:(setq ispell-dictionary "en_US")
```

## ``jj`` - Exit Insert Mode

Doom already defines `jk` to exit insert mode, but we want also `jj`.

    (base) [root@axgk .doom.d]# vi -- +bindings.el

And there:

    (defun my-jj ()
      (interactive)
      (let* ((initial-key ?j)
             (final-key ?j)
             (timeout 0.5)
             (event (read-event nil nil timeout)))
        (if event
            ;; timeout met
            (if (and (characterp event) (= event final-key))
                (evil-normal-state)
              (insert initial-key)
              (push event unread-command-events))
          ;; timeout exceeded
          (insert initial-key))))

    (define-key evil-insert-state-map (kbd "j") 'my-jj)

## Kroki - on demand

Best way for plots - NOT eval at any export, for too slow, but rather on demand.

```org
#+begin_src sh :results raw :exports results
~/docs/latex/plot img/cred1.png <<eof
actor subscriber as u1
(...)
note over cpe: provisioned, locked
eof
#+end_src
```

with plot a python file, executed when hitting enter on the first line:

```python

(base) [root@95f00130b0e0 latex]# cat plot
#!/usr/bin/env python
import sys, os
import base64
import zlib

KROKI_ENDPOINT = 'https://kroki.io' # or axc2...


class argv:
    typ = 'plantuml'
    fmt = 'svg'
    fn = None


def die(msg):
    msg = log(msg)
    print(msg)
    sys.exit(0)  # otherwise org wont' show results


def log(msg):
    msg = ' '.join(msg) if isinstance(msg, (list, tuple)) else msg
    os.system('notify-send "%s"' % msg)
    with open('/tmp/plotlog', 'a') as fd:
        fd.write(msg + '\n')
    return msg


mydir = lambda: os.path.dirname(os.path.abspath(__file__))


def add_plant_style(spec):
    spec = 'skinparam backgroundcolor transparent\n' + spec
    fn = mydir() + '/plantuml_style'
    if os.path.exists(fn):
        with open(fn) as fd:
            spec = fd.read() + '\n' + spec
    return spec


def read_argv():
    log(sys.argv)
    if not len(sys.argv) > 1:
        die('require filename of chart as first arg')
    argv.fn = f = sys.argv[1]
    if f.endswith('.png'):
        argv.fmt = 'png'


def main():
    read_argv()
    spec = sys.stdin.read()
    if argv.typ == 'plantuml':
        spec = add_plant_style(spec)
    spec = spec.encode('utf-8')
    pth = base64.urlsafe_b64encode(zlib.compress(spec)).decode('utf-8')
    url = '/'.join([KROKI_ENDPOINT, argv.typ, argv.fmt])
    log(['fetching', url])

    # pngs need binary:
    cmd = 'wget "%s/%s" -O  "%s"' % (url, pth, argv.fn)
    cmd = ('mkdir -p "%s"; ' % os.path.dirname(argv.fn)) + cmd
    os.system(cmd)
    f = argv.fn
    if not f[0] in ('.', '/'):
        f = './' + f
    res = '[[%s]]' % f
    return res


if __name__ == '__main__':
    print(main())

```

