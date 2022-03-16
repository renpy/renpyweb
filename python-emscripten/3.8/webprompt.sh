#!/bin/bash -ex

# Simple Python prompt for the browser, for smoke testing

# Copyright (C) 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

INSTALLDIR=${INSTALLDIR:-$(dirname $(readlink -f $0))/destdir}
BUILD=t

mkdir -p $BUILD

cython -3 ../emscripten.pyx -o $BUILD/emscripten.c
cython -3 ../emscripten_fetch.pyx -o $BUILD/emscripten_fetch.c
# utf_32_be: support Unicode characters e.g. u'é'
# __future__.py: for emscripten.pyx
# + some optional but common Python deps
PREFIX=$INSTALLDIR OUTDIR=$BUILD ./package-pythonhome.sh \
    encodings/utf_32_be.py __future__.py \
    struct.py operator.py datetime.py random.py functools.py types.py \
    collections/__init__.py collections/abc.py \
    pickle.py copyreg.py _compat_pickle.py keyword.py heapq.py reprlib.py \
    re.py sre_compile.py sre_parse.py sre_constants.py enum.py

FLAGS='-O3'
while (( $# )); do
    case "$1" in
	debug) FLAGS='-s ASSERTIONS=1 -g -s FETCH_DEBUG=1';;
	async) ASYNC='-s ASYNCIFY=1 -O3';;
    esac
    shift
done
emcc -o $BUILD/index.html \
  ../webprompt-main.c $BUILD/emscripten.c $BUILD/emscripten_fetch.c \
  $FLAGS \
  -I$INSTALLDIR/include/python3.8 -L$INSTALLDIR/lib -lpython3.8 \
  -s EMULATE_FUNCTION_POINTER_CASTS=1 \
  -s USE_ZLIB=1 \
  -s FETCH=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s FORCE_FILESYSTEM=1 -s RETAIN_COMPILER_SETTINGS=1 \
  $ASYNC \
  --shell-file ../webprompt-shell.html -s MINIFY_HTML=0 \
  -s EXPORTED_FUNCTIONS='[_main, _Py_Initialize, _PyRun_SimpleString, _pyruni]' \
  -s EXTRA_EXPORTED_RUNTIME_METHODS='[ccall, cwrap]'

# emrun --serve_after_close t/index.html

# cython -3 ../mock/emscripten.pyx -o t/mock.c
# cython -3 ../mock/emscripten_fetch.pyx -o t/mock2.c
# gcc -g -I build/hostpython/include/python3.8 -L build/hostpython/lib/ t/mock.c t/mock2.c ../webprompt-main.c -lpython3.8 -ldl -lm -lutil -lz -lpthread
# PYTHONHOME=build/hostpython/ ./a.out
