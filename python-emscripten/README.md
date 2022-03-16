Python compilation scripts and patches to run in the browser.

<https://www.beuc.net/python-emscripten/python>

Build requirements: Emscripten, python3, gcc, make, quilt

Emscripten: download prebuilt binaries (or [build from source](https://emscripten.org/docs/building_from_source/))

    git clone https://github.com/emscripten-core/emsdk/
    pushd emsdk/
    ./emsdk install 2.0.7
    ./emsdk activate 2.0.7
    popd
    source emsdk/emsdk_env.sh

Python for the web browser!

    cd 3.8/
    ./python.sh
    ./package-pythonhome.sh repr.py base64.py ...
    emcc ... -lpython3.8 -s EMULATE_FUNCTION_POINTER_CASTS=1

Web demo: <https://www.beuc.net/python-emscripten/demo/>

    ./webprompt.sh
    emrun --serve_after_close t/index.html

Real-world showcase: [RenPyWeb](https://github.com/renpy/renpyweb).

Emscripten evolves regularly with (minor) breaking changes.  
If you use a different version compilation may break.

Mirrors:

- <https://gitlab.com/python-emscripten/python>
- <https://github.com/python-emscripten/python>
