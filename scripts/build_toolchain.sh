#!/bin/bash

EMSCRIPTEN_VERSION=1.38.37
RENPYWEB="$(dirname $(readlink -f $0))/.."
TOOLCHAIN="$RENPYWEB/toolchain"

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

write_emconfig () {
    cat > ./emconfig <<EOT
import os

EMSCRIPTEN_ROOT = "${TOOLCHAIN}/emscripten"
LLVM_ROOT = "${TOOLCHAIN}/emscripten-fastcomp/build/bin/"
BINARYEN_ROOT = ""

# EMSCRIPTEN_NATIVE_OPTIMIZER='/path/to/custom/optimizer(.exe)'

NODE_JS = os.path.expanduser(os.getenv('NODE', '/usr/bin/nodejs')) # executable
SPIDERMONKEY_ENGINE = [os.path.expanduser(os.getenv('SPIDERMONKEY', 'js'))] # executable
V8_ENGINE = os.path.expanduser(os.getenv('V8', 'd8')) # executable

JAVA = 'java' # executable

TEMP_DIR = '/tmp'

COMPILER_ENGINE = NODE_JS
JS_ENGINES = [NODE_JS]
EOT
}

write_env () {
    cat > env.sh <<EOT
export PATH=${TOOLCHAIN}/emscripten:\$PATH
export EM_CONFIG=${TOOLCHAIN}/emconfig
export EM_PORTS=${TOOLCHAIN}/ports
export EM_CACHE=${TOOLCHAIN}/cache
EOT
}


main () {
    cd "$RENPYWEB"

    mkdir -p toolchain
    cd toolchain

    run_once clone_fastcomp
    run_once build_fastcomp

    run_once clone_emscripten
    run_once patch_emscripten

    mkdir -p ports
    mkdir -p cache

    write_emconfig
    write_env
}

main
