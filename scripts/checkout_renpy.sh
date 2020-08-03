#!/bin/bash

set -ex

RENPYWEB="$(dirname $(readlink -f $0))/.."

cd "$RENPYWEB"

if [ ! -e pygame_sdl2 ] ; then
    git clone git@github.com:renpy/pygame_sdl2.git pygame_sdl2
    pushd pygame_sdl2
    git checkout renpy-7.3.5.606
    popd
fi

if [ ! -e renpy ] ; then
    git clone https://github.com/Beuc/renpy -b red-7.3.5 renpy
else
    pushd renpy
    git checkout red-7.3.5
    git pull
    popd
fi
