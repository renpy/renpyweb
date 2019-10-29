# RenPyWeb - Ren'Py in your HTML5 web browser

This is the build environment for RenPyWeb.

## How to build

- Install Ren'Py to `renpy/` and pygame\_sdl2 to `pygame_sdl2/`.  To
  build a game.zip, it's also necessary to either build Ren'Py for the
  host computer, or copy a lib directory from a similar Ren'Py version
  to `renpy/lib/`. This can be done for you with
  `scripts/checkout_renpy.sh`.

- Emscripten: download prebuilt binaries (or [build from source](https://emscripten.org/docs/building_from_source/building_emscripten_from_source_on_linux.html))

      git clone https://github.com/emscripten-core/emsdk/
      pushd emsdk/
      ./emsdk install 1.39.0
      ./emsdk activate --embedded 1.39.0
      popd
      source emsdk/emsdk_env.sh

- Emscripten: you need to recompile everything on upgrade:

      rm -rf build/ install/ python-emscripten/2.7.10/build/
      make cythonclean

- Emscripten: apply pending fixes:

      cd emsdk/emscripten/ && patch -p1 < ../../../patches/emscripten.patch

- Compile:
  `make`

- Install the 'web' add-on to Ren'Py:
  `scripts/install_in_renpy.sh`

- Package the game: from the Ren'Py interface, or using `scripts/distribute_game.sh`


## How to run locally

      make testserver
      $BROWSER http://localhost:8000/


## How to make small-scale tests

Check the `pygame-example-*` targets. Symlink `pygame-example/main.py`
to the variant you wish to experiment with.

Also check the `native` target to try to run Ren'Py natively with some
Emscripten behavior.


## Performances

RenPyWeb could be faster.

Normally your computer runs the game and let it do what it wants until
it quits.  However the browser only gives control to the game to
render a single image - and the game needs to give control back as
soon as possible, ideally 60 times per second.

The root issue is that Ren'Py's main loop is strongly recursive, and
cannot be interrupted.  We were able to add specific stop/resume
points using the Emterpreter technology, at the cost of performances
in Python.

Fixing it would be ideal, but would require rewriting a lot of Ren'Py.


In addition, whenever RenPyWeb takes too much time for certain
actions, the browser just waits for it at the cost of slightly
freezing the game or breaking the audio stream (for audio, a larger
buffer/latency was used as a temporary work-around).

When we say "certain actions", this can be running background tasks
such as sound decoding, image prediction and autosave; or complex
tasks like rendering a detailed Screen.

In desktop/mobile Ren'Py, background tasks are run in threads.
However the browser's JavaScript and WebAssembly are mono-threaded;
those background tasks need to be done along with rendering the
current frame, causing random delays.

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

- [WebAssembly threads](https://developers.google.com/web/updates/2018/10/wasm-threads):
  present in Chrome, present but disabled by default in Firefox

- [pthread emulation](https://emscripten.org/docs/porting/pthreads.html):
  to mimic thread by running 2 separate Worker apps with all the
  memory in SharedArrayBuffer, while proxying text and graphic output
  to the main thread; in progress

- threaded/proxied version of the SDL2/OpenGL stack as ported to
  Emscripten; only basic OpenGL is available as of 2019-08


If you have suggestions, feel free to file a bug report :)
