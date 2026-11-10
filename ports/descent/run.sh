#!/bin/sh
# Starts Descent on D1X-Rebirth. data/ holds the game data, descent.cfg, the
# pilots and the saves (D1X_REBIRTH_HOME). The first start unpacks the
# shareware descent.hog and descent.pig from the bundled desc14sw.tar.gz unless
# a descent.hog of the full version is already there. lib/ holds PhysicsFS.
here=$(dirname "$(readlink -f "$0")")
data=$here/data
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export D1X_REBIRTH_HOME="$data/"
cd "$here" || exit 1

if [ ! -f "$data/descent.hog" ]; then
    tmp=$data/.shareware
    rm -rf "$tmp"
    mkdir -p "$tmp"
    if tar -xzf shareware/desc14sw.tar.gz -C "$tmp" desc14sw/descent.hog desc14sw/descent.pig; then
        mv "$tmp/desc14sw/descent.pig" "$tmp/desc14sw/descent.hog" "$data/"
    fi
    rm -rf "$tmp"
fi

# goodluck.cfg seeds the screen mode; the game rewrites descent.cfg on quit.
[ -f "$data/descent.cfg" ] || { mkdir -p "$data" && cp goodluck.cfg "$data/descent.cfg"; }
exec ./d1x-rebirth -hogdir "$data" "$@" > "$here/run.log" 2>&1
