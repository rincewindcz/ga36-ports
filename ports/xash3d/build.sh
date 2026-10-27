#!/usr/bin/env bash
# Half-Life on the Xash3D FWGS engine (SDL2, gles1, gles2 and soft renderers)
# with the hlsdk-portable game libraries, built with waf. hlsdk-portable names
# the libraries with the _armv7hf suffix the engine appends to the liblist.gam
# paths, so the x86 libraries of a Steam valve/ can stay in place. The player
# puts the Half-Life valve/ directory into ports/xash3d/data, which run.sh
# passes as -rodir and which is staged empty.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

XASH_REPO=https://github.com/FWGS/xash3d-fwgs.git
XASH_COMMIT=e8d773eaa640f65db66164afbf5b867a5544b9b0
HLSDK_REPO=https://github.com/FWGS/hlsdk-portable.git
HLSDK_COMMIT=8a09758d2912d278423870391f6c25995de0000b
XASH_OPTS=(--sdl-use-pkgconfig --enable-bundled-deps --enable-stbtt --disable-mbedtls
           --disable-gl --enable-gles1 --enable-gles2 --enable-soft)
GPL3_SHA256=3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986
xash=$SRC_DIR/xash3d-fwgs
hlsdk=$SRC_DIR/hlsdk-portable
log=$BUILD_DIR/xash3d/build.log

# waf_build DIR DESTDIR CONFIGURE_OPTION...
waf_build() {
    local dir=$1 dest=$2
    shift 2
    (
        cd "$dir"
        CC="$CROSS_CC" CXX="$CROSS_CXX" LINKFLAGS="$CROSS_LDFLAGS" STRIP=llvm-strip OBJCOPY=llvm-objcopy \
            python3 waf configure -T release -o build-goodluck "$@"
        python3 waf build -j"$JOBS"
        python3 waf install --strip --destdir="$dest"
    )
}

cross_sysroot
fetch_commit "$xash" "$XASH_REPO" "$XASH_COMMIT"
git -C "$xash" submodule update -q --init --recursive --depth 1
fetch_commit "$hlsdk" "$HLSDK_REPO" "$HLSDK_COMMIT"
git -C "$hlsdk" submodule update -q --init --recursive --depth 1
fetch_file https://www.gnu.org/licenses/gpl-3.0.txt "$GPL3_SHA256" "$DL_DIR/gpl-3.0.txt"
cross_pkgconfig

stage=$(stage_dir xash3d)
game=$stage/ports/xash3d
mkdir -p "$game/data" "$game/valve/userconfig.d"
{
    waf_build "$xash" "$game" "${XASH_OPTS[@]}"
    waf_build "$hlsdk" "$game"
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

cp "$DL_DIR/gpl-3.0.txt" "$game/LICENSE.txt"
cp "$hlsdk/LICENSE" "$game/LICENSE-hlsdk.txt"
cp "$here/run.sh" "$game/"
cp "$here/goodluck.cfg" "$game/valve/userconfig.d/"
cp "$here/xash3d.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/xash3d.png"
