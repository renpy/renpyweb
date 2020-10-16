#!/bin/bash -ex
# Cross-compile libpng for Emscripten

# Copyright (C) 2019, 2020  Sylvain Beucler

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

CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
HOSTPYTHON=$BUILD/hostpython/bin/python
MODE=opti
CFLAGS=-O3

cd $BUILD/
tar xf $CACHEROOT/libpng-1.6.37.tar.gz
cd libpng-1.6.37/

#official config.sub/config.guess don't recognize 'asmjs-unknown-emscripten' :/
#cp -a ../config/config.sub ../config/config.guess .
#cp -a ../SDL2/config.sub ../SDL2/config.guess .
cp -a $PATCHESDIR/config.{sub,guess} .
mkdir -p cross-emscripten-$MODE
cd cross-emscripten-$MODE/

# emconfigure ../configure --prefix $INSTALLDIR
# => errors when trying to test assembly, weird test

emconfigure ../configure --host asmjs-unknown-emscripten --build $(sh ../config.guess) \
  --prefix $INSTALLDIR \
 CPPFLAGS="-I$INSTALLDIR/include" LDFLAGS="-L$INSTALLDIR/lib" CFLAGS="$CFLAGS"
emmake make -j$(nproc)
emmake make install
