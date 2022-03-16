# Fake python wrapper for emscripten_* C functions for native testing

# Copyright (C) 2018, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

import time
import sys

sys.platform = 'emscripten'

def set_main_loop(py_function, fps, simulate_infinite_loop):
    print("def: set_main_loop", py_function, fps, simulate_infinite_loop)
    if not simulate_infinite_loop:
        # TODO: simulate browser loop in another Python script?
        pass
    py_function = <object>(py_function)
    if fps <= 0:
        fps = 60  # common screen refresh rate
    while True:
        time.sleep(1.0/fps)
        py_function()

def async_call(func, arg, millis):
    py_function = <object>(func)
    py_arg = <object>(arg)
    py_function(py_arg)

def exit_with_live_runtime():
    print("exit_with_live_runtime")

def sleep(ms):
    time.sleep(ms/1000.0)

def sleep_with_yield(ms):
    sleep(ms)

def run_script(script):
    print("run_script")
    print('\n'.join(["  "+l for l in script.splitlines()]))

def syncfs():
    print("syncfs")
