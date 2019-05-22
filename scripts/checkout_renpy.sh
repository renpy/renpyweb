#!/bin/bash

set -ex

RENPYWEB="$(dirname $(readlink -f $0))/.."

cd "$RENPYWEB"

if [ ! -e pygame_sdl2 ] ; then
    git clone git@github.com:renpy/pygame_sdl2.git pygame_sdl2
    pushd pygame_sdl2
    git checkout master
    git pull
    popd
fi

if [ ! -e renpy ] ; then
    git clone git@github.com:renpy/renpy.git renpy
else
    pushd renpy
    git checkout master
    git pull
    popd
fi
