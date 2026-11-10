#!/bin/sh
# Starts Descent 2 on D2X-Rebirth. data/ holds the game data, descent.cfg, the
# pilots and the saves (D2X_REBIRTH_HOME). lib/ holds PhysicsFS.
here=$(dirname "$(readlink -f "$0")")
data=$here/data
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export D2X_REBIRTH_HOME="$data/"
cd "$here" || exit 1
# goodluck.cfg seeds the screen mode; the game rewrites descent.cfg on quit.
[ -f "$data/descent.cfg" ] || { mkdir -p "$data" && cp goodluck.cfg "$data/descent.cfg"; }
exec ./d2x-rebirth -hogdir "$data" "$@" > "$here/run.log" 2>&1
