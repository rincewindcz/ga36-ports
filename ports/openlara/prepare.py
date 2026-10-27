#!/usr/bin/env python3
"""Stages your own Tomb Raider (PC) data for OpenLara on the GA36-MB.

  prepare.py SOURCE [OUT]

SOURCE is one of:
  - an installed game folder with DATA/ (and FMV/), e.g. from GOG or Steam
  - a CD image: .cue with its .bin (DOSBox store releases may name them
    GAME.DAT and GAME.GOG), or a Nero .nrg
  - a .zip or .7z holding any of the above

OUT (default ./openlara-data) receives ports/openlara/DATA, FMV and audio/1;
copy its ports folder into the HOME root of the console. CD audio tracks
become audio/1/track_NN.ogg, numbered as on the disc. Needs 7z and, for CD
audio, ffmpeg.
"""

import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

RAW = 2352
COOKED = 2048
SYNC_HEADER = 16


def die(message):
    sys.exit(f"prepare.py: {message}")


def run(*args):
    try:
        subprocess.run(args, check=True, stdout=subprocess.DEVNULL)
    except FileNotFoundError:
        die(f"{args[0]} not found, install it first")


def find(root, pattern):
    return sorted(p for p in root.rglob("*") if re.fullmatch(pattern, p.name, re.IGNORECASE))


CUE_FILE = re.compile(r'^\s*FILE\s+.+\s+(BINARY|MOTOROLA)\s*$', re.IGNORECASE | re.MULTILINE)


def is_cue_sheet(path):
    """.cue files, and cue sheets under other names (DOSBox store releases may use GAME.DAT)."""
    if not path.is_file() or path.stat().st_size > 65536:
        return False
    if path.suffix.lower() == ".cue":
        return True
    if path.suffix.lower() not in (".dat", ".inst"):
        return False
    text = path.read_bytes().decode("latin-1")
    return bool(CUE_FILE.search(text) and re.search(r"^\s*TRACK\s", text, re.IGNORECASE | re.MULTILINE))


def level1(root):
    hits = [p for p in find(root, r"level1\.phd") if p.parent.name.lower() == "data"]
    return hits[0].parent.parent if hits else None


def nrg_tracks(path):
    """(number, sector size, start, end) per track, offsets in bytes."""
    with open(path, "rb") as f:
        f.seek(-12, 2)
        tail = f.read(12)
        if tail[:4] == b"NER5":
            offset, wide = struct.unpack(">Q", tail[4:])[0], True
        else:
            f.seek(-8, 2)
            tail = f.read(8)
            if tail[:4] != b"NERO":
                die(f"{path.name}: not a Nero image")
            offset, wide = struct.unpack(">I", tail[4:])[0], False
        f.seek(offset)
        while True:
            chunk, size = struct.unpack(">4sI", f.read(8))
            data = f.read(size)
            if chunk in (b"DAOX", b"DAOI"):
                break
            if chunk == b"END!":
                die(f"{path.name}: no track table")
    first = data[20]
    entry = 42 if wide else 30
    tracks = []
    for i, p in enumerate(range(22, len(data) - entry + 1, entry)):
        sector, = struct.unpack(">H", data[p + 12:p + 14])
        if wide:
            start, end = struct.unpack(">QQ", data[p + 26:p + 42])
        else:
            start, end = struct.unpack(">II", data[p + 22:p + 30])
        tracks.append((first + i, sector, start, end))
    return [(path, number, sector, start, end) for number, sector, start, end in tracks]


def msf(text):
    m, s, f = (int(x) for x in text.split(":"))
    return (m * 60 + s) * 75 + f


def cue_tracks(path):
    """(bin file, number, sector size, start, end) per track, offsets in bytes."""
    entries = []
    current = None
    for line in path.read_text(errors="replace").splitlines():
        words = line.split()
        if not words:
            continue
        keyword = words[0].upper()
        if keyword == "FILE":
            name = re.match(r'\s*FILE\s+"?(.*?)"?\s+\w+\s*$', line, re.IGNORECASE).group(1)
            matches = [p for p in path.parent.iterdir() if p.name.lower() == Path(name).name.lower()]
            if not matches:
                die(f"{path.name}: {name} not found next to it")
            current = matches[0]
        elif keyword == "TRACK":
            mode = words[2].upper()
            entries.append({"file": current, "number": int(words[1]), "mode": mode,
                            "size": COOKED if mode.endswith("/2048") else RAW})
        elif keyword == "INDEX" and entries:
            entries[-1].setdefault("index", {})[int(words[1])] = msf(words[2])
    tracks = []
    for i, t in enumerate(entries):
        start = t["index"][1] * t["size"]
        nxt = entries[i + 1] if i + 1 < len(entries) else None
        if nxt and nxt["file"] == t["file"]:
            end = nxt["index"].get(0, nxt["index"][1]) * nxt["size"]
        else:
            end = t["file"].stat().st_size
        size = COOKED if t["mode"] == "MODE1/2048" else RAW if t["mode"] == "AUDIO" else -RAW
        tracks.append((t["file"], t["number"], size, start, end))
    return tracks


def copy_range(src, dst, start, end, sector=None):
    """Copies [start, end) of src; with sector=RAW, only the 2048 data bytes of each MODE1 sector."""
    with open(src, "rb") as f, open(dst, "wb") as out:
        f.seek(start)
        left = end - start
        while left > 0:
            if sector:
                block = f.read(min(left, sector))
                left -= len(block)
                out.write(block[SYNC_HEADER:SYNC_HEADER + COOKED])
            else:
                block = f.read(min(left, 1 << 20))
                left -= len(block)
                out.write(block)
            if not block:
                break


def from_image(tracks, work, game):
    """tracks: (file, number, size, start, end); size 2048 data, 2352 audio, -2352 raw MODE1 data."""
    iso = None
    audio = game / "audio" / "1"
    for src, number, size, start, end in tracks:
        if size in (COOKED, -RAW) and iso is None:
            iso = work / "data.iso"
            copy_range(src, iso, start, end, RAW if size == -RAW else None)
        elif size == RAW:
            audio.mkdir(parents=True, exist_ok=True)
            pcm = work / f"track_{number:02d}.raw"
            copy_range(src, pcm, start, end)
            run("ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "s16le", "-ar", "44100", "-ac", "2",
                "-i", str(pcm), "-c:a", "libvorbis", "-q:a", "4", str(audio / f"track_{number:02d}.ogg"))
            pcm.unlink()
    if iso is None:
        die("the image has no data track")
    unpacked = work / "iso"
    run("7z", "x", "-y", f"-o{unpacked}", str(iso))
    iso.unlink()
    return unpacked


def stage(source, out):
    game = out / "ports" / "openlara"
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        if source.is_file() and source.suffix.lower() in (".zip", ".7z"):
            run("7z", "x", "-y", f"-o{work / 'archive'}", str(source))
            source = work / "archive"
        root = None
        if source.is_dir():
            images = [p for p in sorted(source.rglob("*")) if is_cue_sheet(p)] or find(source, r".*\.nrg")
            if images:
                source = images[0]
            else:
                root = level1(source)
                if root is None:
                    die("no DATA/LEVEL1.PHD and no CD image found")
        if root is None:
            suffix = source.suffix.lower()
            if suffix == ".nrg":
                tracks = nrg_tracks(source)
            elif is_cue_sheet(source):
                tracks = cue_tracks(source)
            else:
                die(f"{source.name}: expected a folder, .cue, .nrg, .zip or .7z")
            game.mkdir(parents=True, exist_ok=True)
            root = level1(from_image(tracks, work, game))
            if root is None:
                die("the disc has no DATA/LEVEL1.PHD")
        for name in ("DATA", "FMV", "audio"):
            src = next((p for p in root.iterdir() if p.is_dir() and p.name.lower() == name.lower()), None)
            if src:
                shutil.copytree(src, game / name, dirs_exist_ok=True)
    if not (game / "DATA").is_dir():
        die("DATA was not staged")
    return game


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__.strip())
    source = Path(sys.argv[1]).expanduser().resolve()
    out = Path(sys.argv[2] if len(sys.argv) == 3 else "openlara-data").expanduser().resolve()
    if not source.exists():
        die(f"{source} not found")
    game = stage(source, out)
    for path in sorted(game.iterdir()):
        files = [p for p in path.rglob("*") if p.is_file()]
        print(f"{path.relative_to(out)}: {len(files)} files, {sum(p.stat().st_size for p in files) >> 20} MB")
    print(f"Copy {out / 'ports'} into the HOME root of the console.")


if __name__ == "__main__":
    main()
