#!/bin/bash -ex
# Cross-compile ffmpeg for Emscripten

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

cd $BUILD/
tar xf $CACHEROOT/ffmpeg-3.0.tar.bz2
cd ffmpeg-3.0/

mkdir -p build
cd build/

export CFLAGS="-fno-common"
export CXXFLAGS="-fno-common"
# Configure flags from renpy-deps/build.sh
emconfigure ../configure --prefix=$INSTALLDIR \
       --cc=emcc \
       --disable-shared \
       --enable-runtime-cpudetect \
       --enable-avresample \
       --disable-encoders \
       --disable-muxers \
       --disable-bzlib \
       --disable-demuxers \
       --enable-demuxer=au \
       --enable-demuxer=avi \
       --enable-demuxer=flac \
       --enable-demuxer=m4v \
       --enable-demuxer=matroska \
       --enable-demuxer=mov \
       --enable-demuxer=mp3 \
       --enable-demuxer=mpegps \
       --enable-demuxer=mpegts \
       --enable-demuxer=mpegtsraw \
       --enable-demuxer=mpegvideo \
       --enable-demuxer=ogg \
       --enable-demuxer=wav \
       --disable-decoders \
       --enable-decoder=flac \
       --enable-decoder=mp2 \
       --enable-decoder=mp3 \
       --enable-decoder=mp3on4 \
       --enable-decoder=mpeg1video \
       --enable-decoder=mpeg2video \
       --enable-decoder=mpegvideo \
       --enable-decoder=msmpeg4v1 \
       --enable-decoder=msmpeg4v2 \
       --enable-decoder=msmpeg4v3 \
       --enable-decoder=mpeg4 \
       --enable-decoder=pcm_dvd \
       --enable-decoder=pcm_s16be \
       --enable-decoder=pcm_s16le \
       --enable-decoder=pcm_s8 \
       --enable-decoder=pcm_u16be \
       --enable-decoder=pcm_u16le \
       --enable-decoder=pcm_u8 \
       --enable-decoder=theora \
       --enable-decoder=vorbis \
       --enable-decoder=opus \
       --enable-decoder=vp3 \
       --enable-decoder=vp8 \
       --enable-decoder=vp9 \
       --disable-parsers \
       --enable-parser=mpegaudio \
       --enable-parser=mpegvideo \
       --enable-parser=mpeg4video \
       --enable-parser=vp3 \
       --enable-parser=vp8 \
       --disable-protocols \
       --disable-devices \
       --disable-vdpau \
       --disable-vda \
       --disable-filters \
       --disable-bsfs \
       --disable-d3d11va \
       --disable-dxva2 \
       --disable-vaapi \
       --disable-vda \
       --disable-vdpau \
       --disable-videotoolbox \
       --disable-iconv \
       \
       --disable-programs \
       --disable-avdevice \
       --disable-postproc \
       --disable-avfilter \
       --disable-protocols \
       --disable-network \
       --arch=emscripten --disable-asm --disable-stripping --ar=emar --ranlib=emranlib \
       --host asmjs-unknown-none

# --enable-cross-compile: requests specifying target and host OS,
#   let's rely on emconfigure instead

emmake make -j$(nproc) V=1 || true
cp -p /bin/true doc/print_options
touch doc/print_options
emmake make -j$(nproc) V=1
emmake make install
