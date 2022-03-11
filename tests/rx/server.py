#!/usr/bin/env python
import json
import sys
import time
from functools import partial

import gevent
import gevent.queue
import rx as Rx
from flask import Flask, stream_with_context
from gevent import monkey
from gevent.pywsgi import WSGIServer
from rx import operators as rx
from rx.scheduler.eventloop import GEventScheduler as GS
from tools import gevent, now, print
from werkzeug.debug import DebuggedApplication
from werkzeug.serving import run_with_reloader

sys.path.append(__file__.rsplit('/', 1)[0])


monkey.patch_all()
app = Flask(__name__)
GS = GS(gevent)
jobs = Rx.subject.Subject()
results = Rx.subject.Subject()
flush_response = lambda q: q.put(StopIteration)  # closing the socket
wait = lambda dt: time.sleep(dt / 1000.0)
asyn = lambda: rx.delay(0, GS)


class J:
    """Job Running Pipeline Functions"""

    def _run_job(job):
        """syncronous job running"""
        # how is the job (transport, behaviour, ...):
        _, job = job['meta'].pop, job['job']
        parts, dt, q, ts = _('parts'), _('dt'), _('req'), _('ts')
        print('running job', job)
        for c in range(parts):
            wait(dt)
            print('got result part', c, job)
            res = {
                'res': '%s result %s' % (job, c),
                'nr': c,
                'dt': now() - ts,
                'req': q,
            }
            results.on_next(res)
        wait(dt)
        flush_response(q)
        return

    run_job = rx.map(_run_job)


def interested_clients(res):
    """Work via a central registry of clients who want job results"""
    # here we just added "them" directly into the result:
    return [res.pop('req')]


class R:
    def _send_response(res):
        clients = interested_clients(res)
        ser = json.dumps(res) + '\r\n'
        [c.put(ser) for c in clients]
        return res

    send_response = rx.map(_send_response)


def new_job(job, meta):
    """Production decoupled from repsonse sending"""
    jobs.on_next({'job': job, 'meta': meta})


@app.route('/<job>/<int:parts>/<int:dt>')
def index(job, parts, dt):
    """
    The request handling greenlet.

    The client can parametrize how many data parts the job result should have - and
    when they 'arrive'.

    Creates a queue which, when seing an item, will cause a chunk response
    """
    # eventhandlers can produce here and we'll send to the client:
    q = gevent.queue.Queue()

    def generate():
        for data in q:
            yield data
        print('closing request socket')

    meta = {'parts': parts, 'dt': dt, 'req': q, 'ts': now()}
    new_job(job, meta)
    _ = 'application/json'
    return app.response_class(stream_with_context(generate()), mimetype=_)


# ------------------------------------------------------------------------------- server
def reconfigure_server_pipelines(pipelines, subs=[0, 0]):
    print('starting processing pipelines for jobs and incomming data')
    if subs[0]:
        print('stopping old pipeline')
        [s.dispose() for s in subs]

    for i in [0, 1]:
        s = [jobs, results][i].pipe(asyn(), *pipelines[i])
        subs[i] = s.subscribe()


def run_server():
    print('starting server at 50000')
    http_server = WSGIServer(('', 50000), DebuggedApplication(app))
    http_server.serve_forever()
