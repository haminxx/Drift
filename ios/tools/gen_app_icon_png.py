#!/usr/bin/env python3
"""Write minimal solid-color 1024x1024 RGBA PNGs for AppIcon placeholders."""
from __future__ import annotations

import os
import struct
import zlib


def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_solid_png(path: str, w: int, h: int, r: int, g: int, b: int, a: int = 255) -> None:
    pixel = bytes([r, g, b, a])
    raw = b"".join(b"\x00" + pixel * w for _ in range(h))
    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack(">II", w, h) + b"\x08\x06\x00\x00\x00"
    png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", compressed) + _chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ios_dir = os.path.dirname(script_dir)
    paths = [
        os.path.join(ios_dir, "Drift", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"),
        os.path.join(ios_dir, "Drift Watch App", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"),
    ]
    for p in paths:
        write_solid_png(p, 1024, 1024, 45, 120, 200)
        print("Wrote", p, os.path.getsize(p), "bytes")


if __name__ == "__main__":
    main()
