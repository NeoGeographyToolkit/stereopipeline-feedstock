#!/bin/bash

set -e

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

mkdir build
cd build

# Fix for missing liblzma.
perl -pi -e "s#(/[^\s]*?lib)/lib([^\s]+).la#-L\$1 -l\$2#g" ${PREFIX}/lib/*.la

cmake ..                                        \
    -DCMAKE_PREFIX_PATH=${PREFIX}               \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}       \
    -DISIS_DEPS_DIR=${PREFIX}                   \
    -DBINARYBUILDER_INSTALL_DIR=${PREFIX}       \
    -DCMAKE_VERBOSE_MAKEFILE=ON                 \
    # -DVW_ENABLE_SSE=0 #  on pfe

make -j${CPU_COUNT}
make install


