#!/bin/bash -ex
# Cross-compile SDL2_image for Emscripten

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
if [ ! -d SDL2_image-2.0.2/ ]; then
    tar xf $CACHEROOT/SDL2_image-2.0.2.tar.gz
fi
(
    cd SDL2_image-2.0.2/

    # webp
    (
        # prevent libtoolize from messing the parent ltmain.sh
	mkdir -p t1/t2/t3
	cp -a external/libwebp-0.6.0/ t1/t2/t3/
	cd t1/t2/t3/libwebp-0.6.0/
	if [ ! -e configure ]; then ./autogen.sh; fi
	mkdir -p cross-emscripten-$MODE
	cd cross-emscripten-$MODE/
	# Disable SIMD/SSE; check -s SIMD=1 for WASM and browser support some day
	EMCONFIGURE_JS=1 emconfigure ../configure --prefix $INSTALLDIR \
            --disable-shared --disable-threading --disable-sse2 --disable-sse4.1
	emmake make -j$(nproc)
	emmake make install
    )


    mkdir -p cross-emscripten-$MODE
    cd cross-emscripten-$MODE/
    EMCONFIGURE_JS=1 emconfigure ../configure --prefix $INSTALLDIR \
      --disable-shared \
      --enable-png --enable-jpg --enable-webp \
        --disable-png-shared --disable-jpg-shared --disable-webp-shared \
        --disable-tif --disable-tif-shared \
        --disable-bmp --disable-xpm --disable-gif --disable-lbm --disable-pcx \
        --disable-svg --disable-tga --disable-xcf  \
      PKG_CONFIG_LIBDIR=$INSTALLDIR/lib/pkgconfig:$(emconfigure env|grep ^PKG_CONFIG_LIBDIR|sed 's/^PKG_CONFIG_LIBDIR=//') \
      CPPFLAGS="-I$INSTALLDIR/include" LDFLAGS="-L$INSTALLDIR/lib" CFLAGS="$CFLAGS"

    emmake make -j$(nproc)
    emmake make install
)
