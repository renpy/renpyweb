#!/bin/bash -e

# Packages Ren'Py files (for use in Emscripten MEMFS)

# Copyright (C) 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Goals:
# - Provide size-optimized Ren'Py
# - Provide RenPyWeb-patched Ren'Py (C modules in index.wasm though)

# Most Ren'Py specific files are now in the game.zip that's created
# by Ren'Py, so this only contains pygame_sdl2 and some overrides
# to python files that are needed for Ren'Py to run.

FILE_PACKAGER="python3 $(dirname $(which emcc))/tools/file_packager.py"
PACKAGEDIR=build/package-pyapp-renpy
OUTDIR=build/t
HOSTPYTHON=$(dirname $(readlink -f $0))/../python-emscripten/$PY2VER/build/hostpython/bin/python

rm -rf $PACKAGEDIR/
mkdir -p $PACKAGEDIR

# Ren'Py dependencies from pip.
mkdir -p $PACKAGEDIR
$HOSTPYTHON -m pip install --target $PACKAGEDIR future==0.18.2 six==1.12.0 typing ecdsa==0.18.0

# pygame_sdl2-static
mkdir -p $PACKAGEDIR/lib/python2.7/site-packages/pygame_sdl2/threads
for i in $(cd install && find lib/python2.7/site-packages/pygame_sdl2/ -name "*.pyo"); do
   cp -a install/$i $PACKAGEDIR/$i
done

# Stub out these two libs.
mkdir -p $PACKAGEDIR/lib/python2.7
cp -a patches/pystub/*.py  $PACKAGEDIR/lib/python2.7

# Compile manually added Python scripts
(cd $PACKAGEDIR/ && find -name "*.py" -print0 | xargs -r0 $HOSTPYTHON -OO -m py_compile)

find $PACKAGEDIR/ -name "*.py" -print0 | xargs -r0 rm
find $PACKAGEDIR/ -name "*.pyc" -print0 | xargs -r0 rm

# RenPyWeb-specific files
cp -a web-presplash-default.jpg $PACKAGEDIR/

PACKAGEDIR_FULLPATH=$(readlink -f $PACKAGEDIR)
(
    cd $OUTDIR;  # use relative path in xxx-data.js
    $FILE_PACKAGER \
	pyapp.data --js-output=pyapp-data.js \
	--preload $PACKAGEDIR_FULLPATH@/ \
	--use-preload-cache --no-heap-copy
    # No --lz4 because this implies read-only, hence can't be overwritten
    # by game.zip.
    # https://github.com/emscripten-core/emscripten/issues/8450
)
