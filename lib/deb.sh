# Debian armhf package fetching with signature and checksum verification.
# Sourced after env.sh. deb_index once, then deb_fetch <package> <destdir>.

deb_cache=$DL_DIR/debs
deb_keyring=/usr/share/keyrings/debian-archive-keyring.gpg

deb_index() {
    mkdir -p "$deb_cache"
    curl -fsSL -o "$deb_cache/InRelease" "$DEBIAN_MIRROR/dists/$DEBIAN_SUITE/InRelease"
    if [[ -r $deb_keyring ]]; then
        gpgv --keyring "$deb_keyring" "$deb_cache/InRelease"
    else
        echo "warning: $deb_keyring missing, Release signature not verified" >&2
    fi
    curl -fsSL -o "$deb_cache/Packages.xz" "$DEBIAN_MIRROR/dists/$DEBIAN_SUITE/main/binary-armhf/Packages.xz"
    local want
    want=$(awk '/SHA256:/{f=1;next} /^[A-Z]/{f=0} f && $3=="main/binary-armhf/Packages.xz"{print $1}' "$deb_cache/InRelease")
    (cd "$deb_cache" && echo "$want  Packages.xz" | sha256sum -c --quiet)
}

deb_fetch() {
    local pkg=$1 dest=$2 file sha deb tmp
    read -r file sha < <(xz -dc "$deb_cache/Packages.xz" | awk -v p="$pkg" '
        $1=="Package:"{cur=$2} cur==p && $1=="Filename:"{f=$2} cur==p && $1=="SHA256:"{print f, $2; exit}')
    [[ -n $file ]] || { echo "package $pkg not found" >&2; return 1; }
    deb=$deb_cache/$(basename "$file")
    [[ -f $deb ]] || curl -fsSL -o "$deb" "$DEBIAN_MIRROR/$file"
    echo "$sha  $deb" | sha256sum -c --quiet
    tmp=$(mktemp -d)
    (cd "$tmp" && ar x "$deb" && tar -xf data.tar.* -C "$dest")
    rm -rf "$tmp"
}

# deb_notice PKG ROOT DEST: copies the copyright file of PKG, unpacked under
# ROOT, to DEST/PKG.txt and records the package version in DEST/SOURCES.txt
# (the matching Debian source package is the corresponding source)
deb_notice() {
    local pkg=$1 root=$2 dest=$3 version
    version=$(xz -dc "$deb_cache/Packages.xz" | awk -v p="$pkg" '
        $1=="Package:"{cur=$2} cur==p && $1=="Version:" && v==""{v=$2} END{print v}')
    mkdir -p "$dest"
    cp -L "$root/usr/share/doc/$pkg/copyright" "$dest/$pkg.txt"
    [[ -f $dest/SOURCES.txt ]] || printf 'Debian %s armhf binary packages, sources at https://snapshot.debian.org/\n\n' "$DEBIAN_SUITE" > "$dest/SOURCES.txt"
    grep -qx "$pkg $version" "$dest/SOURCES.txt" || echo "$pkg $version" >> "$dest/SOURCES.txt"
}
