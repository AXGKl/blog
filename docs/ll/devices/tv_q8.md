# Remote Controlling My Samsung Q8

Tizen OS Platform (from api/v2 below)

## API Explore
 
There is contact. Main problem with python default [samsungctl](https://github.com/Ape/samsungctl)
is the `ms.event.unauthorized` I'm getting with this series for any use case.

??? "info" "API Explore"

    This works w/o auth:

    From [here](https://github.com/Ape/samsungctl/issues/117#issuecomment-529234802): 
        
    ```
        ~ ❯ http http://tv.lan:8001/api/v2/
        HTTP/1.1 200 OK
        content-length: 1218
        content-type: application/json; charset=utf-8

        {
            "device": {
                "FrameTVSupport": "false",
                "GamePadSupport": "true",
                "ImeSyncedSupport": "true",
                "OS": "Tizen",
                "TokenAuthSupport": "true",
                "VoiceSupport": "true",
                "countryCode": "DE",
                "description": "Samsung DTV RCR",
                "developerIP": "0.0.0.0",
                "developerMode": "0",
                "duid": "uuid:85aa4d83-1bb6-410f-843a-658d51bc7270",
                "firmwareVersion": "Unknown",
                "id": "uuid:85aa4d83-1bb6-410f-843a-658d51bc7270",
                "ip": "10.0.0.28",
                "model": "18_KANTM2_QTV",
                "modelName": "QE55Q8FNA",
                "name": "[TV] Samsung Q8 Series (55)",
                "networkType": "wireless",
                "resolution": "3840x2160",
                "smartHubAgreement": "true",
                "ssid": "c0:25:06:ab:46:11",
                "type": "Samsung SmartTV",
                "udn": "uuid:85aa4d83-1bb6-410f-843a-658d51bc7270",
                "wifiMac": "CC:6E:A4:E3:A4:FC"
            },
            "id": "uuid:85aa4d83-1bb6-410f-843a-658d51bc7270",
            "isSupport": "{\"DMP_DRM_PLAYREADY\":\"false\",\"DMP_DRM_WIDEVINE\":\"false\",\"DMP_available\":\"true\",\"EDEN_available\":\"true\",\"FrameTVSupport\":\"false\",\"ImeSyncedSupport\":\"true\",\"TokenAuthSupport\":\"true\",\"remote_available\":\"true\",\"remote_fourDirections\":\"true\",\"remote_touchPad\":\"true\",\"remote_voiceControl\":\"true\"}\n",
            "name": "[TV] Samsung Q8 Series (55)",
            "remote": "1.0",
            "type": "Samsung SmartTV",
            "uri": "http://tv.lan:8001/api/v2/",
            "version": "2.0.25"
        }
    ```

    But:

    ```console
        ~/repos/samsungctl master !1 ?4 ❯ samsungctl --host tv.lan --port 8001 -v  --method websocket --timeout 2 KEY_HOME                                                                                                                                                                                                                                                                  samsungctl
    Traceback (most recent call last):
      File "/home/gk/repos/samsungctl/bin/samsungctl", line 33, in <module>
        sys.exit(load_entry_point('samsungctl==0.7.0+1', 'console_scripts', 'sam     File "/home/gk/repos/samsungctl/lib64/python3.9/site-packages/samsungctl-0.7.0+1-py3.9.egg/samsungctl/remote_websocket.py", line 76, in _read_response
        (...)
    samsungctl.exceptions.UnhandledResponse: {'event': 'ms.channel.unauthorized'}
    ~/repos/samsungctl master !1 ?4 ❯ samsungctl --host tv.lan --port 8002 -v  --method websocket --timeout 2 KEY_HOME                                                                                                                                                                                                                                                                  samsungctl
    Traceback (most recent call last):
      File "/home/gk/repos/samsungctl/bin/samsungctl", line 33, in <module>
        sys.exit(load_entry_point('samsungctl==0.7.0+1', 'console_scripts', 'samsungctl')())
      File "/home/gk/repos/samsungctl/lib64/python3.9/site-packages/samsungctl-0.7.0+1-py3.9.egg/samsungctl/__main__.py", line 112, in main
      (...)
      File "/home/gk/repos/samsungctl/lib64/python3.9/site-packages/websocket/_socket.py", line 125, in recv
        raise WebSocketConnectionClosedException(
    websocket._exceptions.WebSocketConnectionClosedException: Connection to remote host was lost.
    ~/repos/samsungctl master !1 ?4 ❯

    ```

## Detour to JS

This has even NodeRED:

https://github.com/Toxblh/samsung-tv-control

=== "Install"

    ```
    conda install nodejs
    npm install samsung-tv-control --save
    ```

    node modules in $HOME then..., no idea why not in conda: /home/gk/node_modules/samsung-tv-control/lib

=== "Example"

    `wget https://raw.githubusercontent.com/Toxblh/samsung-tv-control/master/example/index.js -O r.js`

    config:
    ```
    const config = {
      debug: true, // Default: false
      ip: "10.0.0.28",
      mac: "123456789ABC",
      nameApp: "NodeJS-Test", // Default: NodeJS
      port: 8002, // Default: 8002
      token: "12345678",
    };

    ```

=== "First Run"

    ```
    node r.js
    ```

Inspecting what's happening led to a first python api, where I can switch on/off the TV, send keys,
send text or open a browser URL:

## First Working Python

Funny that it works now w/o taking care for the token. Hmm...


```python

~/repos/samsungctl master !1 ?6 ❯ cat g.py
import json
import ssl
import time

import websocket

import _thread

jd = lambda o: json.dumps(o)
jl = lambda o: json.loads(o)

pp = lambda s: print(json.dumps(s, indent=4, sort_keys=True, default=str))


no_token = '12345'


class TV:
    ws = None
    send = lambda c: TV.ws.send(jd(c))
    token = no_token
    apps = None  # a list like:
    # # [
    #         {
    #             "appId": "111299001912",
    #             "app_type": 2,
    #             "icon": "/opt/share/weba...
    #             "is_lock": 0,
    #             "name": "YouTube"
    #         },
    #         {
    #             "appId": "11101200001",


class act:
    def key(k):
        TV.send(
            {
                'method': 'ms.remote.control',
                'params': {
                    'Cmd': 'Click',
                    'DataOfCmd': k,
                    'Option': 'false',
                    'TypeOfRemote': 'SendRemoteKey',
                },
            }
        )

    # off or on. Test on by http to :8001/api/v2 or simply ping it
    power = lambda: act.key('KEY_POWER')

    def find_apps():
        TV.send(
            {
                'method': 'ms.channel.emit',
                'params': {'data': '', 'event': 'ed.installedApp.get', 'to': 'host'},
                #'token': TV.token,
            }
        )

    def open_url(url):
        TV.send(
            {
                'method': 'ms.channel.emit',
                'params': {
                    'event': 'ed.apps.launch',
                    'to': 'host',
                    'data': {
                        'appId': 'org.tizen.browser',  # always, no scanning required
                        'action_type': 'NATIVE_LAUNCH',
                        #'metaTag': 'https://www.youtube.com/watch?v=ah0Nio4Z0zI',
                        'metaTag': url,
                    },
                },
            }
        )


class WS:
    def on_message(ws, message):
        msg = jl(message)
        pp(msg)
        ev = msg['event']
        if ev == 'ms.channel.connect':
            TV.token = msg['data']['token']
        elif ev == 'ed.installedApp.get':
            TV.apps = msg['data']['data']

        act.open_url('https://ard.de')

    def on_error(ws, error):
        print('Error', error)

    def on_close(ws, close_status_code, close_msg):
        print('### closed ###')

    def on_open(ws):
        def run(*args):
            act.key('KEY_HOME')

        _thread.start_new_thread(run, ())


if __name__ == '__main__':
    # websocket.enableTrace(True)
    TV.ws = websocket.WebSocketApp(
        #'wss://tv.lan:8002/',
        'wss://10.0.0.28:8002/api/v2/channels/samsung.remote.control?name=Tm9kZUpTLVRlc3Q=',  # &token=12345678',
        on_open=WS.on_open,
        on_message=WS.on_message,
        on_error=WS.on_error,
        on_close=WS.on_close,
    )
    TV.ws.run_forever(sslopt={'cert_reqs': ssl.CERT_NONE})
```



## References

- https://github.com/Toxblh/samsung-tv-control
- https://github.com/Ape/samsungctl

From there:

- http://sc0ty.pl/2012/02/samsung-tv-network-remote-control-protocol/
- https://gist.github.com/danielfaust/998441
- https://github.com/Bntdumas/SamsungIPRemote
- https://github.com/kyleaa/homebridge-samsungtv2016

