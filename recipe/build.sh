#!/bin/bash

# These can be turned on when building each package by hand. This is recommended
# before building with conda, while using the same dependencies, to ensure
# no issues later.
# export SRC_DIR=$HOME/projects # temporary
# export PREFIX=$CONDA_PREFIX # temporary

# It is much less time-consuming to build these in one script, than to have
# individual conda packages for them. It takes an outrageous amount of time to
# build with conda, and it often fails because of dependency or other issues.
# Hence do it this way.

# ISIS 9.0.0 did not ship PDAL. The existing versions in conda are not
# compatible with this ISIS version. So have to build PDAL as well.
cd $SRC_DIR
git clone git@github.com:PDAL/PDAL.git
# TODO(oalexan1): Must use https
cd PDAL
git checkout 2.9.3
mkdir -p build
cd build
if [ "$(uname)" = "Darwin" ]; then
    EXT='.dylib'
else
    EXT='.so'
fi
ldflags="-Wl,-rpath,${PREFIX}/lib -L${PREFIX}/lib -lgeotiff -lcurl -lssl -lxml2 -lcrypto -lzstd -lz -lunwind"
cmake ${CMAKE_ARGS}                                      \
  -DBUILD_SHARED_LIBS=ON                                 \
  -DCMAKE_BUILD_TYPE=Release                             \
  -DCMAKE_INSTALL_PREFIX=$PREFIX                         \
  -DCMAKE_PREFIX_PATH=$PREFIX                            \
  -DBUILD_PLUGIN_I3S=OFF                                 \
  -DBUILD_PLUGIN_TRAJECTORY=OFF                          \
  -DBUILD_PLUGIN_E57=OFF                                 \
  -DBUILD_PLUGIN_PGPOINTCLOUD=OFF                        \
  -DBUILD_PLUGIN_ICEBRIDGE=OFF                           \
  -DBUILD_PLUGIN_NITF=OFF                                \
  -DBUILD_PLUGIN_TILEDB=OFF                              \
  -DBUILD_PLUGIN_HDF=OFF                                 \
  -DBUILD_PLUGIN_DRACO=OFF                               \
  -DENABLE_CTEST=OFF                                     \
  -DWITH_TESTS=OFF                                       \
  -DWITH_ZLIB=ON                                         \
  -DWITH_ZSTD=ON                                         \
  -DWITH_LASZIP=ON                                       \
  -DWITH_LAZPERF=ON                                      \
  -DCMAKE_VERBOSE_MAKEFILE=ON                            \
  -DCMAKE_CXX17_STANDARD_COMPILE_OPTION="-std=c++17"     \
  -DCMAKE_VERBOSE_MAKEFILE=ON                            \
  -DWITH_TESTS=OFF                                       \
  -DCMAKE_EXE_LINKER_FLAGS="$ldflags"                    \
  -DDIMBUILDER_EXECUTABLE=dimbuilder                     \
  -DBUILD_PLUGIN_DRACO:BOOL=OFF                          \
  -DOPENSSL_ROOT_DIR=${PREFIX}                           \
  -DLIBXML2_INCLUDE_DIR=${PREFIX}/include/libxml2        \
  -DLIBXML2_LIBRARIES=${PREFIX}/lib/libxml2${EXT}        \
  -DLIBXML2_XMLLINT_EXECUTABLE=${PREFIX}/bin/xmllint     \
  -DGDAL_LIBRARY=${PREFIX}/lib/libgdal${EXT}             \
  -DGDAL_CONFIG=${PREFIX}/bin/gdal-config                \
  -DZLIB_INCLUDE_DIR=${PREFIX}/include                   \
  -DZLIB_LIBRARY:FILEPATH=${PREFIX}/lib/libz${EXT}       \
  -DCURL_INCLUDE_DIR=${PREFIX}/include                   \
  -DPostgreSQL_LIBRARY_RELEASE=${PREFIX}/lib/libpq${EXT} \
  -DCURL_LIBRARY_RELEASE=${PREFIX}/lib/libcurl${EXT}     \
  -DPROJ_INCLUDE_DIR=${PREFIX}/include                   \
  -DPROJ_LIBRARY:FILEPATH=${PREFIX}/lib/libproj${EXT}    \
  ..
make -j${CPU_COUNT} install

# geoid
cd $SRC_DIR
wget https://github.com/NeoGeographyToolkit/StereoPipeline/releases/download/geoid1.0/geoids.tgz > /dev/null 2>&1 # this is verbose
tar xzf geoids.tgz
cd geoids
if [ "$(uname)" = "Darwin" ]; then
    LIB_FLAG='-dynamiclib'
    EXT='.dylib'
else
    LIB_FLAG='-shared'
    EXT='.so'
fi
# Build
${FC} ${FFLAGS} -fPIC -O3 -c interp_2p5min.f
${FC} ${LDFLAGS} ${LIB_FLAG} -o libegm2008${EXT} interp_2p5min.o
# Install
mkdir -p ${PREFIX}/lib
/bin/cp -fv libegm2008.* ${PREFIX}/lib
GEOID_DIR=${PREFIX}/share/geoids
mkdir -p ${GEOID_DIR}
/bin/cp -fv *tif *jp2 ${GEOID_DIR}

# libnabo
cd $SRC_DIR
git clone https://github.com/NeoGeographyToolkit/libnabo.git
cd libnabo
mkdir -p build && cd build
cmake                                          \
  -DCMAKE_BUILD_TYPE=Release                   \
  -DCMAKE_CXX_FLAGS='-O3 -std=c++11'           \
  -DCMAKE_C_FLAGS='-O3'                        \
  -DCMAKE_INSTALL_PREFIX=${PREFIX}             \
  -DEIGEN_INCLUDE_DIR=${PREFIX}/include/eigen3 \
  -DCMAKE_PREFIX_PATH=${PREFIX}                \
  -DBoost_DIR=${PREFIX}/lib                    \
  -DBoost_INCLUDE_DIR=${PREFIX}/include        \
  -DBUILD_SHARED_LIBS=ON                       \
  -DCMAKE_VERBOSE_MAKEFILE=ON                  \
  ..
make -j${CPU_COUNT} install

# libpointmatcher
cd $SRC_DIR
git clone https://github.com/NeoGeographyToolkit/libpointmatcher.git
cd libpointmatcher
mkdir -p build && cd build
cmake                                          \
  -DCMAKE_BUILD_TYPE=Release                   \
  -DCMAKE_CXX_FLAGS="-O3 -std=c++17"           \
  -DCMAKE_C_FLAGS='-O3'                        \
  -DCMAKE_INSTALL_PREFIX=${PREFIX}             \
  -DCMAKE_VERBOSE_MAKEFILE=ON                  \
  -DCMAKE_PREFIX_PATH=${PREFIX}                \
  -DCMAKE_VERBOSE_MAKEFILE=ON                  \
  -DBUILD_SHARED_LIBS=ON                       \
  -DEIGEN_INCLUDE_DIR=${PREFIX}/include/eigen3 \
  -DBoost_DIR=${PREFIX}/lib                    \
  -DBoost_INCLUDE_DIR=${PREFIX}/include        \
  -DBoost_NO_BOOST_CMAKE=OFF                   \
  -DBoost_DEBUG=ON                             \
  -DBoost_DETAILED_FAILURE_MSG=ON              \
  -DBoost_NO_SYSTEM_PATHS=ON                   \
  ..
make -j${CPU_COUNT} install

# fgr
cd $SRC_DIR
git clone https://github.com/NeoGeographyToolkit/FastGlobalRegistration.git
cd FastGlobalRegistration
FGR_SOURCE_DIR=$(pwd)/source
mkdir -p build && cd build
INC_FLAGS="-I${PREFIX}/include/eigen3 -I${PREFIX}/include -O3 -L${PREFIX}/lib -lflann_cpp -llz4 -O3 -std=c++11"
cmake                                        \
  -DCMAKE_BUILD_TYPE=Release                 \
  -DCMAKE_CXX_FLAGS="${INC_FLAGS}"           \
  -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}      \
  -DCMAKE_PREFIX_PATH=${PREFIX}              \
  -DCMAKE_VERBOSE_MAKEFILE=ON                \
  -DFastGlobalRegistration_LINK_MODE=SHARED  \
  ${FGR_SOURCE_DIR}
make -j${CPU_COUNT}
# Install
FGR_INC_DIR=${PREFIX}/include/FastGlobalRegistration
mkdir -p ${FGR_INC_DIR}
/bin/cp -fv ${FGR_SOURCE_DIR}/FastGlobalRegistration/app.h ${FGR_INC_DIR}
FGR_LIB_DIR=${PREFIX}/lib
mkdir -p ${FGR_LIB_DIR}
/bin/cp -fv FastGlobalRegistration/libFastGlobalRegistrationLib* ${FGR_LIB_DIR}

#s2p
cd $SRC_DIR
git clone https://github.com/NeoGeographyToolkit/s2p.git --recursive
cd s2p
# update recursive submodules
git submodule update --init --recursive
export CFLAGS="-I$PREFIX/include -O3 -DNDEBUG -march=native"
export LDFLAGS="-L$PREFIX/lib"
baseDir=$(pwd)
# Extension
if [ "$(uname)" = "Darwin" ]; then
    EXT='.dylib'
else
    EXT='.so'
fi
# Build the desired programs
cd 3rdparty/mgm
perl -pi -e "s#CFLAGS=#CFLAGS=$CFLAGS #g" Makefile
perl -pi -e "s#LDFLAGS=#LDFLAGS=$LDFLAGS #g" Makefile 
make -j${CPU_COUNT}
cd $baseDir
# msmw
cd 3rdparty/msmw
mkdir -p build
cd build
cmake .. -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CFLAGS" \
    -DPNG_LIBRARY_RELEASE="${PREFIX}/lib/libpng${EXT}"     \
    -DTIFF_LIBRARY_RELEASE="${PREFIX}/lib/libtiff${EXT}"   \
    -DZLIB_LIBRARY_RELEASE="${PREFIX}/lib/libz${EXT}"      \
    -DJPEG_LIBRARY="${PREFIX}/lib/libjpeg${EXT}"
make -j${CPU_COUNT}
cd $baseDir
# msmw2
cd 3rdparty/msmw2
mkdir -p build
cd build
cmake ..                                                   \
    -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CFLAGS"  \
    -DPNG_LIBRARY_RELEASE="${PREFIX}/lib/libpng${EXT}"     \
    -DTIFF_LIBRARY_RELEASE="${PREFIX}/lib/libtiff${EXT}"   \
    -DZLIB_LIBRARY_RELEASE="${PREFIX}/lib/libz${EXT}"      \
    -DJPEG_LIBRARY="${PREFIX}/lib/libjpeg${EXT}"
make -j${CPU_COUNT}
cd $baseDir
# Install the desired programs
BIN_DIR=${PREFIX}/plugins/stereo/mgm/bin
mkdir -p ${BIN_DIR}
/bin/cp -fv 3rdparty/mgm/mgm ${BIN_DIR}
BIN_DIR=${PREFIX}/plugins/stereo/msmw/bin
mkdir -p ${BIN_DIR}
/bin/cp -fv \
    3rdparty/msmw/build/libstereo/iip_stereo_correlation_multi_win2 \
    ${BIN_DIR}/msmw
BIN_DIR=${PREFIX}/plugins/stereo/msmw2/bin
mkdir -p ${BIN_DIR}
/bin/cp -fv \
    3rdparty/msmw2/build/libstereo_newversion/iip_stereo_correlation_multi_win2_newversion \
    ${BIN_DIR}/msmw2

# libelas
if [ "$(uname -m | grep -i arm)" != "" ]; then 
    echo Libelas does not build on Arm
else
    cd $SRC_DIR
    git clone https://github.com/NeoGeographyToolkit/libelas.git
    cd libelas
    # Set the env
    export CFLAGS="-I$PREFIX/include -O3 -DNDEBUG -ffast-math -march=native"
    export LDFLAGS="-L$PREFIX/lib"
    if [ "$(uname)" = "Darwin" ]; then
        EXT='.dylib'
    else
        EXT='.so'
    fi
    # build
    mkdir -p build
    cd build
    cmake ..                                             \
    -DTIFF_LIBRARY_RELEASE="${PREFIX}/lib/libtiff${EXT}" \
    -DTIFF_INCLUDE_DIR="${PREFIX}/include"               \
    -DCMAKE_CXX_FLAGS="-I${PREFIX}/include"
    make -j${CPU_COUNT}
    # Copy the 'elas' tool to the plugins subdir meant for it
    BIN_DIR=${PREFIX}/plugins/stereo/elas/bin
    mkdir -p ${BIN_DIR}
    /bin/cp -fv elas ${BIN_DIR}/elas
fi

# Multiview
cd $SRC_DIR
git clone git@github.com:NeoGeographyToolkit/MultiView.git --recursive
cd MultiView
git submodule update --init --recursive
mkdir -p build && cd build
cmake ..                                          \
    -DCMAKE_BUILD_TYPE=Release                    \
    -DMULTIVIEW_DEPS_DIR=${PREFIX}                \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13           \
    -DCMAKE_MODULE_PATH=$PREFIX/share/pcl-1.13/Modules \
    -DCMAKE_VERBOSE_MAKEFILE=ON                   \
    -DCMAKE_CXX_FLAGS="-O3 -std=c++11 -Wno-error -I${PREFIX}/include" \
    -DCMAKE_C_FLAGS='-O3 -Wno-error'              \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}
make -j${CPU_COUNT} install

# Build latest visionworkbench
cd $SRC_DIR
git clone git@github.com:visionworkbench/visionworkbench.git
cd visionworkbench
mkdir -p build
cd build
cmake ..                                         \
    -DCMAKE_PREFIX_PATH=${PREFIX}                \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}             \
    -DASP_DEPS_DIR=${PREFIX}                     \
    -DUSE_OPENEXR=OFF                            \
    -DCMAKE_VERBOSE_MAKEFILE=ON
make -j${CPU_COUNT} install

# Build stereo-pipeline with ISIS and without OpenEXR. The source code is
# fetched by conda-build based on meta.yaml.
cd $SRC_DIR
mkdir -p build
cd build
cmake ..                             \
    -DCMAKE_PREFIX_PATH=${PREFIX}    \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DASP_DEPS_DIR=${PREFIX}         \
    -DUSE_ISIS=ON                    \
    -DUSE_OPENEXR=OFF                \
    -DCMAKE_VERBOSE_MAKEFILE=ON
make -j${CPU_COUNT} install
