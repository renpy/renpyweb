#!/bin/bash
#
# Installs renpyweb into Ren'Py proper.

# Copyright 2019 Tom Rothamel

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

set -e


RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

if [ -e "renpy/web" ] ; then
    rm -Rf "renpy/web"
fi

mkdir renpy/web

for i in index.html index.js index.wasm pyapp.data pyapp-data.js pythonhome.data pythonhome-data.js renpyweb-version.txt js_cmd.js; do
    cp build/t/$i renpy/web/$i
done

cp htaccess.txt renpy/web/
