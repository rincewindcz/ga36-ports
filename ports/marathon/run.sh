#!/bin/sh
# Starts Marathon on Aleph One. data/ is the scenario (Aleph One's Marathon
# release package), share/ holds the engine's default theme, lib/ holds
# OpenAL, libsndfile with its codecs and Boost.Filesystem. Preferences, saves
# and screenshots go to $HOME/.alephone.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ALEPHONE_DATA="$here/data:$here/share"
cd "$here" || exit 1
exec ./alephone --fullscreen --no-chooser "$here/data" "$@" > "$here/run.log" 2>&1
