#!/bin/bash

# For use in the Ren'Py auto-build process.  Rebuilds Ren'Py and
# pygame_sdl2, then does a WASM build and an install.

set -e

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

. emsdk/emsdk_env.sh

rm -Rf build/t
make cythonclean
nice make

scripts/install_in_renpy.sh
