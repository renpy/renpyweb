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
