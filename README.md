# RenPyWeb - Ren'Py in your HTML5 web browser

This is the build environment for RenPyWeb.

## How to build

- Install emscripten 1.38.25 and apply
  `patches/emscripten-ports-sdl2emterpreter.patch`

- Adapt `env.sh` and `source` it

- Type:
  `make`


## How to run locally

    cd build/t/
    python3 -m http.server 8000


## How to make small-scale tests

Check the `pygame-example-*` targets. Symlink `pygame-example/main.py`
to the variant you wish to experiment with.

Also check the `native` target to try to run Ren'Py natively with some
Emscripten behavior.


## How to make the devkit

    make hosting-nogzip-zip


## Troubleshootings

If you get a weird stack trace referencing things like
`___Pyx_PyObject_CallNoArg_387` or `___Pyx_PyObject_CallNoArg_6345`,
this means some offsets changed in the code and the functions are not
whitelisted for the Emterpreter anymore.  Pick the new function names
from the stacktrace, update the `EMTERPRETIFY_WHITELIST` and
recompile.

This is ugly but out of our control for now.
