# Shared settings and helpers, sourced by every port build script.
#
# BUILD_DIR (default build/ in the repository) holds the source checkouts, the
# downloads, the sysroot and one directory per port with its stage tree. The
# stage tree is the HOME root of the console: tools/package.sh zips it as is.

GA36_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-$GA36_ROOT/build}
SRC_DIR=$BUILD_DIR/src
DL_DIR=$BUILD_DIR/dl
JOBS=${JOBS:-$(nproc)}

DEBIAN_SUITE=trixie
DEBIAN_MIRROR=http://deb.debian.org/debian

mkdir -p "$SRC_DIR" "$DL_DIR"

# fetch_commit DIR REPO COMMIT: shallow checkout of one pinned commit
fetch_commit() {
    local dir=$1 repo=$2 commit=$3
    [[ -d $dir ]] || git init -q "$dir"
    if [[ $(git -C "$dir" rev-parse -q --verify HEAD || true) != "$commit" ]]; then
        git -C "$dir" fetch -q --depth 1 "$repo" "$commit"
        git -C "$dir" checkout -q -f FETCH_HEAD
    fi
}

# apply_patches DIR PATCH...: applies each patch unless it is already applied
apply_patches() {
    local dir=$1 patch
    shift
    for patch in "$@"; do
        git -C "$dir" apply --reverse --check "$patch" 2> /dev/null || git -C "$dir" apply "$patch"
    done
}

# fetch_file URL SHA256 DEST: downloads URL to DEST once and verifies it
fetch_file() {
    local url=$1 sha=$2 dest=$3
    mkdir -p "$(dirname "$dest")"
    [[ -f $dest ]] || curl -fsSL -o "$dest" "$url"
    echo "$sha  $dest" | sha256sum -c --quiet
}

# stage_dir ID: empty stage tree for a port, with the Puppy entry and icon directories
stage_dir() {
    local stage=$BUILD_DIR/$1/stage
    rm -rf "$stage"
    mkdir -p "$stage/ports/$1" "$stage/.local/share/applications" "$stage/.local/share/icons"
    echo "$stage"
}
