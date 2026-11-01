#!/usr/bin/env bash
# FreeJ2ME-Plus as a libretro core for the RetroArch of goodluckOS. The core
# starts its Java app with the java found on PATH, so run.sh puts bin/java
# first: it runs the bundled Debian JRE with the libraries the device lacks.
# Java plays the sound itself, so RetroArch audio is off and asound.conf mixes
# its synthesizer lines.
# The jar is built here like upstream's jar-libretro target, since the patch
# changes it.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/TASEmulators/freej2me-plus.git
GAME_COMMIT=3933e75ef927a95eab9f5e065f0b76dabf336069
JRE_DEBS=(openjdk-21-jre-headless libharfbuzz0b libgraphite2-3 libglib2.0-0t64 libpcre2-8-0
          libjpeg62-turbo liblcms2-2 libfontconfig1 libexpat1)
JRE_LIBS=(libharfbuzz.so.0 libgraphite2.so.3 libglib-2.0.so.0 libpcre2-8.so.0
          libjpeg.so.62 liblcms2.so.2 libfontconfig.so.1 libexpat.so.1)
src=$SRC_DIR/freej2me
log=$BUILD_DIR/freej2me/build.log
classes=$BUILD_DIR/freej2me/classes

cross_sysroot
deb_index
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir freej2me)
game=$stage/ports/freej2me
mkdir -p "$game/bin" "$game/games" "$game/system" "$game/lib"
make -C "$src/src/libretro" -j"$JOBS" platform=unix CC="$CROSS_CC -fuse-ld=lld" CXX="$CROSS_CXX -fuse-ld=lld" \
    > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }
llvm-strip -o "$game/freej2me_plus_libretro.so" "$src/src/libretro/freej2me_plus_libretro.so"

rm -rf "$classes"
mkdir -p "$classes"
find "$src/src" -name '*.java' -not -path '*/libretro/*' -not -path '*/win32pad/*' > "$BUILD_DIR/freej2me/sources"
javac --release 8 -nowarn -encoding utf-8 -d "$classes" "@$BUILD_DIR/freej2me/sources" >> "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }
find "$classes" \( -name 'FJGUI*.class' -o -name 'FreeJ2ME*.class' -o -name 'ScreenShot*.class' \) -delete
rm -rf "$classes/org/recompile/freej2me/gamepad"
cp -r "$src/resources/." "$src/META-INF" "$classes/"
jar --create --file "$game/system/freej2me_plus-lr.jar" --main-class org.recompile.freej2me.Libretro -C "$classes" .

debs=$(mktemp -d)
trap 'rm -rf "$debs"' EXIT
for pkg in "${JRE_DEBS[@]}"; do
    deb_fetch "$pkg" "$debs"
    deb_notice "$pkg" "$debs" "$game/lib/licenses"
done
for lib in "${JRE_LIBS[@]}"; do
    cp -L "$debs/usr/lib/arm-linux-gnueabihf/$lib" "$game/lib/"
done

# HOME is vfat: the links into /etc become plain files
jre=$debs/usr/lib/jvm/java-21-openjdk-armhf
cp "$jre/lib/jvm.cfg-default" "$jre/lib/jvm.cfg.real"
find "$jre" -xtype l -delete
mv "$jre/lib/jvm.cfg.real" "$jre/lib/jvm.cfg"
mkdir -p "$game/jre/bin"
cp -L "$jre/bin/java" "$game/jre/bin/"
cp -rL "$jre/lib" "$jre/conf" "$game/jre/"
cp -rL "$debs/etc/java-21-openjdk/." "$game/jre/conf/"
rm -rf "$game/jre/lib/jfr" "$game/jre/lib/classlist" "$game/jre/lib/jrt-fs.jar" "$game/jre/lib/jar.binfmt" \
    "$game/jre/lib/jexec" "$game/jre/lib/jvm.cfg-default" "$game/jre/conf/jvm-armhf.cfg"

cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$here/run.sh" "$here/fonts.conf" "$here/asound.conf" "$here/retroarch.cfg" "$here/options.cfg" "$game/"
cp "$here/java" "$game/bin/"
cp "$here/freej2me.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/freej2me.png"
