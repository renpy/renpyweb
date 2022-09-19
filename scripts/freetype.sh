#!/bin/bash -ex
# Cross-compile FreeType for Emscripten

# Copyright (C) 2021  Sylvain Beucler

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
tar xf $CACHEROOT/freetype-2.10.1.tar.gz
cd freetype-2.10.1/

mkdir -p build
cd build/

# cf. renpy-build/tasks/freetype.py
sed -i.bak \
    -e 's,/\* #define FT_CONFIG_OPTION_SYSTEM_ZLIB \*/,#define FT_CONFIG_OPTION_SYSTEM_ZLIB,' \
    -e 's,/\* #define T1_CONFIG_OPTION_OLD_ENGINE \*/,#define T1_CONFIG_OPTION_OLD_ENGINE,' \
    -e 's,/\* #define CFF_CONFIG_OPTION_OLD_ENGINE \*/,#define CFF_CONFIG_OPTION_OLD_ENGINE,' \
    ../include/freetype/config/ftoption.h
emconfigure ../configure --prefix $INSTALLDIR --disable-shared --with-harfbuzz=no --host asmjs-unknown-none

make CCexe=gcc $(pwd)/apinames  # build tool, don't cross-compile
emmake make -j$(nproc)
emmake make install
