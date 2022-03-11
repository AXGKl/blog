import json
import os
import sys
import time
from functools import partial

from server import J, R, reconfigure_server_pipelines, run_server, rx, asyn, Rx, wait
from tools import gevent, print

sys.path.append(__file__.rsplit('/', 1)[0])  # noqa
gevent.spawn(run_server)

done_clients = []


def test_server_one():
    pipelines = [[J.run_job], [R.send_response]]
    reconfigure_server_pipelines(pipelines)
    send_requests()


def test_server_two():
    pipelines = [
        [rx.flat_map(lambda job: Rx.just(job).pipe(asyn(), J.run_job)),],
        [R.send_response],
    ]
    reconfigure_server_pipelines(pipelines)
    send_requests()


def send_requests():
    """sending 3 requests in parallel, simulating 3 clients"""
    # yes we can reconfigure the pipeline while running;
    done_clients.clear()
    print('')
    for client in 1, 2, 3:
        s = partial(send_job_req_to_api_server, client=client)
        gevent.spawn(s)
        wait(10)
    while not len(done_clients) == 3:
        time.sleep(0.1)
    time.sleep(0.1)
    print('all_done', who=client)


def send_job_req_to_api_server(client):
    from requests import get

    print('Sending job', who=client)
    j, url = json.loads, 'http://127.0.0.1:50000/job%s/3/%s'
    chunks = get(url % (client, 100 * client), stream=True)
    [print('got chunk', j(r), who=client) for r in chunks.iter_lines()]
    print('done client', who=client)
    done_clients.append(client)
