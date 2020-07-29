#!/bin/bash -ex
# Compile Ren'Py modules statically for Emscripten mock environment

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

PYTHON=$(pwd)/python-emscripten/$PY2VER/build/hostpython/bin/python
PYTHONHOME=$(pwd)/python-emscripten/$PY2VER/build/hostpython/

(
    cd build/pygame_sdl2-static/
    $PYTHON setup.py build_ext -b native-static/build-lib -t native-static/build-temp
    $PYTHON setup.py install_headers
)

(
    # remove include files pointing to system's /usr/include/ (but preserving pygame_sdl2's headers)
    #rm -f ~/.virtualenvs/pygame_sdl2/include/python2.7/*
    cd build/renpy/module/
    #RENPY_DEPS_INSTALL="$(pwd)/../../Python-2.7.10/native::/usr::/usr/lib/x86_64-linux-gnu" ../../Python-2.7.10/native/python setup.py build_ext -b native-static/build-lib -t native-static/build-temp --include-dirs ../../Python-2.7.10/native/include/python2.7
    RENPY_DEPS_INSTALL="/usr::/usr/lib/x86_64-linux-gnu" $PYTHON setup.py build_ext -b native-static/build-lib -t native-static/build-temp -I ~/.virtualenvs/pygame_sdl2/include/python2.7
)

cython python-emscripten/mock/emscripten.pyx -o build/mock_emscripten.c
gcc -DSTATIC -DMOCK -DRENPY main.c build/mock_emscripten.c -I $PYTHONHOME/include/python2.7 $(ls build/pygame_sdl2-static/native-static/build-temp/*/*.o | grep -v mixer) build/renpy/module/native-static/build-temp/*/*.o build/renpy/module/native-static/build-temp/*.o $PYTHONHOME/lib/libpython2.7.a -lm -ljpeg -lpng -lz -lSDL2 -lSDL2_image -lSDL2_ttf -lfreetype -lfribidi -lGL -lGLEW -lavcodec -lavformat -lavutil -lswresample -lswscale -ldl -lutil -o build/renpy/main

# note: make sure the resulting executable is run from the Ren'Py folder, Ren'Py uses dirname(argv[0])
# PYTHONHOME=$HOME/workdir/emtests/renpyweb/install ./main
# also if you run in a renpy git clone: ln -s the_question/game .
