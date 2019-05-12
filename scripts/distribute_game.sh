#!/bin/bash

# This will run Ren'Py to compile and distribute the game. It takes an
# optional argument, a path to a Ren'Py game's base directory.

set -e

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

renpy/renpy.sh renpy/launcher distribute --package web --packagedest build/t/game ${1:-renpy/the_question}
