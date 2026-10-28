# ga36-ports

Game ports for the GA36-MB handheld (Allwinner A23) running
[goodluckOS](https://github.com/CodeZombie/goodluckOS), published at
[ga36.genserek.net](https://ga36.genserek.net). Every port is one zip that is unpacked into the HOME root
of the console; it appears in the Ports category of [kennel](https://github.com/rincewindcz/kennel) or
Puppy.

Commercial game data is never part of a zip. Ports whose data may be shared include it; the others
ship the engine and say where to get the data legally.

## Layout

| Path | Content |
|---|---|
| `ports/<id>/port.yaml` | metadata, read by `tools/package.py` and by the website |
| `ports/<id>/index.md` | optional notes for players (known issues, tips), a short list |
| `ports/<id>/build.sh` | builds the stage tree `build/<id>/stage` (the HOME root) |
| `ports/<id>/run.sh`, `<id>.puppy`, `icon.png` | launcher, Puppy entry, 128x128 icon |
| `ports/<id>/patches/` | patches applied to the pinned upstream commit |
| `ports/<id>/prepare.py` | optional: stages the user's own game data on a PC |
| `lib/env.sh` | `BUILD_DIR`, `fetch_commit`, `apply_patches`, `fetch_file`, `stage_dir` |
| `lib/cross.sh` | clang cross build for armhf against a Debian trixie sysroot (`build/sysroot`), `cross_cmake`, `cross_pkgconfig` |
| `lib/deb.sh` | signed Debian package fetch, `deb_notice` (copyright file and version of a bundled library) |
| `lib/love-runtime.sh` | LÖVE 11.5 runtime with its libraries and license notices |
| `lib/gl4es.sh` | gl4es (OpenGL 1.x over GLES 2) |
| `tools/package.py` | checks a stage tree against `port.yaml` and packs `build/dist/<id>-<version>.zip` |
| `tools/drmshot.c`, `padd.c`, `glos.py` | on-device screenshot, virtual pad, serial console client |

## Build and package

Requirements: bash, clang, lld, llvm-strip, cmake, curl, gpgv with the Debian archive keyring, xz,
zip, Python 3 with PyYAML. Some ports need more (ImageMagick, 7-Zip).

```sh
ports/lugaru/build.sh
tools/package.py lugaru
```

`build/` holds the sysroot, source checkouts, downloads, stage trees and zips (`BUILD_DIR` moves it).
Build output goes to `build/<id>/build.log`.

`package.py` refuses a stage tree that has:

- files outside `ports/<id>/`, `.local/share/applications/<id>.puppy` and `.local/share/icons/<id>.png`;
- symlinks, names invalid on vfat, or names that differ only in case;
- a Puppy entry whose `COMMAND` or `ICON` is missing, or a `COMMAND` that is not executable;
- a missing file from `licenses` or `data.license_file`;
- any file under a `data.files[].to` path when `data.kind` is `user`.

It adds `ports/<id>/SOURCE.txt` (engine repository and commit, link to this repository) to the zip.
Entries are sorted and dated with the release date.

## port.yaml

```yaml
title: Tomb Raider
catalog: 4                # catalog number, unique, shown as GA-004; never reused
summary: One line for the list.
tags: [action, 3d]
status: playable          # works | playable | wip
review: draft             # draft | approved | rejected
accent: amber             # blue teal amber rose violet green crimson (kennel's accents)
added: 2026-10-27
icon: icon.png
engine: { name: OpenLara, url: https://github.com/XProger/OpenLara, commit: <sha>, license: BSD-2-Clause }

data:                     # kind: included
  kind: included
  license: CC-BY-SA 3.0
  credit: Wolfire Games
  license_file: ports/lugaru/CONTENT-LICENSE.txt

data:                     # kind: user
  kind: user
  sources:
    - { name: GOG, url: https://www.gog.com/..., note: "..." }
    - { name: Tyrian 2.1 (freeware), url: https://..., free: true }
  files:
    - { from: "DATA/", to: ports/openlara/DATA/ }
  prepare:                # optional
    script: prepare.py
    usage: python3 prepare.py "path/to/game"
    needs: [Python 3, 7-Zip]
    note: What the script does.

install:                  # optional extra steps, inline `code` allowed
  - Turn off X in the game options.
controls:
  - { button: dpad, action: "Move" }     # dpad A B X Y L1 R1 L2 R2 L-stick R-stick START SELECT
shots:
  - { file: shots/title.png, caption: "Title screen" }   # 640x480 from drmshot
licenses:                 # paths inside the zip
  - ports/openlara/LICENSE.txt
releases:                 # newest first
  - version: 2026.10.1
    date: 2026-10-27
    changes: [First release.]
    # file, size and sha256 are added when the zip is published
```

Quote any `action` or `from` value that contains a comma or starts with a special character.

## Screenshots

640x480 PNG from `tools/drmshot` on the console, as root. Freeze the running port while
capturing, or the shot catches a frame the GPU is still drawing:

```sh
echo 1 > /sys/fs/cgroup/appd/app/cgroup.freeze
drmshot > shot.ppm
echo 0 > /sys/fs/cgroup/appd/app/cgroup.freeze
```

## Review

Only `approved` ports are listed on the website; every port can be seen in its owner-only
`/preview/`.
`review` is the starting point: the site owner can approve or reject a port on the website side
without a commit here.
Unapproved ports are pushed like any other: the public site leaves them out.

## License

Scripts, launchers and port layers: MIT, see [LICENSE](LICENSE). Patches are under the license of
the project they apply to. Each zip carries the licenses of what it contains.
