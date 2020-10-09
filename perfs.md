## Performances

RenPyWeb is currently reasonably fast (for a
Ren'Py/Python/C/WebAssembly stack :)).

A first performance boost was done by switching from Emscripten
"fastcomp" with Emterpreter, to Emscripten "upstream" with Asyncify.


Here are a few leads to consider for better performances.

### Interruptible main loop

Normally your computer runs the game and let it do what it wants until
it quits.  However the browser only gives control to the game to
render a single image - and the game needs to give control back as
soon as possible, ideally 60 times per second.

The root issue is that Ren'Py's main loop is strongly recursive, and
cannot be interrupted.  We were able to add specific stop/resume
points using the Asyncify technology, at the cost of some performance
in Python.

Fixing it would be ideal, but would require rewriting a lot of Ren'Py.


### Full threading support

Whenever RenPyWeb takes too much time for certain actions, the browser
just waits for it, at the cost of slightly freezing the game or
breaking the audio stream (for audio, a larger buffer/latency was used
as a temporary work-around).

When we say "certain actions", this can be running background tasks
such as sound decoding, image prediction and autosave; or complex
tasks like rendering a detailed Screen.

In desktop/mobile Ren'Py, background tasks are run in threads.
However the browser's JavaScript and WebAssembly are mono-threaded;
those background tasks need to be done along with rendering the
current frame, causing random delays.

To fix this, we need full threading support in the browser, so we can
run Ren'Py in a thread without interrupting it (so we can drop
Asyncify and reclaim perfs), and run background tasks in their own
threads (so they don't block execution and cause delay - plus fix
other shortcomings such as video support).

Full threading support in the browser requires:

- [Worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API):
  present in modern browsers

- [SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer):
  present in Chrome, present in Firefox but requires specific server-side headers

- [WebAssembly threads](https://developers.google.com/web/updates/2018/10/wasm-threads):
  mostly same as SharedArrayBuffer in 2020, to check

- [pthread emulation](https://emscripten.org/docs/porting/pthreads.html):
  to mimic thread by running 2 separate Worker apps with all the
  memory in SharedArrayBuffer, while proxying text and graphic output
  to the main thread; in progress

- threaded/proxied version of the SDL2/OpenGL stack as ported to
  Emscripten; only basic OpenGL is available as of 2019-08

Threading seem to come with its whole lot of constraints though, so
it's not entirely sure we'll gain raw perfs in the end.
