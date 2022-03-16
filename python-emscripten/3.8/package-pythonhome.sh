#!/bin/bash -e

# Creates a minimal Python file hierarchy at $PACKAGEDIR

# Copyright (C) 2018, 2019, 2020  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

FILE_PACKAGER="python3 $(dirname $(which emcc))/tools/file_packager.py"

PREFIX=${PREFIX:-$(dirname $(readlink -f $0))/destdir}
PACKAGEDIR=${PACKAGEDIR:-$(dirname $(readlink -f $0))/package}
OUTDIR=${OUTDIR:-.}
CROSSPYTHON=$(dirname $(readlink -f $0))/crosspython-static/bin/python3

# Python home

# optional lz4 compression, requires '-s LZ4=1'
LZ4=
if [ "$1" == "--lz4" ]; then LZ4="--lz4"; shift; fi

rm -rf $PACKAGEDIR/
mkdir -p $PACKAGEDIR

# Hard-coded modules: for 'print("hello, world.")'
# $@: additional, app-specific modules
(cd $PREFIX/lib/python3.8/ && $CROSSPYTHON -OO -m compileall .) >/dev/null || true
for i in site.py os.py stat.py posixpath.py genericpath.py abc.py encodings/__init__.py codecs.py encodings/aliases.py encodings/utf_8.py io.py _collections_abc.py _sitebuiltins.py encodings/ascii.py encodings/latin_1.py \
    "$@"; do
    mkdir -p $PACKAGEDIR/lib/python3.8/$(dirname $i)/__pycache__
    # Install to legacy .pyc location for size-efficient source-less distribution
    cp -au $PREFIX/lib/python3.8/$(dirname $i)/__pycache__/$(basename ${i%.py}.cpython-38.opt-2.pyc) \
       $PACKAGEDIR/lib/python3.8/${i%.py}.pyc
done
# Large and leaks build paths, clean it:
#echo 'build_time_vars = {}' > $PACKAGEDIR/lib/python3.8/lib-dynload/_sysconfigdata__linux_x86_64-linux-gnu.py
#(cd $PACKAGEDIR && $CROSSPYTHON -OO -m py_compile lib/python3.8/_sysconfigdata.py)
#rm -f $PACKAGEDIR/lib/python3.8/_sysconfigdata.py

# --no-heap-copy: suited for ALLOW_MEMORY_GROWTH=1
PACKAGEDIR_FULLPATH=$(readlink -f $PACKAGEDIR)
(
    cd $OUTDIR;  # use relative path in xxx-data.js
    $FILE_PACKAGER \
	pythonhome.data --js-output=pythonhome-data.js \
	--preload $PACKAGEDIR_FULLPATH@/ \
	--use-preload-cache --no-heap-copy $LZ4
)
