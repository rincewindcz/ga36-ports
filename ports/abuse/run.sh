#!/bin/sh
# Starts Abuse 2025. data/ lives next to this script; lib/ holds FluidSynth
# and an SDL2_mixer with FluidSynth MIDI. Config and saves go to
# $HOME/.local/share/abuse/data.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ABUSE_PATH="$here/data"
cd "$here" || exit 1
exec ./abuse "$@" > "$here/run.log" 2>&1
