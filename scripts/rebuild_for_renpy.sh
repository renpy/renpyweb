#!/bin/bash

set -e

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

. toolchain/env.sh

rm -Rf build/t
rm -f build/renpy.built
rm -f build/pygame_sdl2-static.built
nice make wasm

scripts/install_in_renpy.sh
