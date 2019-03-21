#!/bin/bash

EMSCRIPTEN_VERSION=1.38.28
RENPYWEB=$(dirname $(readlink -f $0))

set -e

# This runs a command once, creating a
run_once () {
    if [ ! -e ".built.$1" ] ; then
        $1
        touch ".built.$1"
    fi
}


clone_fastcomp () {
    git clone https://github.com/emscripten-core/emscripten-fastcomp
    pushd emscripten-fastcomp
    git checkout $EMSCRIPTEN_VERSION
    git clone https://github.com/emscripten-core/emscripten-fastcomp-clang tools/clang
    pushd tools/clang
    git checkout $EMSCRIPTEN_VERSION
    popd
    popd
}

build_fastcomp () {
    pushd emscripten-fastcomp

    mkdir -p build
    pushd build

    cmake .. -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="host;JSBackend" -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DCLANG_INCLUDE_TESTS=OFF
    make -j4

    popd
    popd

}

clone_emscripten () {
    git clone https://github.com/emscripten-core/emscripten.git
    pushd emscripten

    git checkout $EMSCRIPTEN_VERSION

    popd
}

patch_emscripten () {

    pushd emscripten
    patch -p1 < "$RENPYWEB/patches/emscripten.patch"
    popd

}


main () {
    cd "$RENPYWEB"

    mkdir -p toolchain
    cd toolchain

    run_once clone_fastcomp
    run_once build_fastcomp

    run_once clone_emscripten
    run_once patch_emscripten
}

main
