# RenPyWeb - Ren'Py in your HTML5 web browser

This is the build environment for RenPyWeb.

## How to build

- [Install emscripten](https://emscripten.org/docs/building_from_source/building_emscripten_from_source_on_linux.html) 1.38.28 and apply
  `patches/emscripten.patch`

- Adapt `env.sh` and `source` it

- Type:
  `make`


## How to run locally

- Firefox: double-click on `build/t/index.html`

- Firefox or Chromium:

        cd build/t/
        python3 -m http.server 8000
        chromium http://localhost:8000/


## ASMJS version

Use `asmjs.html` instead of `index.html`.

ASMJS is deprecated in favor of WebAssembly.  It can be used for older
browsers, but it is most useful as a debugging tool because WASM
sometimes fails to provide enough information.


## How to make small-scale tests

Check the `pygame-example-*` targets. Symlink `pygame-example/main.py`
to the variant you wish to experiment with.

Also check the `native` target to try to run Ren'Py natively with some
Emscripten behavior.


## How to make the devkit

    make devkit


## How to update Ren'Py

    cd build/renpy/
    quilt pop -a
    git stash
    git pull
    git checkout ...
    git stash pop
    git diff > .../patches/renpy_TOSPLIT-xxx.patch
    quilt push / quilt refresh

Edit `scripts/renpy_modules-static.sh` and update the Git commit or
tag accordingly.
