#!/bin/bash -ex
# Cross-compile RenPy Cython modules for Emscripten, as static modules

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

# Compile statically so we can use 'emcc -s EMTERPRETER_ASYNC' in the main program

# Cf. https://mdqinc.com/blog/2011/08/statically-linking-python-with-cython-generated-modules-and-packages/
# + patches for setuplib.py

ROOT=$(dirname $(readlink -f $0))/..
CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
HOSTPYTHON=$(dirname $(readlink -f $0))/../python-emscripten/$PY2VER/crosspython-static/bin/python

RENPY_MODULES_ROOT="$ROOT/renpy"

unset RENPY_STEAM_PLATFORM
unset RENPY_STEAM_SDK

# TODO: Generate vc_version.py (git describe --tags --dirty --match start-7.2)
# (cd "$RENPY_MODULES_ROOT" && python -O distribute.py || true)

(
    # Install Python modules needed by Ren'Py.
    $HOSTPYTHON -m ensurepip
    $HOSTPYTHON -m pip install future==0.18.2

    cd $RENPY_MODULES_ROOT/module
    export RENPY_DEPS_INSTALL="$INSTALLDIR"  # doesn't work for emscripten ports, no '*.a'
    CC="$EMCC" LDSHARED="$EMCC" \
      CFLAGS="-I$INSTALLDIR/include -s USE_SDL=2 -s USE_FREETYPE=1" \
      LDFLAGS="-L$INSTALLDIR/lib" \
      RENPY_EMSCRIPTEN=1 RENPY_STATIC=1 \
      $HOSTPYTHON \
        setup.py \
          build_ext \
            -b emscripten-static/build-lib -t emscripten-static/build-temp \
          build \
          install -O2 --root $INSTALLDIR --prefix ''

    rm -f $INSTALLDIR/lib/python2.7/site-packages/_renpy*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*/*.so
)
