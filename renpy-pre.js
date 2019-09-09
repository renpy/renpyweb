/*
Emscripten hooks - downloads external Ren'Py game on demand

Copyright (C) 2019  Sylvain Beucler

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

function httpRequest(method, url) {
    return new Promise(function(resolve, reject) {
        var wasmXHR = new XMLHttpRequest();
        wasmXHR.open(method, url, true);
        // Tell browser not to corrupt the cache on HEAD + max-age=0...
        if (method == 'HEAD') wasmXHR.setRequestHeader("Cache-Control", "no-store");
        wasmXHR.responseType = 'arraybuffer';
        wasmXHR.onload = function() {
	    if (wasmXHR.status == 200 || wasmXHR.status == 304 || wasmXHR.status == 206 || (wasmXHR.status == 0 && wasmXHR.response)) {
		resolve(wasmXHR);
	    } else {
		reject(wasmXHR);
	    }
	};
        wasmXHR.onerror = function() { reject(wasmXHR); }
        wasmXHR.send(null);
    });
}

// gzip fallback for annoying CDNs
// https://groups.google.com/forum/#!msg/emscripten-discuss/ORbvqatO9hE/pZcMKTzEAwAJ
// Adapted from emscripten/src/preamble.js:
// - Compilation streaming only if the .wasm is available with gzip HTTP compression
// - Falls back to JS decompression of .wasm.gz otherise
// https://emscripten.org/docs/api_reference/module.html#Module.instantiateWasm
Module.instantiateWasm = function(imports, successCallback) {
  // Async compilation can be confusing when an error on the page overwrites Module
  // (for example, if the order of elements is wrong, and the one defining Module is
  // later), so we save Module and check it later.
  var trueModule = Module;
  function receiveInstantiatedSource(output) {
    // 'output' is a WebAssemblyInstantiatedSource object which has both the module and instance.
    // receiveInstance() will swap in the exports (to Module.asm) so they can be called
    assert(Module === trueModule, 'the Module object should not be replaced during async compilation - perhaps the order of HTML elements is wrong?');
    trueModule = null;
      // TODO: Due to Closure regression https://github.com/google/closure-compiler/issues/3193, the above line no longer optimizes out down to the following line.
      // When the regression is fixed, can restore the above USE_PTHREADS-enabled path.
    successCallback(output['instance']);
  }

  var module_name = 'index'
  function instantiateArrayBuffer(receiver) {
    var wasm = httpRequest('GET', module_name+'.wasm.gz');
    wasm.then(
      function(xhr) {
        compressed = xhr.response
        var t = Date.now();
        var wasmBinary = Zee.decompress(new Uint8Array(compressed));
        console.log(module_name+'.wasm.gz decompressed in ' + ((Date.now() - t)/1000).toFixed(2) + ' secs');
        var wasmInstantiate = WebAssembly.instantiate(new Uint8Array(wasmBinary), imports).then(function(output) {
            successCallback(output.instance);
        }).catch(function(e) {
            Module.setStatus('wasm instantiation failed! ' + e);
        });
      },
      function(xhr) {
        Module.setStatus("Error while downloading " + xhr.responseURL
                     + " : " + xhr.statusText + " (status code " + xhr.status + ")");
      }
    );
    return {}; // Compiling asynchronously, no exports.
  }

  // Prefer streaming instantiation if available.
  var wasm = httpRequest('HEAD', module_name+'.wasm');
  wasm.then(
    function(xhr) {
      console.log(module_name+'.wasm content-encoding: ' + xhr.getResponseHeader('content-encoding'));
      if (xhr.getResponseHeader('content-encoding') == 'gzip' &&
        !Module['wasmBinary'] &&
        typeof WebAssembly.instantiateStreaming === 'function' &&
        !isDataURI(wasmBinaryFile) &&
        typeof fetch === 'function') {
          WebAssembly.instantiateStreaming(fetch(wasmBinaryFile, { credentials: 'same-origin' }), imports)
	    .then(receiveInstantiatedSource, function(reason) {
              // We expect the most common failure cause to be a bad MIME type for the binary,
              // in which case falling back to ArrayBuffer instantiation should work.
              err('wasm streaming compile failed: ' + reason);
              err('falling back to .wasm.gz');
              instantiateArrayBuffer(receiveInstantiatedSource);
            });
      } else {
        err('falling back to .wasm.gz');
        instantiateArrayBuffer(receiveInstantiatedSource);
      }
    },
    function(xhr) {
      err('HEAD ' + xhr.responseURL + ' failed: ' + xhr.status);
      err('falling back to .wasm.gz');
      instantiateArrayBuffer(receiveInstantiatedSource);
    }
  );
  return {}; // no exports yet; we'll fill them in later
}


// Download specified game.zip and extract&run it
Module['onRuntimeInitialized'] = function() {
    _GET = {};
    if (location.search.length > 0) {
      location.search.substr(1).split('&').forEach(function(item) {
        _GET[item.split("=")[0]] = item.split("=")[1]
      });
    }
    //var query_string = '?';
    //for (i in _GET) { query_string += i+'='+_GET[i]+'&'; }
    //query_string = query_string.slice(0, -1);


    var url = DEFAULT_GAME_FILENAME;
    
    if (_GET['game']) {
	if (_GET['game'].match(/^[0-9a-z._-]+$/i)) {
	    url = _GET['game'];
	} else {
	    // XSS: prevent executing untrusted remote/relative Python code
	    // (that could steal or modify same-origin data)
	    throw "Invalid game filename.";
	}
    }

    var xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.responseType = 'arraybuffer';
    xhr.onprogress = function(event) {
        var size = -1;
        if (event.total) size = event.total;
        if (event.loaded) {
            if (!xhr.addedTotal) {
                xhr.addedTotal = true;
                if (!Module.dataFileDownloads) Module.dataFileDownloads = {};
                Module.dataFileDownloads[url] = {
                    loaded: event.loaded,
                    total: size
                };
            } else {
                Module.dataFileDownloads[url].loaded = event.loaded;
            }
            var total = 0;
            var loaded = 0;
            var num = 0;
            for (var download in Module.dataFileDownloads) {
                var data = Module.dataFileDownloads[download];
                total += data.total;
                loaded += data.loaded;
                num++;
            }
            total = Math.ceil(total * Module.expectedDataFileDownloads/num);
            if (Module['setStatus']) Module['setStatus']('Downloading Story... (' + loaded + '/' + total + ')');
        } else if (!Module.dataFileDownloads) {
            if (Module['setStatus']) Module['setStatus']('Downloading Story...');
        }
    };
    xhr.onerror = function(event) {
        console.log(xhr);
        console.log(event);
	Module.print("Cannot download game. Maybe the download was blocked, see the JavaScript console for more information.\n");
    }
    xhr.onload = function(event) {
        if (xhr.status == 200 || xhr.status == 304 || xhr.status == 206 || (xhr.status == 0 && xhr.response)) {
            FS.writeFile('game.zip', new Uint8Array(xhr.response));
            if (Module['setStatus']) Module['setStatus']('');
	    Module.print("Extracting Story...\n");
            window.setTimeout(function() { gameExtractAndRun(); }, 200);
        } else {
            console.log(xhr);
            console.log(event);
	    Module.print("Error while downloading " + xhr.responseURL
                         + " : " + xhr.statusText + " (status code " + xhr.status + ")\n");
        }
    };
    xhr.send(null);
}


// Don't throw exception on sys.exit()
Module['quit'] = function() {
    console.log('Module.quit');
    Module['setStatus']('Quit');
}
