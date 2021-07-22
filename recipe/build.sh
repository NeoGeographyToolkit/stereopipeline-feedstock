#!/bin/bash

set -e

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

mkdir build
cd build

# Fix for missing liblzma.
perl -pi -e "s#(/[^\s]*?lib)/lib([^\s]+).la#-L\$1 -l\$2#g" ${PREFIX}/lib/*.la

# On the Mac use the local compiler.
# TODO(oalexan1): Figure out while the Mac conda
# compiler results in stereo_pprc hanging when
# doing threaded code.
if [ "$(uname)" = "Darwin" ]; then
    cmake ..                                        \
        -DCMAKE_PREFIX_PATH=${PREFIX}               \
        -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}       \
        -DASP_DEPS_DIR=${PREFIX}                    \
        -DCMAKE_VERBOSE_MAKEFILE=ON                 \
        -DCMAKE_C_COMPILER=/usr/bin/clang           \
        -DCMAKE_CXX_COMPILER=/usr/bin/clang++
else
    cmake ..                                        \
        -DCMAKE_PREFIX_PATH=${PREFIX}               \
        -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}       \
        -DASP_DEPS_DIR=${PREFIX}                    \
        -DCMAKE_VERBOSE_MAKEFILE=ON
fi

# This is likely not needed
#        -DCMAKE_EXE_LINKER_FLAGS="-L${PREFIX}/lib -Wl,-rpath-link,${PREFIX}/lib" \

make -j${CPU_COUNT}
make install


