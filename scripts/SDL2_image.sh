#!/bin/bash -ex
# Cross-compile SDL2_image for Emscripten

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
if [ ! -d SDL2_image-2.6.2/ ]; then
    tar xf $CACHEROOT/SDL2_image-2.6.2.tar.gz
fi
(
    cd SDL2_image-2.6.2/

    mkdir -p build
    cd build/

    emconfigure ../configure --prefix $INSTALLDIR \
      --host asmjs-unknown-none \
      --disable-shared \
      \
      --disable-tif \
      --disable-imageio \
      --disable-jpg-shared \
      --disable-png-shared \
      --enable-webp \
      --disable-webp-shared \
      --disable-xcf  \
      --disable-svg \
      \
      --disable-tif-shared \
      --disable-xpm \
      --disable-gif \
      --disable-lbm \
      --disable-pcx \
      --disable-tga \
      --disable-bmp \
      --disable-xcf \
      --disable-qoi \
      \
      PKG_CONFIG_LIBDIR=$INSTALLDIR/lib/pkgconfig:$(emconfigure env|grep ^PKG_CONFIG_LIBDIR|sed 's/^PKG_CONFIG_LIBDIR=//') \
      CPPFLAGS="-I$INSTALLDIR/include" LDFLAGS="-s USE_SDL=2 -L$INSTALLDIR/lib" CFLAGS="-O3"

    emmake make -j$(nproc)
    emmake make install
)
