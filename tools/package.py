#!/usr/bin/env python3
"""Checks a port's stage tree against its port.yaml and packs the release zip.

  package.py ID

Reads ports/ID/port.yaml and BUILD_DIR/ID/stage (made by ports/ID/build.sh),
writes BUILD_DIR/dist/ID-VERSION.zip for the newest release in port.yaml and
prints its size and sha256. The zip is unpacked into the HOME root of the
console, a vfat file system: no symlinks, no names that differ only in case.
"""

import hashlib
import os
import re
import subprocess
import sys
import zipfile
from datetime import date
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = Path(os.environ.get("BUILD_DIR", ROOT / "build"))
REPO_URL = "https://github.com/rincewindcz/ga36-ports"

STATUS = {"works", "playable", "wip"}
REVIEW = {"draft", "approved", "rejected"}
ACCENT = {"blue", "teal", "amber", "rose", "violet", "green", "crimson"}
KINDS = {"included", "user"}
VFAT_BAD = re.compile(r'[<>:"\\|?*\x00-\x1f]')


class Problems(list):
    def check(self, ok, message):
        if not ok:
            self.append(message)


def validate(port_id, meta, problems):
    for key in ("title", "catalog", "summary", "status", "review", "accent", "added", "icon", "engine", "data", "releases"):
        problems.check(key in meta, f"port.yaml: {key} missing")
    problems.check(isinstance(meta.get("catalog"), int) and meta["catalog"] > 0, "port.yaml: catalog must be a positive integer")
    for other in sorted((ROOT / "ports").glob("*/port.yaml")):
        if other.parent.name != port_id and yaml.safe_load(other.read_text()).get("catalog") == meta.get("catalog"):
            problems.append(f"port.yaml: catalog {meta.get('catalog')} is also used by {other.parent.name}")
    problems.check(meta.get("status") in STATUS, f"port.yaml: status must be one of {sorted(STATUS)}")
    problems.check(meta.get("review") in REVIEW, f"port.yaml: review must be one of {sorted(REVIEW)}")
    problems.check(meta.get("accent") in ACCENT, f"port.yaml: accent must be one of {sorted(ACCENT)}")
    data = meta.get("data") or {}
    problems.check(data.get("kind") in KINDS, f"port.yaml: data.kind must be one of {sorted(KINDS)}")
    if data.get("kind") == "user":
        problems.check(data.get("sources"), "port.yaml: data.sources missing for user data")
        problems.check(data.get("files"), "port.yaml: data.files missing for user data")
    releases = meta.get("releases") or []
    problems.check(releases and "version" in releases[0] and "date" in releases[0],
                   "port.yaml: the newest release needs version and date")
    script = (data.get("prepare") or {}).get("script")
    if script:
        problems.check((ROOT / "ports" / port_id / script).is_file(), f"port.yaml: prepare script {script} missing")


def puppy_paths(path):
    """COMMAND and ICON of a Puppy entry, relative to HOME."""
    fields = dict(line.split("=", 1) for line in path.read_text().splitlines() if "=" in line)
    return {key: fields[key].removeprefix("/home/player/") for key in ("COMMAND", "ICON") if key in fields}


def inspect(port_id, meta, stage, problems):
    allowed = (f"ports/{port_id}/", f".local/share/applications/{port_id}.puppy", f".local/share/icons/{port_id}.png")
    files, seen = [], {}
    for path in sorted(stage.rglob("*")):
        rel = path.relative_to(stage).as_posix()
        problems.check(not path.is_symlink(), f"{rel}: symlink (HOME is vfat)")
        problems.check(not VFAT_BAD.search(path.name), f"{rel}: name not valid on vfat")
        problems.check(rel.lower() not in seen, f"{rel}: same name as {seen.get(rel.lower())} on vfat")
        seen[rel.lower()] = rel
        if path.is_file():
            problems.check(rel.startswith(allowed[0]) or rel in allowed[1:], f"{rel}: outside the port's paths")
            files.append(rel)

    puppy = stage / allowed[1]
    if puppy.is_file():
        for key, rel in puppy_paths(puppy).items():
            target = stage / rel
            problems.check(target.is_file(), f"{port_id}.puppy: {key} {rel} not in the zip")
            if key == "COMMAND" and target.is_file():
                problems.check(os.access(target, os.X_OK), f"{rel}: not executable")
    else:
        problems.append(f"{allowed[1]} missing")

    for rel in meta.get("licenses") or []:
        problems.check((stage / rel).is_file(), f"license {rel} not in the zip")
    data = meta.get("data") or {}
    if data.get("kind") == "included" and data.get("license_file"):
        problems.check((stage / data["license_file"]).is_file(), f"data license {data['license_file']} not in the zip")
    if data.get("kind") == "user":
        for entry in data.get("files") or []:
            dest = entry["to"].rstrip("/") + "/"
            leaked = [f for f in files if f.startswith(dest)]
            problems.check(not leaked, f"game data in the zip under {dest}: {', '.join(leaked[:3])}")
    return files


def source_note(port_id, meta, version):
    try:
        commit = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "HEAD"], capture_output=True, text=True,
                                check=True).stdout.strip()
    except subprocess.CalledProcessError:
        commit = "main"
    engine = meta["engine"]
    lines = [f"{meta['title']} for the GA36-MB, release {version}", ""]
    lines.append(f"Engine: {engine['name']}, {engine.get('license', 'see LICENSE.txt')}")
    lines.append(f"Source: {engine['url']}" + (f" at commit {engine['commit']}" if engine.get("commit") else ""))
    lines.append(f"Build script, patches and launcher: {REPO_URL}/tree/{commit}/ports/{port_id}")
    lines.append("")
    return "\n".join(lines)


def pack(port_id, meta, stage, files, out):
    release = meta["releases"][0]
    when = release["date"] if isinstance(release["date"], date) else date.fromisoformat(str(release["date"]))
    stamp = (when.year, when.month, when.day, 0, 0, 0)
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        entries = {rel: stage / rel for rel in files}
        dirs = sorted({p.relative_to(stage).as_posix() + "/" for p in stage.rglob("*") if p.is_dir()})
        for rel in dirs:
            info = zipfile.ZipInfo(rel, stamp)
            info.external_attr = (0o40755 << 16) | 0x10
            z.writestr(info, b"")
        for rel in sorted(entries):
            info = zipfile.ZipInfo(rel, stamp)
            info.external_attr = (0o100755 if os.access(entries[rel], os.X_OK) else 0o100644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, entries[rel].read_bytes())
        info = zipfile.ZipInfo(f"ports/{port_id}/SOURCE.txt", stamp)
        info.external_attr = 0o100644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(info, source_note(port_id, meta, release["version"]))


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__.strip())
    port_id = sys.argv[1]
    meta_path = ROOT / "ports" / port_id / "port.yaml"
    if not meta_path.is_file():
        sys.exit(f"{meta_path} not found")
    meta = yaml.safe_load(meta_path.read_text())
    stage = BUILD_DIR / port_id / "stage"

    problems = Problems()
    validate(port_id, meta, problems)
    files = []
    if stage.is_dir():
        files = inspect(port_id, meta, stage, problems)
    else:
        problems.append(f"{stage} missing, run ports/{port_id}/build.sh")
    if problems:
        sys.exit("\n".join(f"{port_id}: {p}" for p in problems))

    version = meta["releases"][0]["version"]
    out = BUILD_DIR / "dist" / f"{port_id}-{version}.zip"
    pack(port_id, meta, stage, files, out)
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    print(f"{out}\n  size {out.stat().st_size}\n  sha256 {digest}\n  review {meta['review']}")


if __name__ == "__main__":
    main()
