#!/bin/bash -ex
# Cross-compile libzip for Emscripten

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

cd $BUILD/
tar xf $CACHEROOT/libzip-1.7.3.tar.gz
cd libzip-1.7.3/

mkdir -p build
cd build/
cp "$PATCHESDIR/libzip-CMakeCache.txt" CMakeCache.txt

CPPFLAGS="-I$INSTALLDIR/include" CFLAGS="-O3" LDFLAGS="-L$INSTALLDIR/lib" \
  emcmake cmake \
    -D CMAKE_INSTALL_PREFIX=$INSTALLDIR \
    -D ENABLE_COMMONCRYPTO=false -D ENABLE_GNUTLS=false \
    -D ENABLE_MBEDTLS=false -D ENABLE_OPENSSL=false  \
    -D ENABLE_BZIP2=false -D ENABLE_LZMA=false \
    -D BUILD_TOOLS=false -D BUILD_REGRESS=false \
    -D BUILD_EXAMPLES=false -D BUILD_DOC=false \
    -D BUILD_SHARED_LIBS=false \
    -D ZLIB_LIBRARY=$INSTALLDIR/lib -D ZLIB_INCLUDE_DIR=$INSTALLDIR/include \
    ..
emmake make -j$(nproc) VERBOSE=1
emmake make install
