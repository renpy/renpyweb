#!/bin/bash -ex
# Repackage a Ren'Py game Distribution for Emscripten - DRAFT

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

tar xf *.tar.bz2
cd */
mv renpy/common .
rm -rf *.py *.sh README.html lib/ renpy/
mkdir renpy
mv common renpy/
(
    cd renpy/common
    find \! \( -name "*.rpyc" -o -name "*.rpymc" \) -print0 | xargs -r0 rm
    rmdir */
)
# Not for tutorial:
find -name "*.rpy" -print0 | xargs -r0 rm
# Only for our demos, to enable developer mode
# rm game/script_version.txt
# Only for the_question
# mkdir -p launcher/game/fonts/
# cp -a ../../launcher/game/fonts/NanumGothic.ttf ../../launcher/game/fonts/SourceHanSans-Light-Lite.ttf launcher/game/fonts/
zip -r ../game.zip *

# Note: Don't remove .py, in-game .pyo are not found as RenpyImporter doesn't check for them by default
#find game/ -name "*.py" -print0 | xargs -r0 python -OO -m py_compile
#find game/ -name "*.py" -print0 | xargs -r0 rm

# Note: not compiling .rpymc/.rpyc; instead, get them from a Ren'Py
# Distribution along with their renpy/common/*.rpymc which are
# referenced by cache/bytecode.rpyb (long to recompile on start-up)
# If changing our mind:
# (cd build/renpy/ && PYTHONHOME=$INSTALLDIR ./main game compile)
