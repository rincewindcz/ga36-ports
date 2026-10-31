#!/bin/sh
# Starts Blood: run.sh [cryptic] (Cryptic Passage). The game data lives in
# data/; config, saves and nblood.pk3 are in the working directory.
here=$(dirname "$(readlink -f "$0")")
case $1 in
    "")      ini= ;;
    cryptic) ini="-ini CRYPTIC.INI" ;;
    *)       echo "usage: $0 [cryptic]" >&2; exit 1 ;;
esac
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
cd "$here" || exit 1
exec ./nblood -usecwd -nosetup -j data $ini > "$here/run.log" 2>&1
