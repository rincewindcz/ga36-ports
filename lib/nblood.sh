# NBlood source ports for goodluckOS, sourced by the Blood and Powerslave build
# scripts after cross.sh. Classic software renderer over SDL2: the Mali-400 has
# no desktop GL. One checkout serves both ports, which share the engine objects.
#
# nblood_build TARGET LOG [PATCH...]: builds a make target (blood, exhumed) in $NBLOOD_SRC

NBLOOD_REPO=https://github.com/nukeykt/NBlood.git
NBLOOD_COMMIT=497385d64b97f4fd13b6efb3929df0f2ab3adc87
NBLOOD_SRC=$SRC_DIR/nblood

nblood_build() {
    local target=$1 log=$2
    shift 2
    local flags="-marm -I$SYSROOT/usr/include/SDL2"
    cross_sysroot
    fetch_commit "$NBLOOD_SRC" "$NBLOOD_REPO" "$NBLOOD_COMMIT"
    apply_patches "$NBLOOD_SRC" "$GA36_ROOT/lib/nblood-link-flac-only-with-have-flac.patch" "$@"
    make -C "$NBLOOD_SRC" -j"$JOBS" "$target" \
        PLATFORM=LINUX ARCH=armv7l \
        CC="$CROSS_CC $flags" CXX="$CROSS_CXX $flags" LDFLAGS="$CROSS_LDFLAGS" \
        SDLCONFIG= \
        USE_OPENGL=0 POLYMER=0 USE_LIBVPX=0 HAVE_GTK2=0 STARTUP_WINDOW=0 \
        HAVE_FLAC=0 NETCODE=0 \
        STRIP=llvm-strip > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }
}
