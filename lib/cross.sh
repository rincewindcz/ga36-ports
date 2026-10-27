# Cross-compile environment for goodluckOS armhf userspace, sourced by the port
# build scripts. Headers and link-time libraries come from a Debian trixie armhf
# sysroot ($BUILD_DIR/sysroot); binaries run against the newer glibc, libstdc++
# and SDL2 of goodluckOS.
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
. "$GA36_ROOT/lib/deb.sh"

SYSROOT=$BUILD_DIR/sysroot
SYSROOT_DEBS=(libc6 libc6-dev linux-libc-dev libgcc-14-dev libgcc-s1 libstdc++-14-dev libstdc++6
              libsdl2-dev libsdl2-2.0-0 libx11-dev x11proto-dev
              libasound2-dev libasound2t64
              libsdl2-gfx-dev libsdl2-gfx-1.0-0 libpng-dev libpng16-16t64 zlib1g-dev zlib1g
              libvorbisidec-dev libvorbisidec1 libogg-dev libogg0
              libsdl2-mixer-dev libsdl2-mixer-2.0-0
              libgles-dev libgles2 libegl-dev libegl1 libgl-dev libglvnd0
              libsdl3-dev libsdl3-0
              libopenal-dev libopenal1 libvorbis-dev libvorbis0a libvorbisfile3 libvorbisenc2
              libjsoncpp-dev libjsoncpp26 libjpeg62-turbo-dev libjpeg62-turbo
              libepoxy-dev libepoxy0 libsdl2-image-dev libsdl2-image-2.0-0
              libopenmpt-dev libopenmpt0t64 libmpg123-0t64)
CROSS_FLAGS="--target=arm-linux-gnueabihf --sysroot=$SYSROOT -march=armv7-a -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard"
CROSS_CC="clang $CROSS_FLAGS"
CROSS_CXX="clang++ $CROSS_FLAGS"
CROSS_LDFLAGS="-fuse-ld=lld"

cross_sysroot() {
    [[ -f $SYSROOT/.done && $(< "$SYSROOT/.done") == "${SYSROOT_DEBS[*]}" ]] && return
    deb_index
    rm -rf "$SYSROOT"
    mkdir -p "$SYSROOT/usr/lib" "$SYSROOT/usr/bin" "$SYSROOT/usr/sbin"
    ln -s usr/lib "$SYSROOT/lib"
    ln -s usr/bin "$SYSROOT/bin"
    ln -s usr/sbin "$SYSROOT/sbin"
    for pkg in "${SYSROOT_DEBS[@]}"; do
        deb_fetch "$pkg" "$SYSROOT"
    done
    echo "${SYSROOT_DEBS[*]}" > "$SYSROOT/.done"
}

# cross_pkgconfig: points pkg-config at the sysroot
cross_pkgconfig() {
    export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
    export PKG_CONFIG_LIBDIR=$SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/share/pkgconfig
}

# cross_cmake SRC BUILD CMAKE_OPTION... : configure SRC for goodluckOS in BUILD and build it
cross_cmake() {
    local src=$1 build=$2
    shift 2
    cmake -S "$src" -B "$build" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=arm -DCMAKE_SYSROOT="$SYSROOT" \
        -DCMAKE_C_COMPILER=clang -DCMAKE_C_FLAGS="$CROSS_FLAGS" \
        -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS="$CROSS_FLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$CROSS_LDFLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$CROSS_LDFLAGS" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DCMAKE_SKIP_RPATH=ON "$@"
    cmake --build "$build" -j"$JOBS"
}
