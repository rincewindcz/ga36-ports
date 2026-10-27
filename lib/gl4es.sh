# gl4es for goodluckOS, sourced by the build scripts of OpenGL 1.x games after
# cross.sh. libGL.so.1 translates OpenGL 1.x to GLES 2 on Mesa lima; built with
# NOX11 and without the EGL wrapper, so the game creates a GLES 2 context
# through SDL and gl4es renders into it. run.sh sets LIBGL_GLES and LIBGL_EGL.
#
# gl4es_build: builds $GL4ES_LIB (upstream sets no soname)

GL4ES_REPO=https://github.com/ptitSeb/gl4es.git
GL4ES_COMMIT=2037865590d410bcd7b8d1f22b841472ed6d39ac
GL4ES_SRC=$SRC_DIR/gl4es
GL4ES_LIB=$GL4ES_SRC/lib/libGL.so.1

gl4es_build() {
    fetch_commit "$GL4ES_SRC" "$GL4ES_REPO" "$GL4ES_COMMIT"
    cross_cmake "$GL4ES_SRC" "$GL4ES_SRC/build-goodluck" -DNOX11=ON -DDEFAULT_ES=2 \
        -DCMAKE_SHARED_LINKER_FLAGS="$CROSS_LDFLAGS -Wl,-soname,libGL.so.1"
}
