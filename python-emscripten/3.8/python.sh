#!/bin/bash -ex

# Compile minimal Python for Emscripten and native local testing

# Copyright (C) 2018, 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

VERSION=3.8.3
SCRIPTDIR=$(dirname $(readlink -f $0))
DESTDIR=${DESTDIR:-$SCRIPTDIR/destdir}
SETUPLOCAL=${SETUPLOCAL:-'/dev/null'}

CACHEROOT=$SCRIPTDIR
BUILD=$SCRIPTDIR/build
export QUILT_PATCHES=$(dirname $(readlink -f $0))/patches

WGET=${WGET:-wget}

unpack () {
    $WGET -c https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz -P $CACHEROOT/
    mkdir -p $BUILD
    cd $BUILD/
    rm -rf Python-$VERSION/
    tar xf $CACHEROOT/Python-$VERSION.tar.xz
    cd Python-$VERSION/
    quilt push -a
}

# use cases:
# - python/.pyo for emscripten() below
# - common basis for crosspython below
hostpython () {
    cd $BUILD/Python-$VERSION/
    mkdir -p native
    (
        cd native/
        if [ ! -e config.status ]; then
            ../configure \
                --prefix=''
        fi

        make -j$(nproc)
        rm -rf $BUILD/hostpython
        make install DESTDIR=$BUILD/hostpython
    )
}

emscripten () {
    cd $BUILD/Python-$VERSION/
    mkdir -p emscripten
    (
        cd emscripten/
        # OPT=-Oz: TODO
        # CONFIG_SITE: deals with cross-compilation https://bugs.python.org/msg136962
        # PATH: detect our Python, beware of conflict with emcc's python3
        #       don't use PYTHON_FOR_BUILD which is high-level / lots of options
        # --without-pymalloc: ?
        # --disable-ipv6: ?
        # --disable-shared: compile statically for Emscripten perfs + incomplete PIC support
        if [ ! -e config.status ]; then
            CONFIG_SITE=../config-emscripten.site READELF=true \
		BASECFLAGS='-s USE_ZLIB=1' LDFLAGS='-s USE_ZLIB=1' \
                PATH=$BUILD/Python-$VERSION/native:$PATH \
                emconfigure ../configure \
                --host=asmjs-unknown-emscripten --build=$(../config.guess) \
                --prefix='' \
                --without-pymalloc --disable-ipv6 \
                --disable-shared
        fi
	cat <<EOF >> pyconfig.h
/* issues with posixmodule.c */
#undef HAVE_POSIX_SPAWN
#undef HAVE_POSIX_SPAWNP
/* issues with signalmodule.c */
#undef HAVE_PTHREAD_SIGMASK
EOF

        # Modules/Setup.local
        echo '*static*' > Modules/Setup.local
        cat $SETUPLOCAL >> Modules/Setup.local
        # drop -I/-L/-lz, we USE_ZLIB=1 (keep it in SETUPLOCAL for mock)
        sed -i -e 's/^\(zlib zlibmodule.c\).*/\1/' Modules/Setup.local
        emmake make Makefile
        # decrease .pyo size by dropping docstrings
        sed -i -e '/compileall.py/ s/ -O / -OO /' Makefile

        (
            export PATH=$BUILD/Python-$VERSION/native:$PATH
            # Trigger setup.py:CROSS_COMPILING (introduced in 3.8)
            export _PYTHON_HOST_PLATFORM=emscripten
            emmake make -j$(nproc)
            emmake make install DESTDIR=$DESTDIR
        )

        # Basic trimming
        # Disabled for now, better cherry-pick the files we need
        #emmake make install DESTDIR=$(pwd)/destdir
        #find destdir/ -name "*.py" -print0 | xargs -r0 rm
        #find destdir/ -name "*.pyo" -print0 | xargs -r0 rm  # only keep .pyc, .pyo apparently don't work
        #find destdir/ -name "*.so" -print0 | xargs -r0 rm
        #rm -rf destdir/usr/local/bin/
        #rm -rf destdir/usr/local/share/man/
        #rm -rf destdir/usr/local/include/
        #rm -rf destdir/usr/local/lib/*.a
        #rm -rf destdir/usr/local/lib/pkgconfig/
        #rm -rf destdir/usr/local/lib/python2.7/test/
        # Ditch .so for now, they cause an abort() with dynamic
        # linking unless we recompile all of them as SIDE_MODULE-s
        #rm -rf $DESTDIR/lib/python2.7/lib-dynload/
    )
}

# For mock-ing emscripten environment through static desktop python
mock () {
    cd $BUILD/Python-$VERSION/
    mkdir -p native
    (
        cd native/
        if [ ! -e config.status ]; then
            ../configure \
                --prefix=$BUILD/hostpython/ \
                --without-threads --without-pymalloc --without-signal-module --disable-ipv6 \
                --disable-shared
        fi
        echo '*static*' > Modules/Setup.local
        cat $SETUPLOCAL >> Modules/Setup.local

        make -j$(nproc) Parser/pgen python
    
        make -j$(nproc)
        DESTDIR= make install
    )
}

# python aimed at compiling third-party Python modules to WASM
# - building static/dynamic wasm modules
# - compiling .pyo files, in emscripten() and package-xxx.sh
# Uses hostpython; detects its PYTHONHOME through ../lib AFAICS, no need to recompile
# Usage:
# .../crosspython-static/bin/python  setup.py xxx --root=.../destdir/ --prefix=''
# .../crosspython-dynamic/bin/python setup.py xxx --root=.../destdir/ --prefix=''
# .../crosspython-static/bin/python -OO -m py_compile xxx.py
# Note: maybe create and patch two virtualenv instead?  but harder to
#   use with dual static/dynamic Makefile; doesn't handle root=destdir
crosspython () {
    cd $SCRIPTDIR
    # Copy-link hostpython except for include/ and
    # lib/python3.8/_sysconfigdata.py
    for variant in static dynamic; do
	rm -rf crosspython-$variant
	mkdir crosspython-$variant
	(
	    cd crosspython-$variant
	    for i in $(cd ../build/hostpython && ls -A); do
		ln -s ../build/hostpython/$i $i
	    done
	    rm include lib
	    mkdir lib
	    for i in $(cd ../build/hostpython/lib && ls -A); do
		ln -s ../../build/hostpython/lib/$i lib/$i
	    done
	    rm lib/python3.8
	    mkdir lib/python3.8
	    for i in $(cd ../build/hostpython/lib/python3.8 && ls -A); do
		ln -s ../../../build/hostpython/lib/python3.8/$i lib/python3.8/$i
	    done
	    
	    # Use Python.h configured for WASM
	    ln -s $DESTDIR/include include
	    
	    # Use compiler settings configured for WASM
	    cp -a $DESTDIR/lib/python3.8/_sysconfigdata__emscripten_.py \
	       lib/python3.8/_sysconfigdata_*.py
	)
    done
    # 'CCSHARED': 'xxx',
    sed -i -e "s/'CCSHARED': .*/'CCSHARED': '-fPIC -s SIDE_MODULE=1',/" \
       crosspython-dynamic/lib/python3.8/_sysconfigdata_*.py
}

case "$1" in
    unpack|hostpython|emscripten|mock|crosspython)
        "$1"
        ;;
    '')
        unpack
        hostpython
        emscripten
        crosspython
        ;;
    *)
        echo "Usage: $0 unpack|hostpython|emscripten|mock|crosspython"
        exit 1
        ;;
esac
