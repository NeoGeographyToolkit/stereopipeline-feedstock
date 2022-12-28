#!/bin/bash

set -e

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

mkdir build
cd build

# Recommended in https://gitter.im/conda-forge/conda-forge.github.io?at=5c40da7f95e17b45256960ce
find ${PREFIX}/lib -name '*.la' -delete

cmake ..                             \
    -DCMAKE_PREFIX_PATH=${PREFIX}    \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DASP_DEPS_DIR=${PREFIX}         \
    -DCMAKE_VERBOSE_MAKEFILE=ON

make -j${CPU_COUNT}
make install

