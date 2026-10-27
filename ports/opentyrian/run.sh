#!/bin/sh
# Starts OpenTyrian. data/ (Tyrian 2.1 freeware) lives next to this script.
# Settings and saves go to $HOME/.config/opentyrian.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./opentyrian "$@" > "$here/run.log" 2>&1
