#!/bin/sh
# Starts a J2ME game on FreeJ2ME-Plus in RetroArch.
here=$(dirname "$(readlink -f "$0")")
export PATH="$here/bin:$PATH"
exec retroarch --appendconfig "$here/retroarch.cfg" -L "$here/freej2me_plus_libretro.so" "$@" > "$here/run.log" 2>&1
