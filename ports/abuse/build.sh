#!/usr/bin/env bash
# Abuse 2025: SDL2 renderer game with built-in gamepad support. Its MIDI music
# needs FluidSynth with the bundled SF2 soundfonts, which the goodluckOS
# SDL2_mixer (Timidity only) lacks, so a minimal FluidSynth (no glib, no audio
# drivers) and an SDL2_mixer linked to it are built and bundled. The Lisp
# interpreter calls members on nil, so null pointer checks must stay. The game
# data comes from the repository.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/apancik/Abuse_2025.git
GAME_COMMIT=48bc0d079116c6429989bcf88595ef20c5c1b80f
FLUIDSYNTH_REPO=https://github.com/FluidSynth/fluidsynth.git
FLUIDSYNTH_COMMIT=71e85b2ca6bf48641ba7e2261d8f2640ae473773
MIXER_REPO=https://github.com/libsdl-org/SDL_mixer.git
MIXER_COMMIT=b208916aed9250fe434360e6c6a95f0697bb7b01
FLUIDSYNTH_OPTS=(-DBUILD_SHARED_LIBS=ON -Denable-floats=ON -Denable-threads=ON
                 -Denable-alsa=OFF -Denable-aufile=OFF -Denable-dbus=OFF -Denable-ipv6=OFF -Denable-jack=OFF
                 -Denable-ladspa=OFF -Denable-libsndfile=OFF -Denable-midishare=OFF -Denable-network=OFF
                 -Denable-oss=OFF -Denable-sdl3=OFF -Denable-pulseaudio=OFF -Denable-pipewire=OFF
                 -Denable-readline=OFF -Denable-openmp=OFF -Denable-systemd=OFF -Denable-native-dls=OFF
                 -Denable-signalsmith=OFF)
MIXER_OPTS=(-DSDL2MIXER_VENDORED=OFF -DSDL2MIXER_SAMPLES=OFF -DSDL2MIXER_CMD=OFF
            -DSDL2MIXER_MIDI_FLUIDSYNTH=ON -DSDL2MIXER_MIDI_FLUIDSYNTH_SHARED=OFF
            -DSDL2MIXER_MOD=OFF -DSDL2MIXER_OPUS=OFF -DSDL2MIXER_WAVPACK=OFF)
src=$SRC_DIR/abuse
fluidsynth_src=$SRC_DIR/fluidsynth
mixer_src=$SRC_DIR/SDL2_mixer
deps=$BUILD_DIR/abuse/deps
log=$BUILD_DIR/abuse/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
fetch_commit "$fluidsynth_src" "$FLUIDSYNTH_REPO" "$FLUIDSYNTH_COMMIT"
git -C "$fluidsynth_src" submodule update -q --init --depth 1 gcem
fetch_commit "$mixer_src" "$MIXER_REPO" "$MIXER_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir abuse)
game=$stage/ports/abuse
rm -rf "$deps"
mkdir -p "$deps"
{
    cross_cmake "$fluidsynth_src" "$fluidsynth_src/build-goodluck" "${FLUIDSYNTH_OPTS[@]}"
    cmake --install "$fluidsynth_src/build-goodluck" --prefix "$deps"
    cross_cmake "$mixer_src" "$mixer_src/build-goodluck" "${MIXER_OPTS[@]}" \
        -DFluidSynth_LIBRARY="$deps/lib/libfluidsynth.so" -DFluidSynth_INCLUDE_PATH="$deps/include"
    cmake --install "$mixer_src/build-goodluck" --prefix "$deps"
    cross_cmake "$src" "$src/build-goodluck" -DCMAKE_INSTALL_PREFIX=/home/player/ports/abuse \
        -DCMAKE_CXX_FLAGS="$CROSS_FLAGS -fno-delete-null-pointer-checks" \
        -DSDL2_MIXER_LIBRARY="$deps/lib/libSDL2_mixer.so"
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib/licenses"
llvm-strip -o "$game/abuse" "$src/build-goodluck/src/abuse"
llvm-strip -o "$game/lib/libfluidsynth.so.3" "$deps/lib/libfluidsynth.so.3"
llvm-strip -o "$game/lib/libSDL2_mixer-2.0.so.0" "$deps/lib/libSDL2_mixer-2.0.so.0"
cp "$fluidsynth_src/LICENSE" "$game/lib/licenses/fluidsynth.txt"
cp "$mixer_src/LICENSE.txt" "$game/lib/licenses/SDL2_mixer.txt"
cp -r "$src/data" "$game/"
rm "$game/data/CMakeLists.txt"
cp "$src/COPYING" "$game/LICENSE.txt"
cp "$src/COPYING.GPL" "$src/COPYING.WTFPL" "$game/"
cp "$here/run.sh" "$game/"
cp "$here/abuse.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/abuse.png"
