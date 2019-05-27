#!/bin/bash

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

rm -Rf build/ cache/ install/ python-emscripten/ python-emscripten.fossil toolchain
rm -Rf pygame_sdl2/emscripten-static/ renpy/module/emscripten-static/
