#!/bin/bash -e

# Packages pygame-example files (for use in Emscripten MEMFS)

# Copyright (C) 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.


FILE_PACKAGER="python3 $(dirname $(which emcc))/tools/file_packager.py"
PACKAGEDIR=build/package-pyapp-pygame-example
OUTDIR=build/t
HOSTPYTHON=$(dirname $(readlink -f $0))/../python-emscripten/$PY3VER/build/hostpython/bin/python3

rm -rf $PACKAGEDIR/
mkdir -p $PACKAGEDIR

# pygame_sdl2-static
mkdir -p $PACKAGEDIR/lib/python3.8/site-packages/pygame_sdl2/threads
#for i in $(cd install && find lib/python3.8/site-packages/pygame_sdl2/ -name "*.pyo"); do
for i in $(cd install && find lib/python3.8/site-packages/pygame_sdl2/ -name "*.py"); do
   cp -a install/$i $PACKAGEDIR/$i
done

# Stub out threading
mkdir -p $PACKAGEDIR/lib/python3.8
cp -a patches/pystub/threading.py  $PACKAGEDIR/lib/python3.8

# Compile manually added Python scripts
#find $PACKAGEDIR/ -name "*.py" -print0 | xargs -r0 $HOSTPYTHON -OO -m py_compile
#find $PACKAGEDIR/ -name "*.py" -print0 | xargs -r0 rm

# Copy game data and remove source files
cp -a pygame-example/* $PACKAGEDIR/

# TODO: py3 precompile
# Compile Python scripts
#for i in $(cd pygame-example/ && find . -name "*.py"); do
#    if [ pygame-example/$i -nt pygame-example/${i%.py}.pyo ]; then
#	$HOSTPYTHON -OO -m py_compile pygame-example/$i
#    fi
#done
#
#find $PACKAGEDIR/ \( -name "*.py" -o -name "*.pyc" \
#    -o -name "*.pyx" -o -name "*.pxd" \
#    -o -name "*.rpy" -o -name "*.rpym" \) -print0 \
#  | xargs -r0 rm

# Entry point
# TODO: Python doesn't like .pyo entry points?
cp -aL pygame-example/main.py $PACKAGEDIR/main.py

$FILE_PACKAGER \
    $OUTDIR/pyapp.data --js-output=$OUTDIR/pyapp-data.js \
    --preload $PACKAGEDIR@/ \
    --use-preload-cache --no-heap-copy --lz4
