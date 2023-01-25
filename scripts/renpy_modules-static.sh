#!/bin/bash -ex
# Cross-compile RenPy Cython modules for Emscripten, as static modules

# Copyright (C) 2019, 2020, 2021  Sylvain Beucler

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

# Compile statically for performance and to avoid Emscripten current
# limitations with dynamic linking. See also
# https://github.com/renpy/pygame_sdl2/blob/master/setuplib.py

ROOT=$(dirname $(readlink -f $0))/..
CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
CROSSPYTHON=$(dirname $(readlink -f $0))/../python-emscripten/$PY2VER/crosspython-static/bin/python

RENPY_MODULES_ROOT="$ROOT/renpy"

unset RENPY_STEAM_PLATFORM
unset RENPY_STEAM_SDK

# TODO: Generate vc_version.py (git describe --tags --dirty --match start-7.2)
# (cd "$RENPY_MODULES_ROOT" && python -O distribute.py || true)

(
    # Install Python modules needed by Ren'Py.
    $CROSSPYTHON -m ensurepip
    $CROSSPYTHON -m pip install future==0.18.2 typing ecdsa==0.18.0

    cd $RENPY_MODULES_ROOT/module
    export RENPY_DEPS_INSTALL="$INSTALLDIR"  # doesn't work for emscripten ports, no '*.a'
    CC="$EMCC" LDSHARED="$EMCC" \
      CFLAGS="-I$INSTALLDIR/include -I$INSTALLDIR/include/freetype2 -s USE_SDL=2" \
      LDFLAGS="-r -L$INSTALLDIR/lib" \
      RENPY_EMSCRIPTEN=1 RENPY_STATIC=1 \
      $CROSSPYTHON \
        setup.py \
          build_ext \
            -b emscripten-static/build-lib -t emscripten-static/build-temp \
          build \
          install -O2 --root $INSTALLDIR --prefix ''

    rm -f $INSTALLDIR/lib/python2.7/site-packages/_renpy*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*/*.so
)
