#!/bin/bash -ex
# Cross-compile ffmpeg for Emscripten

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
tar xf $CACHEROOT/ffmpeg-4.3.1.tar.bz2
cd ffmpeg-4.3.1/

mkdir -p build
cd build/

export CFLAGS="-fno-common"
export CXXFLAGS="-fno-common"

# Configure flags from renpy-build/tasks/ffmpeg.py

# Disable video codes avi, m4v, matroska, mov, mpegps, mpegts,
#   mpegtsraw, mpegvideo, mp2, mp3on4, mpeg1video, mpeg2video,
#   mpegvideo, msmpeg4v1, msmpeg4v2, msmpeg4v3, mpeg4, pcm_dvd,
#   theora, vp3, vp8, vp9, mpeg4video

# Disable shared and pthreads

emconfigure ../configure --prefix=$INSTALLDIR \
        --cc=emcc \
        --disable-shared \
        --disable-pthreads \
        \
        --enable-cross-compile \
        --enable-runtime-cpudetect \
        \
        --disable-all \
        --disable-everything \
        \
        --enable-ffmpeg \
        --enable-ffplay \
        --disable-doc \
        --enable-avcodec \
        --enable-avformat \
        --enable-swresample \
        --enable-swscale \
        --enable-avfilter \
        --enable-avresample \
        \
        --disable-bzlib \
        \
        --enable-demuxer=au \
        --disable-demuxer=avi \
        --enable-demuxer=flac \
        --disable-demuxer=m4v \
        --disable-demuxer=matroska \
        --disable-demuxer=mov \
        --enable-demuxer=mp3 \
        --disable-demuxer=mpegps \
        --disable-demuxer=mpegts \
        --disable-demuxer=mpegtsraw \
        --disable-demuxer=mpegvideo \
        --enable-demuxer=ogg \
        --enable-demuxer=wav \
        \
        --enable-decoder=flac \
        --disable-decoder=mp2 \
        --enable-decoder=mp3 \
        --disable-decoder=mp3on4 \
        --disable-decoder=mpeg1video \
        --disable-decoder=mpeg2video \
        --disable-decoder=mpegvideo \
        --disable-decoder=msmpeg4v1 \
        --disable-decoder=msmpeg4v2 \
        --disable-decoder=msmpeg4v3 \
        --disable-decoder=mpeg4 \
        --disable-decoder=pcm_dvd \
        --enable-decoder=pcm_s16be \
        --enable-decoder=pcm_s16le \
        --enable-decoder=pcm_s8 \
        --enable-decoder=pcm_u16be \
        --enable-decoder=pcm_u16le \
        --enable-decoder=pcm_u8 \
        --disable-decoder=theora \
        --enable-decoder=vorbis \
        --enable-decoder=opus \
        --disable-decoder=vp3 \
        --disable-decoder=vp8 \
        --disable-decoder=vp9 \
        \
        --enable-parser=mpegaudio \
        --disable-parser=mpegvideo \
        --disable-parser=mpeg4video \
        --disable-parser=vp3 \
        --disable-parser=vp8 \
        --disable-parser=vp9 \
        \
        --disable-iconv \
        --disable-alsa \
        --disable-libxcb \
        --disable-lzma \
        --disable-sndio \
        --disable-xlib \
        \
        \
        --disable-amf \
        --disable-audiotoolbox \
        --disable-cuda-llvm \
        --disable-d3d11va \
        --disable-dxva2 \
        --disable-ffnvcodec \
        --disable-nvdec \
        --disable-nvenc \
        --disable-v4l2-m2m \
        --disable-vaapi \
        --disable-vdpau \
        --disable-videotoolbox \
        \
       --arch=emscripten --disable-asm --disable-stripping --ar=emar --ranlib=emranlib
# --enable-cross-compile: requests specifying target and host OS,
#   let's rely on emconfigure instead

emmake make -j$(nproc) V=1 || true
cp -p /bin/true doc/print_options
touch doc/print_options
emmake make -j$(nproc) V=1
emmake make install
