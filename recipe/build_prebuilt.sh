#!/bin/bash
# "Trick conda" approach: rsync pre-built ASP/VW/recipe-deps into $PREFIX
# instead of compiling from source. The dev build was done in isis_dev
# with gcc 14 and is known-good (all tools load + smoke test pass).
# This script just copies the artifacts into conda-build's staging prefix
# so conda-build can package them.

set -e

PREBUILT=/tmp/asp_prebuilt
ISIS_DEV=/home/oalexan1/miniconda3/envs/isis_dev

echo "=== Rsyncing pre-built ASP 3.7.0 from isis_dev ==="

# Copy binaries (ASP tools + cgal_tools)
rsync -a ${ISIS_DEV}/bin/ ${PREFIX}/bin/ \
  --include='stereo_pprc' --include='stereo_corr' --include='stereo_rfne' \
  --include='stereo_fltr' --include='stereo_tri' --include='stereo_gui' \
  --include='bundle_adjust' --include='jitter_solve' --include='parallel_stereo' \
  --include='mapproject' --include='cam_gen' --include='cam2rpc' \
  --include='point2dem' --include='point2las' --include='point2mesh' \
  --include='pc_align' --include='pc_merge' --include='dem_mosaic' \
  --include='dem_geoid' --include='geodiff' --include='image_calc' \
  --include='colormap' --include='hillshade' --include='sfs' \
  --include='sat_sim' --include='wv_correct' --include='bathy_threshold_calc' \
  --include='bathy_plane_calc' --include='undistort_image' \
  --include='image2qtree' --include='print_exif' --include='ipfind' \
  --include='ipmatch' --include='correlate' --include='lronac2mosaic.py' \
  --include='dg_mosaic' --include='cam_test' --include='camera_footprint' \
  --include='convert_pinhole_model' --include='pansharp' \
  --include='aster2asp' --include='hiedr2mosaic.py' \
  --include='historical_helper.py' --include='n_align' \
  --include='sfs_blend' --include='multi_stereo' \
  --include='otsu_threshold' --include='s2p_pprc' --include='s2p_fltr' \
  --include='sparse_disp' --include='stereo' --include='stereo_parse' \
  --include='opencv_calibrate' --include='opencv_imagelist_creator' \
  --include='usgscsm_cam_test' --include='ri_compare' \
  --include='bathy_correct' --include='camera_solve' \
  --include='sfm_merge' --include='sfm_subgraph' --include='sfm_view' \
  --include='dem_profile' --include='gcp_gen' \
  --include='fill_holes' --include='rm_connected_components' \
  --include='simplify_mesh' --include='smoothe_mesh' \
  --include='campt' --include='cam_gen' \
  --exclude='*'

# Copy all libraries we built (VW + ASP + recipe deps)
for lib in libVw libAsp libtheia libnabo libpointmatcher \
           libFastGlobal libegm2008 libmve libtexture_reconstruction \
           libvoxblox librayint; do
  cp -a ${ISIS_DEV}/lib/${lib}* ${PREFIX}/lib/ 2>/dev/null || true
done

# Copy plugins (s2p, libelas)
rsync -a ${ISIS_DEV}/plugins/ ${PREFIX}/plugins/ 2>/dev/null || true

# Copy headers
rsync -a ${ISIS_DEV}/include/vw/ ${PREFIX}/include/vw/ 2>/dev/null || true
rsync -a ${ISIS_DEV}/include/asp/ ${PREFIX}/include/asp/ 2>/dev/null || true
rsync -a ${ISIS_DEV}/include/FastGlobalRegistration/ ${PREFIX}/include/FastGlobalRegistration/ 2>/dev/null || true

# Copy geoids and other share data
rsync -a ${ISIS_DEV}/share/geoids/ ${PREFIX}/share/geoids/ 2>/dev/null || true
rsync -a ${ISIS_DEV}/share/wv_correct/ ${PREFIX}/share/wv_correct/ 2>/dev/null || true
rsync -a ${ISIS_DEV}/share/CASP-GO_params.xml ${PREFIX}/share/ 2>/dev/null || true
rsync -a ${ISIS_DEV}/share/tests/ ${PREFIX}/share/tests/ 2>/dev/null || true

echo "=== Pre-built rsync complete ==="
echo "Verifying key files..."
test -x ${PREFIX}/bin/stereo_pprc || { echo "FAIL: stereo_pprc missing"; exit 1; }
test -f ${PREFIX}/lib/libAspCore.so || { echo "FAIL: libAspCore.so missing"; exit 1; }
test -f ${PREFIX}/lib/libVwCore.so || { echo "FAIL: libVwCore.so missing"; exit 1; }
echo "Key files verified OK"
