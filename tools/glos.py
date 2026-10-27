#!/usr/bin/env python3
"""goodluckOS over the USB serial console (ttyACM, root/root).

  glos.py sh COMMAND...           run a shell command, print its output, exit with its status
  glos.py push LOCAL... REMOTE    copy files into the directory REMOTE (created if missing),
                                  verified with md5sum

Options: --port /dev/ttyACM0, --timeout S (per command).
"""
import argparse
import base64
import hashlib
import re
import sys
import time
import uuid
from pathlib import Path

import serial

LOGIN    = re.compile(rb"login: $")
PASSWORD = re.compile(rb"Password: $")
PROMPT   = re.compile(rb"[#$] $")
WRITE    = 4096                    # bytes per serial write while streaming a file


class Console:
    def __init__(self, port, timeout):
        self.port = serial.Serial(port, 115200, timeout=0.2)
        self.timeout = timeout
        self._login()

    def _read_until(self, patterns, timeout):
        data = b""
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            data += self.port.read(4096)
            for i, pattern in enumerate(patterns):
                if pattern.search(data):
                    return i
        return None

    def _login(self):
        self.port.write(b"\n")
        for _ in range(4):
            which = self._read_until([LOGIN, PASSWORD, PROMPT], 5)
            if which == 2:
                self.port.write(b"stty -echo\n")
                self._read_until([PROMPT], 5)
                return
            self.port.write(b"root\n" if which in (0, 1) else b"\n")
        sys.exit("glos: no shell prompt on the console")

    def run(self, command):
        """(exit status, output) of command; the markers are split with "" so
        their literal text only appears in the output, never in an echo."""
        self.port.reset_input_buffer()
        tag = uuid.uuid4().hex[:8]
        self.port.write(f'echo __b""{tag}__; {command}; echo __e""{tag}__ $?\n'.encode())
        begin = f"__b{tag}__".encode()
        done = re.compile(re.escape(f"__e{tag}__").encode() + rb" (\d+)\r?\n")
        data = b""
        end = time.monotonic() + self.timeout
        while time.monotonic() < end:
            data += self.port.read(4096)
            match = done.search(data)
            if match:
                start = data.find(begin)
                body = data[start + len(begin):match.start()] if start >= 0 else data[:match.start()]
                return int(match.group(1)), body.decode(errors="replace").replace("\r\n", "\n").lstrip("\n")
        sys.exit("glos: command timed out: " + command)

    def push(self, local, remote_dir):
        """Streams the file as base64 into `head -c | base64 -d`. Canonical mode
        is off while it reads, so the data is not bound by the tty line limit;
        the ready marker makes sure that is in effect before any data is sent."""
        data = Path(local).read_bytes()
        remote = f"{remote_dir.rstrip('/')}/{Path(local).name}"
        encoded = base64.b64encode(data)
        tag = uuid.uuid4().hex[:8]
        self.port.reset_input_buffer()
        self.port.write((f'stty -icanon; echo __r""{tag}__; head -c {len(encoded)} | base64 -d > \'{remote}\'; '
                         f's=$?; stty icanon; echo __e""{tag}__ $s\n').encode())
        if not self._wait(re.compile(re.escape(f"__r{tag}__").encode())):
            sys.exit(f"glos: push of {local}: console not ready")
        for i in range(0, len(encoded), WRITE):
            self.port.write(encoded[i:i + WRITE])
        match = self._wait(re.compile(re.escape(f"__e{tag}__").encode() + rb" (\d+)\r?\n"))
        status, out = self.run(f"md5sum '{remote}'")
        if not match or match.group(1) != b"0" or status != 0 or out.split()[0] != hashlib.md5(data).hexdigest():
            sys.exit(f"glos: push of {local} failed: {out.strip()}")
        print(f"{local} -> {remote} ({len(data)} bytes)")

    def _wait(self, pattern):
        data = b""
        end = time.monotonic() + self.timeout
        while time.monotonic() < end:
            data += self.port.read(4096)
            match = pattern.search(data)
            if match:
                return match
        return None

    def _check(self, command):
        status, out = self.run(command)
        if status != 0:
            sys.exit(f"glos: {command[:60]}... failed ({status}): {out.strip()}")


def main():
    ap = argparse.ArgumentParser(description="goodluckOS over the USB serial console.")
    ap.add_argument("--port", default="/dev/ttyACM0")
    ap.add_argument("--timeout", type=float, default=30)
    sub = ap.add_subparsers(dest="action", required=True)
    sh = sub.add_parser("sh")
    sh.add_argument("command", nargs="+")
    push = sub.add_parser("push")
    push.add_argument("files", nargs="+")
    args = ap.parse_args()

    console = Console(args.port, args.timeout)
    if args.action == "sh":
        status, out = console.run(" ".join(args.command))
        sys.stdout.write(out)
        sys.exit(status)
    *files, remote = args.files
    if not files:
        sys.exit("glos: push needs LOCAL... REMOTE")
    console._check(f"mkdir -p '{remote}'")
    for f in files:
        console.push(f, remote)


if __name__ == "__main__":
    main()
