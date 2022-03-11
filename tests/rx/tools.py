import time
import sys
from threading import current_thread
import gevent


now = lambda: int(time.time() * 1000)
t0 = now()
dt = lambda: now() - t0
thread = lambda: current_thread().name.replace('Dummy-', '').replace('MainThread', 'M')
gray = '\x1b[0;38;5;245m%s\x1b[0m'


def print(*a, p=print, who=0, **kw):
    pre = '%s %2s ' % (gray % ('%5s' % dt()), thread())
    msg = ' '.join([str(i) for i in a])
    msg = '\x1b[3%sm[%s] %s\x1b[0m' % (who + 1, who or 'S', msg)
    p(pre + msg, **kw)
    return a[0]


#  --------------------   quick test follows -------------------------------------------
if __name__ == '__main__':
    from gevent import monkey

    sleep, asyn = gevent.sleep, gevent.spawn
    if sys.argv[-1] == 'patched':
        monkey.patch_all()
        assert time.sleep == gevent.sleep  # since patched
    print('msg 1')

    def f(who):
        sleep(0.05)
        print('async msg', who=who)

    asyn(f, 2)
    asyn(f, 3)
    asyn(f, 0)

    sleep(0.1)
    print('msg 3', who=4)
