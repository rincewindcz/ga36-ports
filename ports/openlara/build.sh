#!/usr/bin/env bash
# OpenLara (Tomb Raider engine): SDL2 platform with the GLES2 renderer and the
# Mali-400 patches. The game data is not included; prepare.sh stages it from
# the user's own copy into ports/openlara.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

REPO=https://github.com/XProger/OpenLara.git
COMMIT=3b268ca4bf986c380f44a26ffd9218bf6d376249
src=$SRC_DIR/OpenLara
obj=$BUILD_DIR/openlara/obj
log=$BUILD_DIR/openlara/build.log

cross_sysroot
fetch_commit "$src" "$REPO" "$COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir openlara)
game=$stage/ports/openlara
s=$src/src
flags=(-DMALI400 -DSDL2_GLES -D_GAPI_GLES2 -D__SDL2__ -DNDEBUG -O3 -ffunction-sections -fdata-sections
       -Wno-invalid-source-encoding -D_REENTRANT -I"$SYSROOT/usr/include/SDL2" -I"$s")
cxxflags=(-std=c++11 -fno-exceptions -fno-rtti)
rm -rf "$obj"
mkdir -p "$obj"
{
    $CROSS_CC "${flags[@]}" -c "$s/libs/stb_vorbis/stb_vorbis.c" -o "$obj/stb_vorbis.o"
    $CROSS_CC "${flags[@]}" -c "$s/libs/tinf/tinflate.c" -o "$obj/tinflate.o"
    $CROSS_CXX "${flags[@]}" "${cxxflags[@]}" -c "$s/libs/minimp3/minimp3.cpp" -o "$obj/minimp3.o"
    $CROSS_CXX "${flags[@]}" "${cxxflags[@]}" -c "$s/platform/sdl2/main.cpp" -o "$obj/main.o"
    $CROSS_CXX $CROSS_LDFLAGS -Wl,--gc-sections -s "$obj"/*.o -o "$obj/OpenLara" -lSDL2 -lGLESv2 -lm -lpthread
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

cp "$obj/OpenLara" "$here/run.sh" "$game/"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$here/openlara.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/openlara.png"
