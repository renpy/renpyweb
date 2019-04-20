#!/bin/bash

set -ex

RENPYWEB="$(dirname $(readlink -f $0))/.."

cd "$RENPYWEB"

if [ ! -e pygame_sdl2 ] ; then
    git clone git@github.com:renpy/pygame_sdl2.git pygame_sdl2
    fi

if [ ! -e renpy ] ; then
    git clone git@github.com:renpy/renpy.git renpy
fi

