/* Copyright 2022 Teyut <teyut@free.fr>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/* This file contains code for running Python statements
 * in Ren'Py process from JS
 */

(function() {
  let cmd_queue = [];
  let cur_cmd = undefined;
  let debug = false;

  function dbg_log(...args) {
    if(debug) console.debug(...args);
  }

  /** This functions is called by the wrapper script at the end of script execution. */
  function cmd_callback(result) {
    dbg_log('cmd_callback', result);

    if(cur_cmd === undefined) {
      console.error('Unexpected command result', result);
      return;
    }

    try {
      if(result.error !== undefined) {
        dbg_log('ERROR', result.name, result.error, result.traceback);
        const e = new Error(result.error);
        e.name = result.name;
        e.traceback = result.traceback;
        cur_cmd.reject(e);
      } else {
        dbg_log('SUCCESS', result.data);
        cur_cmd.resolve(result.data);
      }
    } finally {
      cur_cmd = undefined;
      send_next_cmd();
    }
  }

  /** Prepare and send the next command to be executed if any. */
  function send_next_cmd() {
    if(cmd_queue.length == 0) return

    cur_cmd = cmd_queue.shift();
    dbg_log('send_next_cmd', cur_cmd);

    // Convert script to base64 to prevent having to escape
    // the script content as a Python string
    const script_b64 = btoa(cur_cmd.py_script);
    const wrapper = 'import base64, emscripten, json, traceback;\n'
        + 'try:'
        + "result = None;"
        + "exec(base64.b64decode('" + script_b64 + "').decode('utf-8'));"
        + "result = json.dumps(dict(data=result));"
        + "\n"
        + "except Exception as e:"
        + "result = json.dumps(dict(error=str(e), name=e.__class__.__name__, traceback=traceback.format_exc()));"
        + "\n"
        + "emscripten.run_script('_renpy_cmd_callback(%s)' % (result,));";

    dbg_log(wrapper);

    // Write script to the global variable Ren'Py is monitoring
    window._renpy_cmd = wrapper;
  }

  /** Add a command to the queue and execute it if the queue was empty. */
  function add_cmd(py_script, resolve, reject) {
    const cmd = {py_script: py_script, resolve: resolve, reject: reject};
    dbg_log('add_cmd', cmd);
    cmd_queue.push(cmd);

    if(cur_cmd === undefined) send_next_cmd();
  }

  /* Global definitions */

  /** Execute Python statements in Ren'Py Python's thread. The statements are executed
   * using the renpy.python.py_exec() function, and the value of the "result" variable
   * is passed to the resolve callback. In case of error, an Error instance is passed
   * to the reject callback, with an extra "traceback" property.
   * @param py_script The Python script to execute.
   * @return A promise which resolves with the statements result.
   */
  renpy_exec = function(py_script) {
    return new Promise((resolve, reject) => {
      add_cmd(py_script, resolve, reject);
    });
  };

  /** Helper function to get the value of a Ren'Py variable.
   * @param name The variable name (e.g., "build.name").
   * @return A promise which resolves with the variable value.
   */
  renpy_get = function(name) {
    return new Promise((resolve, reject) => {
      renpy_exec('result = ' + name)
          .then(resolve).catch(reject);
    });
  };

  /** Helper function to set the value of a Ren'Py variable.
   * @param name The variable name (e.g., "build.name").
   * @param value The value to set. It should either be a basic JS type that
   *              will be converted to JSON, or a Python expression. The raw
   *              parameter must be set to true for the latter case.
   * @param raw (optional) If true, value is a valid Python expression.
   *            Otherwise, it must be a basic JS type.
   * @return A promise which resolves with true in case of success
   *         and fails otherwise.
   */
  renpy_set = function(name, value, raw) {
    let script;
    if(raw) {
      script = name + " = " + value + "; result = True";
    } else {
      // Using base64 as it is unclear if we can use the output
      // of JSON.stringify() directly as a Python string
      script = 'import base64, json; '
          + name + " = json.loads(base64.b64decode('"
          + btoa(JSON.stringify(value))
          + "').decode('utf-8')); result = True";
    }
    return new Promise((resolve, reject) => {
      renpy_exec(script)
          .then(resolve).catch(reject);
    });
  };

  _renpy_cmd_callback = cmd_callback;

})();