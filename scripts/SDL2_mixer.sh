#!/bin/bash -ex
# Cross-compile SDL2_mixer for Emscripten

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

# Note: Ren'Py: not needed; pygame_sdl2: compile-time dependency

CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
HOSTPYTHON=$BUILD/hostpython/bin/python

cd $BUILD/
tar xf $CACHEROOT/SDL2_mixer-2.0.1.tar.gz
cd SDL2_mixer-2.0.1/

mkdir -p build
cd build/

# Note: this is a minimal build just to fix LinkError-s
# TODO: stub it instead?
EMCONFIGURE_JS=1 emconfigure ../configure \
  --prefix $INSTALLDIR --disable-shared \
  --enable-music-wave \
  --disable-music-ogg-shared --disable-music-ogg \
  --disable-music-midi \
  --disable-music-midi-native --disable-music-midi-fluidsynth --disable-music-midi-fluidsynth-shared \
  --disable-music-mod-modplug --disable-music-mod-modplug-shared \
  --disable-music-mod --disable-music-mod-mikmod-shared \
  --disable-music-cmd \
  --disable-music-flac --disable-music-flac-shared \
  --disable-music-mp3 --disable-music-mp3-smpeg --disable-music-mp3-smpeg-shared --disable-smpegtest
emmake make -j$(nproc)
emmake make install
