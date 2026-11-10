# DXX-Rebirth for goodluckOS, sourced by the Descent and Descent 2 build
# scripts after cross.sh. SDL2 with the OpenGL ES 1 renderer, which Mesa lima
# provides natively. One checkout and one SCons build directory serve both
# ports; SCons runs from a virtualenv in $BUILD_DIR/scons.
#
# dxx_build TARGET LOG: builds d1x-rebirth or d2x-rebirth, binary at $DXX_SRC/build-goodluck/TARGET/TARGET

DXX_REPO=https://github.com/dxx-rebirth/dxx-rebirth.git
DXX_COMMIT=56aa6210b2066aca761619a9d2fdf8585137aba8
DXX_SRC=$SRC_DIR/dxx-rebirth
SCONS_VERSION=4.11.1
SCONS=$BUILD_DIR/scons/bin/scons

dxx_build() {
    local target=$1 log=$2
    cross_sysroot
    fetch_commit "$DXX_SRC" "$DXX_REPO" "$DXX_COMMIT"
    apply_patches "$DXX_SRC" "$GA36_ROOT"/lib/dxx-*.patch
    cross_pkgconfig
    {
        if [[ ! -x $SCONS ]]; then
            python3 -m venv "$BUILD_DIR/scons"
            "$BUILD_DIR/scons/bin/pip" install -q "scons==$SCONS_VERSION"
        fi
        # use_udp=0 does not compile upstream; clang 23 reports -Wunused-but-set-global, which -Werror=unused turns fatal
        (cd "$DXX_SRC" && "$SCONS" -j"$JOBS" host_platform=linux CXX=clang++ \
            CXXFLAGS="$CROSS_FLAGS -O2" LINKFLAGS="$CROSS_FLAGS $CROSS_LDFLAGS" \
            CPPFLAGS="-Wno-sign-compare -Wno-unused-but-set-global" PKG_CONFIG=pkg-config \
            sdl2=1 sdlmixer=1 opengl=1 opengles=1 opengles_lib=GLESv1_CM \
            ipv6=0 use_udp=1 use_tracker=0 screenshot=png words_need_alignment=1 \
            builddir=build-goodluck/ "build-goodluck/$target/$target")
    } > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }
}
