# HTTP Requests that work in both native Ren'Py and RenPyWeb

# Copyright (C) 2019  Sylvain Beucler

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Native uses urllib2 https://docs.python.org/2/library/urllib2.html
# RenPyWeb uses XMLHttpRequest
#
# Ren'Py doesn't ship with certificates authorities, so for native
# Ren'Py add your server certificate chain in 'yourgame/game/ca.pem'
# e.g. 'ca.pem' in this directory (for Let's Encrypt)
# (not in a .rpa, urllib2 wants an existing filename)
# (for RenPyWeb, the browser's certificates are used)
#
# Currently a fixed timeout of 10 seconds is set.
#
# Requests do not rollback/forward (we can't alter the remote server!)
# but the user can, so beware that they may send a request multiple
# times (in which case Ren'Py will be unresponsive as rollback/forward
# skips UI updates); use renpy.in_rollback() to detect this.

init python:
    import os

    if renpy.emscripten:

        import emscripten, binascii, json
        class AsyncRequest:
            def __init__(self):
                while True:
                    self.filename = '/tmp/req-' + binascii.hexlify(os.urandom(8))
                    if not os.path.exists(self.filename):
                        break
                self.response = ''

            def send(self, endpoint, headers={}, data=None):
                emscripten.run_script(r'''
                  (function () {
                    try {
                      var filename = %s;
                      var url = %s;
                      var headers = %s;
                      var data = %s;

                      var xhr = new XMLHttpRequest();
                      var method = 'GET';
                      if (data !== null) {
                        method = 'POST';
                      }
                      xhr.open(method, url);

                      if (data !== null) {
                        xhr.setRequestHeader('Content-Type',
                          'application/x-www-form-urlencoded');
                      }
                      Object.keys(headers).forEach(function(key) {
                        xhr.setRequestHeader(key, headers[key]);
                      });

                      xhr.onerror = function(event) {
                          FS.writeFile(filename,
                            JSON.stringify({
                              'success': false,
                              'exception': "Request failed (possibly blocked)",
                            })
                          );
                      }
                      xhr.onload = function(event) {
                        if (this.status==200||this.status==304||this.status==206||this.status==0&&this.response) {
                          FS.writeFile(filename,
                            JSON.stringify({
                              'success': true,
                              'status': this.status,
                              'responseText': this.responseText
                            })
                          );
                        } else {
                          FS.writeFile(filename,
                            JSON.stringify({
                              'success': false,
                              'status': this.status,
                              'statusText': this.statusText,
                              'responseText': this.responseText
                            })
                          );
                        }
                      }

                      xhr.timeout = 10000;
                      xhr.ontimeout = function(event) {
                          FS.writeFile(filename,
                            JSON.stringify({
                              'success': false,
                              'status': event.target.status,
                              'statusText': 'timeout'
                            })
                          );
                      }

                      xhr.send(data);
                    } catch (exception) {
                      console.log(exception);
                      FS.writeFile(filename,
                        JSON.stringify({
                          'success': false,
                          'exception': exception,
                        })
                      );
                    }
                  })();
                ''' % (json.dumps(self.filename), json.dumps(endpoint),
                       json.dumps(headers), json.dumps(data)))
                # new TextDecoder('utf-8').decode(FS.readFile('/tmp/t'))

            def isAlive(self):
                return not os.path.exists(self.filename)
            def readfs(self):
                if os.path.exists(self.filename):
                    try:
                        self.response = json.loads(open(self.filename).read())
                    except ValueError, e:
                        self.response = { 'success': False, 'exception': str(e) }
                    os.unlink(self.filename)
            def getError(self):
                self.readfs()
                if self.response and not self.response.get('success', False):
                    if self.response.get('exception', None) is not None:
                        return 'Exception: ' + self.response['exception']
                    elif self.response.get('status', None) is not None:
                        if self.response.get('statusText', None) is not None:
                            return self.response['statusText'] + '(' + str(self.response['status']) + ')'
                        else:
                            return str(self.response['status'])
                return None
            def getResponse(self):
                self.readfs()
                if self.response and self.response.get('success', False):
                    return self.response['responseText']
                return None

    else:

        import threading, urllib2, httplib
        import time
        class AsyncRequest:
            def __init__(self):
                self.response = None
                self.error = None
            def send(self, endpoint, headers={}, data=None):
                req = urllib2.Request(endpoint, headers=headers, data=data)
                def thread_main():
                    cafile = os.path.join(renpy.config.gamedir, 'ca.pem')
                    if not os.path.exists(cafile): cafile = None
                    try:
                        r = urllib2.urlopen(req, cafile=cafile, timeout=10)
                        self.response = r.read()
                    except urllib2.URLError, e:
                        self.error = str(e.reason)
                    except httplib.HTTPException, e:
                        self.error = 'HTTPException'
                    except Exception, e:
                        self.error = 'Error: ' + str(e)
                renpy.invoke_in_thread(thread_main)
            def isAlive(self):
                return self.response is None and self.error is None
            def getError(self):
                return self.error
            def getResponse(self):
                return self.response


label asyncrequest_test:
    "test start"
    $ req = AsyncRequest()
    $ req.send('https://www.renpy.org/')
    $ timer = 0
    while not renpy.in_rollback() and req.isAlive():
        $ timer += 0.1
        show text "request in progress [timer]"
        pause 0.1
    $ ret = 'rollback'
    if req.getError():
        $ ret = req.getError()
    else:
        $ ret = req.getResponse().split("\n")[0]
    hide text
    "ret=[ret]"
    "test end"
    return
