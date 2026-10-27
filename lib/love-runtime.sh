# LOVE 11.5 runtime for goodluckOS, sourced by the LOVE game build scripts
# after cross.sh. LOVE and its audio and LuaJIT libraries come from Debian
# trixie armhf; libtheoradec is rebuilt because Debian's links cairo, which
# goodluckOS lacks. SDL2, Mesa, FreeType, zlib, ALSA and the C/C++ runtime come
# from goodluckOS.
#
# love_runtime DEST: DEST/love, DEST/lib/ and the license notices in DEST/lib/licenses/

LOVE_DEBS=(love libluajit-5.1-2 libopenal1 libmodplug1 libmpg123-0t64 libogg0 libvorbis0a libvorbisfile3)
LOVE_LIBS=(libluajit-5.1.so.2 libopenal.so.1 libmodplug.so.1 libmpg123.so.0 libogg.so.0 libvorbis.so.0 libvorbisfile.so.3)
THEORA=libtheora-1.1.1
THEORA_SHA256=f36da409947aa2b3dcc6af0a8c2e3144bc19db2ed547d64e9171c59c66561c61

love_runtime() {
    local dest=$1 debs pkg lib
    local theoradec=$SRC_DIR/$THEORA/lib/.libs/libtheoradec.so.1

    cross_sysroot
    mkdir -p "$dest/lib"
    debs=$(mktemp -d)
    deb_index
    for pkg in "${LOVE_DEBS[@]}"; do
        deb_fetch "$pkg" "$debs"
    done

    if [[ ! -f $theoradec ]]; then
        fetch_file "https://downloads.xiph.org/releases/theora/$THEORA.tar.xz" "$THEORA_SHA256" "$DL_DIR/$THEORA.tar.xz"
        rm -rf "${SRC_DIR:?}/$THEORA"
        tar -xf "$DL_DIR/$THEORA.tar.xz" -C "$SRC_DIR"
        (
            cd "$SRC_DIR/$THEORA"
            CC="$CROSS_CC $CROSS_LDFLAGS" ./configure --host=arm-linux-gnueabihf --build="$(uname -m)-pc-linux-gnu" \
                --prefix=/usr --disable-static --disable-asm --disable-encode --disable-examples \
                --disable-oggtest --disable-vorbistest --disable-sdltest --disable-spec > configure.log
            make -C lib -j"$JOBS" libtheoradec.la > build.log
        )
    fi

    cp "$debs/usr/bin/love-11.5" "$dest/love"
    for lib in "${LOVE_LIBS[@]}"; do
        cp -L "$debs/usr/lib/arm-linux-gnueabihf/$lib" "$dest/lib/"
    done
    for pkg in "${LOVE_DEBS[@]}"; do
        deb_notice "$pkg" "$debs" "$dest/lib/licenses"
    done
    llvm-strip --strip-unneeded -o "$dest/lib/libtheoradec.so.1" "$theoradec"
    cp "$SRC_DIR/$THEORA/COPYING" "$dest/lib/licenses/libtheora.txt"
    echo "libtheora 1.1.1 https://downloads.xiph.org/releases/theora/$THEORA.tar.xz" >> "$dest/lib/licenses/SOURCES.txt"
    rm -rf "$debs"
}
