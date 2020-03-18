#!/bin/bash -ex
# Cross-compile libzip for Emscripten

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

CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
HOSTPYTHON=$BUILD/hostpython/bin/python
MODE=opti
CFLAGS=-O3

cd $BUILD/
tar xf $CACHEROOT/libzip-1.6.1.tar.gz
cd libzip-1.6.1/

# This thing can't properly set its own LIBS (-lz), disable executables generation
sed -i -e 's/ADD_SUBDIRECTORY(man)/#&/' CMakeLists.txt
sed -i -e 's/ADD_SUBDIRECTORY(src)/#&/' CMakeLists.txt
sed -i -e 's/ADD_SUBDIRECTORY(regress)/#&/' CMakeLists.txt
sed -i -e 's/ADD_SUBDIRECTORY(examples)/#&/' CMakeLists.txt
mkdir -p cross-emscripten-$MODE
cd cross-emscripten-$MODE/

CPPFLAGS="-I$INSTALLDIR/include" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS -L$INSTALLDIR/lib" \
  emcmake cmake \
    -D CMAKE_INSTALL_PREFIX=$INSTALLDIR \
    -D ENABLE_GNUTLS=false -D ENABLE_OPENSSL=false -D ENABLE_COMMONCRYPTO=false \
    -D ENABLE_BZIP2=false -D ENABLE_LZMA=false \
    -D BUILD_SHARED_LIBS=false \
    -D ZLIB_LIBRARY=$INSTALLDIR/lib -D ZLIB_INCLUDE_DIR=$INSTALLDIR/include \
    ..
sed -i -e 's/^#define SIZEOF_OFF_T 7/#define SIZEOF_OFF_T 4/' config.h
emmake make -j$(nproc)
emmake make install
