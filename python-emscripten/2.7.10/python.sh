#!/bin/bash -ex

# Compile minimal Python for Emscripten and native local testing

# Copyright (C) 2018, 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

VERSION=2.7.10  # for end-of-life Python2, support Ren'Py's version only
SCRIPTDIR=$(dirname $(readlink -f $0))
DESTDIR=${DESTDIR:-$SCRIPTDIR/destdir}
SETUPLOCAL=${SETUPLOCAL:-'/dev/null'}

CACHEROOT=$SCRIPTDIR
BUILD=$SCRIPTDIR/build
export QUILT_PATCHES=$(dirname $(readlink -f $0))/patches

WGET=${WGET:-wget}

unpack () {
    $WGET -c https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz -P $CACHEROOT/
    mkdir -p $BUILD
    cd $BUILD/
    rm -rf Python-$VERSION/
    tar xf $CACHEROOT/Python-$VERSION.tgz
    cd Python-$VERSION/
    quilt push -a
}

# use cases:
# - python/pgen/.pyo for emscripten() below
# - common basis for crosspython below
hostpython () {
    cd $BUILD/Python-$VERSION/
    mkdir -p native
    (
        cd native/
        if [ ! -e config.status ]; then
	    # --without-pymalloc: prevents segfault during 'make' (sysconfigdata)
            ../configure \
                --prefix='' \
                --without-pymalloc
        fi

        make -j$(nproc)
        make install DESTDIR=$BUILD/hostpython
    )

    # setuptools for 3rd-party module installers
    wget -c https://files.pythonhosted.org/packages/11/0a/7f13ef5cd932a107cd4c0f3ebc9d831d9b78e1a0e8c98a098ca17b1d7d97/setuptools-41.6.0.zip -P $CACHEROOT/
    cd $BUILD/hostpython/
    rm -rf setuptools-41.6.0/
    unzip $CACHEROOT/setuptools-41.6.0.zip
    cd setuptools-41.6.0/
    ../bin/python setup.py install
}

emscripten () {
    cd $BUILD/Python-$VERSION/
    mkdir -p emscripten
    (
        cd emscripten/
        # OPT=-Oz: TODO
        # CONFIG_SITE: deals with cross-compilation https://bugs.python.org/msg136962
        # not needed as emcc has a single arch: BASECFLAGS=-m32 LDFLAGS=-m32
        # PATH: detect our Python, beware of conflict with emcc's python3
        #       don't use PYTHON_FOR_BUILD which is high-level / lots of options
        # --without-threads: pthreads experimental as of 2020-05
        #   cf. https://emscripten.org/docs/porting/pthreads.html
        # --without-signal-module: no process signals in Emscripten
        # --without-pymalloc: ?
        # --disable-ipv6: browser-side networking
        # --disable-shared: compile statically for Emscripten perfs + incomplete PIC support
        if [ ! -e config.status ]; then
            CONFIG_SITE=../config.site \
                BASECFLAGS='-s USE_ZLIB=1' LDFLAGS='-s USE_ZLIB=1' \
                PATH=$BUILD/Python-$VERSION/native:$PATH \
                emconfigure ../configure \
                --host=asmjs-unknown-emscripten --build=$(../config.guess) \
                --prefix='' \
                --without-threads --without-pymalloc --without-signal-module --disable-ipv6 \
                --disable-shared
        fi

        # pgen native setup
        # note: need to build 'pgen' once before overwriting it with the native one
        # note: PGEN=../native/Parser/pgen doesn't work, make overwrites it
        emmake make Parser/pgen
        \cp --preserve=mode ../native/Parser/pgen Parser/

        # Modules/Setup.local
        echo '*static*' > Modules/Setup.local
        cat $SETUPLOCAL >> Modules/Setup.local
        # drop -I/-L/-lz, we USE_ZLIB=1 (keep it in SETUPLOCAL for mock)
        sed -i -e 's/^\(zlib zlibmodule.c\).*/\1/' Modules/Setup.local
        emmake make Makefile
    
        (
            export PATH=$BUILD/Python-$VERSION/native:$PATH
            emmake make -j$(nproc)
            # setup.py install_lib doesn't respect DESTDIR
            echo -e 'sharedinstall:\n\ttrue' >> Makefile
            # decrease .pyo size by dropping docstrings
            sed -i -e '/compileall.py/ s/ -O / -OO /' Makefile
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
    # lib/python2.7/_sysconfigdata.py
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
	    rm lib/python2.7
	    mkdir lib/python2.7
	    for i in $(cd ../build/hostpython/lib/python2.7 && ls -A); do
		ln -s ../../../build/hostpython/lib/python2.7/$i lib/python2.7/$i
	    done
	    
	    # Use Python.h configured for WASM
	    ln -s $DESTDIR/include include
	    
	    # Use compiler settings configured for WASM
	    rm lib/python2.7/_sysconfigdata.*
	    cp -a $DESTDIR/lib/python2.7/_sysconfigdata.* lib/python2.7/
	)
    done
    # 'CCSHARED': 'xxx',
    sed -i -e "s/'CCSHARED': .*/'CCSHARED': '-fPIC -s SIDE_MODULE=1',/" \
	crosspython-dynamic/lib/python2.7/_sysconfigdata.py
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
