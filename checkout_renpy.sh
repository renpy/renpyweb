#!/bin/bash

set -ex

RENPYWEB="$(dirname $(readlink -f $0))"
BRANCH=${1:-web}

cd "$RENPYWEB"

if [ ! -e pygame_sdl2 ] ; then
    git clone git@github.com:renpy/pygame_sdl2.git pygame_sdl2
    fi

if [ ! -e renpy ] ; then
    git clone git@github.com:renpy/renpy.git renpy
fi

pushd pygame_sdl2
git checkout $BRANCH
popd

pushd renpy
git checkout $BRANCH
popd
