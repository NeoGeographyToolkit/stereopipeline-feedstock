#!/bin/bash

set -e

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

mkdir build
cd build

# Recommended in https://gitter.im/conda-forge/conda-forge.github.io?at=5c40da7f95e17b45256960ce
find ${PREFIX}/lib -name '*.la' -delete

# if [ "$(uname)" = "Darwin" ]; then
#     cc_comp=clang
#     cxx_comp=clang++
# else
#     cc_comp=x86_64-conda-linux-gnu-gcc
#     cxx_comp=x86_64-conda-linux-gnu-c++
# fi

    # -DCMAKE_C_COMPILER=${PREFIX}/bin/$cc_comp    \
    # -DCMAKE_CXX_COMPILER=${PREFIX}/bin/$cxx_comp \

cmake ..                                         \
    -DCMAKE_PREFIX_PATH=${PREFIX}                \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}             \
    -DASP_DEPS_DIR=${PREFIX}                     \
    -DCMAKE_VERBOSE_MAKEFILE=ON

make -j${CPU_COUNT}
make install

