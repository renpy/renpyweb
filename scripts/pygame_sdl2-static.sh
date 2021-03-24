#!/bin/bash -ex
# Cross-compile pygame_sdl2 for Emscripten, as static modules

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

PYGAME_SDL2_ROOT=$ROOT/pygame_sdl2
(
    cd $PYGAME_SDL2_ROOT/

    # Ensure harfbuzz is compiled without CFLAGS set, work-around for:
    # https://github.com/emscripten-core/emscripten/issues/13648#issuecomment-805844779
    embuilder build harfbuzz

    # PYGAME_SDL2_CFLAGS='': inhibit running sdl2-config --cflags
    # PYGAME_SDL2_LDFLAGS='': inhibit running sdl2-config --libs
    CC="$EMCC" LDSHARED="$EMCC" \
      CFLAGS="-I$INSTALLDIR/include -I$INSTALLDIR/include/SDL2 -s USE_SDL=2 -s USE_SDL_MIXER=2 -s USE_SDL_TTF=2" \
      LDFLAGS="-r -L$INSTALLDIR/lib" \
      PYGAME_SDL2_CFLAGS='' PYGAME_SDL2_LDFLAGS='' PYGAME_SDL2_STATIC=1 \
      $CROSSPYTHON \
      setup.py \
        build_ext \
          -b emscripten-static/build-lib -t emscripten-static/build-temp \
        build \
	install -O2 --root $INSTALLDIR --prefix ''
    PYGAME_SDL2_CFLAGS='' PYGAME_SDL2_LDFLAGS='' \
      $CROSSPYTHON \
      setup.py install_headers

    rm -f $INSTALLDIR/lib/python2.7/site-packages/pygame_sdl2/*.so
)
