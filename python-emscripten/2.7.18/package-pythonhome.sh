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
CROSSPYTHON=$(dirname $(readlink -f $0))/crosspython-static/bin/python

# Python home

# optional lz4 compression, requires '-s LZ4=1'
LZ4=
if [ "$1" == "--lz4" ]; then LZ4="--lz4"; shift; fi

rm -rf $PACKAGEDIR/
mkdir -p $PACKAGEDIR

# Hard-coded modules: for 'print("hello, world.")'
# $@: additional, app-specific modules
for i in site.py os.py posixpath.py stat.py genericpath.py warnings.py linecache.py types.py UserDict.py _abcoll.py abc.py _weakrefset.py copy_reg.py traceback.py sysconfig.py re.py sre_compile.py sre_parse.py sre_constants.py encodings/__init__.py codecs.py encodings/aliases.py encodings/utf_8.py __future__.py ast.py copy.py weakref.py platform.py string.py io.py tempfile.py random.py hashlib.py struct.py dummy_thread.py collections.py keyword.py heapq.py argparse.py textwrap.py gettext.py locale.py functools.py importlib/__init__.py glob.py fnmatch.py pickle.py colorsys.py contextlib.py zipfile.py shutil.py json/__init__.py json/decoder.py json/scanner.py encodings/hex_codec.py json/encoder.py difflib.py inspect.py dis.py opcode.py tokenize.py token.py xml/__init__.py xml/etree/__init__.py xml/etree/ElementTree.py xml/etree/ElementPath.py encodings/zlib_codec.py tarfile.py urlparse.py StringIO.py encodings/latin_1.py encodings/ascii.py \
    "$@"; do
    if [ $PREFIX/lib/python2.7/$i -nt $PREFIX/lib/python2.7/${i%.py}.pyo ]; then
	(cd $PREFIX && $CROSSPYTHON -OO -m py_compile lib/python2.7/$i)
    fi
    mkdir -p $PACKAGEDIR/lib/python2.7/$(dirname $i)
    cp -au $PREFIX/lib/python2.7/${i%.py}.pyo $PACKAGEDIR/lib/python2.7/${i%.py}.pyo
done
# Large and leaks build paths, clean it:
echo 'build_time_vars = {}' > $PACKAGEDIR/lib/python2.7/_sysconfigdata.py
(cd $PACKAGEDIR && $CROSSPYTHON -OO -m py_compile lib/python2.7/_sysconfigdata.py)
rm -f $PACKAGEDIR/lib/python2.7/_sysconfigdata.py

# --no-heap-copy: suited for ALLOW_MEMORY_GROWTH=1
PACKAGEDIR_FULLPATH=$(readlink -f $PACKAGEDIR)
(
    cd $OUTDIR;  # use relative path in xxx-data.js
    $FILE_PACKAGER \
	pythonhome.data --js-output=pythonhome-data.js \
	--preload $PACKAGEDIR_FULLPATH@/ \
	--use-preload-cache --no-heap-copy $LZ4
)
