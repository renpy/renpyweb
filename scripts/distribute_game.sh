#!/bin/bash

set -e

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

renpy/renpy.sh renpy/launcher distribute --package web --packagedest build/t/game ${1:-renpy/the_question}
