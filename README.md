# RenPyWeb - Ren'Py in your HTML5 web browser

This is the build environment for RenPyWeb.

## How to build

- [Install emscripten](https://emscripten.org/docs/building_from_source/building_emscripten_from_source_on_linux.html) 1.38.30 and apply
  `patches/emscripten.patch`.  You can use `build_toolchain.sh` for this.

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

## Performances

RenPyWeb could be faster.

Whenever RenPyWeb takes too much time for certain actions, the browser
just waits for it at the cost of slightly freezing the game or
breaking the audio stream (for audio, a larger buffer/latency was used
as a temporary work-around).

When we say "certain actions", this can be running background tasks
such as sound decoding, image prediction and autosave; or complex
tasks like rendering a detailed Screen.

In desktop/mobile Ren'Py, background tasks are run in threads.
However the browser's JavaScript and WebAssembly are mono-threaded;
those background tasks need to be done along with rendering the
current frame, causing random delays.

In addition, normally your computer runs the game and let it do what
it wants until it quits.  However the browser only gives control to
the game to render a single image - and the game needs to give control
back as soon as possible, ideally 60 times per second.  Ren'Py's main
loop is strongly recursive, and cannot be interrupted without
rewriting half of Ren'Py.  We were able to add specific stop/resume points
using the Emterpreter technology, at the cost of performances in
Python.  Complex tasks hence take longer.

To fix this, we need full threading support in the browser, so we can
run Ren'Py in a thread without interrupting it (so we can ditch
Emterpreter and reclaim perfs), and run background tasks in their own
threads (so they don't block execution and cause delay - plus fix other
shortcomings such as video support).

Full threading support in the browser requires:

- [Worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API):
  present in modern browsers

- [SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer):
  present in Chrome, present but disabled by default in Firefox

- [pthread emulation](https://emscripten.org/docs/porting/pthreads.html):
  to mimic thread by running 2 separate Worker apps with all the
  memory in SharedArrayBuffer, while proxying text and graphic output
  to the main thread; in progress

- threaded version of the SDL2/OpenGL stack as ported to Emscripten; not started AFAIK


If you have suggestions, feel free to file a bug report :)
