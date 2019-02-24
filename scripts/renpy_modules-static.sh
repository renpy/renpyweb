#!/bin/bash -ex
# Cross-compile RenPy Cython modules for Emscripten, as static modules

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

# Compile statically so we can use 'emcc -s EMTERPRETER_ASYNC' in the main program

# Cf. https://mdqinc.com/blog/2011/08/statically-linking-python-with-cython-generated-modules-and-packages/
# + patches for setuplib.py

CACHEROOT=$(dirname $(readlink -f $0))/../cache
BUILD=$(dirname $(readlink -f $0))/../build
INSTALLDIR=$(dirname $(readlink -f $0))/../install
PATCHESDIR=$(dirname $(readlink -f $0))/../patches
HOSTPYTHON=$(dirname $(readlink -f $0))/../python-emscripten/2.7.10/build/hostpython/bin/python

RENPY_MODULES_ROOT=$BUILD/renpy
if [ ! -d "$RENPY_MODULES_ROOT/.git" ]; then
    git clone https://github.com/renpy/renpy $RENPY_MODULES_ROOT
    #(cd "$RENPY_MODULES_ROOT" && git checkout 7.1.1.929)
    #f2376c02e80de963bb47ac9975cdda835c6b083  # 7.1.3
    (cd "$RENPY_MODULES_ROOT" && git checkout 88722c18dc87a6b6a14369d2cef861ce0315d525) # 7.1.4pre2
    (cd "$RENPY_MODULES_ROOT" && git checkout 2eea4a442c9f40cbc87c5f5e86b7933a55bd2ea6) # 7.1.4pre20190224
    #generate vc_version.py
    python -O distribute.py || true
else
    : #(cd "$RENPY_MODULES_ROOT" && git pull)
fi

(
    cd $RENPY_MODULES_ROOT/
    if [ ! -e .patched ]; then
       patch -p1 < $PATCHESDIR/renpy_TOSPLIT-7.1.4.0.patch
       touch .patched
    fi
    if [ ! -e .pc ]; then
	QUILT_PATCHES=$PATCHESDIR/renpy quilt push -a
    fi
    cd module/
    export RENPY_DEPS_INSTALL="$INSTALLDIR"  # doesn't work for emscripten ports, no '*.a'
    CC=emcc LDSHARED=emcc CFLAGS="-I$INSTALLDIR/include -s USE_SDL=2 -s USE_FREETYPE=1" \
      RENPY_EMSCRIPTEN=1 \
      $HOSTPYTHON \
        setup.py \
          build_ext --include-dirs $INSTALLDIR/include/python2.7 \
            -b emscripten-static/build-lib -t emscripten-static/build-temp \
          build \
          install -O2 --prefix $INSTALLDIR

    rm -f $INSTALLDIR/lib/python2.7/site-packages/_renpy*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*.so
    rm -f $INSTALLDIR/lib/python2.7/site-packages/renpy/*/*.so
)

exit 0

# native

python setup.py build_ext -b native-static/build-lib -t native-static/build-temp
