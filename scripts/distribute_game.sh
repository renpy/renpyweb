#!/bin/bash

# This will run Ren'Py to compile and distribute the game. It takes an
# optional argument, a path to a Ren'Py game's base directory.

set -e

RENPYWEB="$(dirname $(readlink -f $0))/.."
cd "$RENPYWEB"

# If renpy/lib is not present, use the nightly build's SDK.
if [ ! -e renpy/lib ] ; then
    pushd renpy
    curl -o renpy-nightly-sdk.tar.bz2 https://nightly.renpy.org/renpy-nightly-sdk.tar.bz2
    tar xaf renpy-nightly-sdk.tar.bz2
    mv renpy-*-sdk/lib .
    rm -Rf renpy-*-sdk
    rm renpy-nightly-sdk.tar.bz2
    popd
fi

# TODO: this doesn't support progressive download, only the stage1 game.zip
renpy/renpy.sh renpy/launcher distribute --package web --packagedest build/t/game ${1:-renpy/the_question}
