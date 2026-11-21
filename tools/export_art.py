#!/usr/bin/env python3
"""Generates CardClash's placeholder pixel art into game/art/.

No dependencies: PNGs are written with zlib. Run from the repo root:

    python3 tools/export_art.py

Everything here is a placeholder in the 4-colour palette (red, cream, green,
black) until the designer's art lands; the designer's files simply replace
these paths.
"""

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "game" / "art"

PALETTE = {
    "k": (0x1B, 0x1A, 0x26, 255),
    "r": (0xC8, 0x32, 0x3C, 255),
    "c": (0xF2, 0xE6, 0xC9, 255),
    "g": (0x3F, 0x7D, 0x3A, 255),
    "w": (255, 255, 255, 255),
    ".": (0, 0, 0, 0),
}


# ---------------------------------------------------------------------------
# PNG writer
# ---------------------------------------------------------------------------


class Canvas:
    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.px = [(0, 0, 0, 0)] * (w * h)

    def set(self, x: int, y: int, rgba) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y * self.w + x] = rgba

    def rect(self, x: int, y: int, w: int, h: int, rgba) -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, rgba)

    def stamp(self, x: int, y: int, rows: list[str], scale: int = 1, ink=None) -> None:
        """Draw palette-string rows ('#' uses `ink`)."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == ".":
                    continue
                rgba = ink if ch == "#" else PALETTE[ch]
                self.rect(x + i * scale, y + j * scale, scale, scale, rgba)

    def save(self, path: Path) -> None:
        raw = b"".join(
            b"\x00" + b"".join(struct.pack("4B", *self.px[y * self.w + x]) for x in range(self.w)) for y in range(self.h)
        )

        def chunk(tag: bytes, data: bytes) -> bytes:
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(raw, 9))
        png += chunk(b"IEND", b"")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)


# ---------------------------------------------------------------------------
# Pixel font (3x5 glyphs) -> BMFont (.fnt + .png) that Godot imports as a FontFile
# ---------------------------------------------------------------------------

GLYPHS: dict[str, list[str]] = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", ".##", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", "..#", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "J": ["..#", "..#", "..#", "#.#", ".#."],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "Q": [".#.", "#.#", "#.#", "##.", ".##"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "Z": ["###", "..#", ".#.", "#..", "###"],
    "!": ["#", "#", "#", ".", "#"],
    "?": ["###", "..#", ".##", "...", ".#."],
    ".": [".", ".", ".", ".", "#"],
    ",": ["..", "..", "..", ".#", "#."],
    ":": [".", "#", ".", "#", "."],
    ";": ["..", ".#", "..", ".#", "#."],
    "-": ["...", "...", "###", "...", "..."],
    "+": ["...", ".#.", "###", ".#.", "..."],
    "=": ["...", "###", "...", "###", "..."],
    "*": ["...", "#.#", ".#.", "#.#", "..."],
    "/": ["..#", "..#", ".#.", "#..", "#.."],
    "'": ["#", "#", ".", ".", "."],
    '"': ["#.#", "#.#", "...", "...", "..."],
    "(": [".#", "#.", "#.", "#.", ".#"],
    ")": ["#.", ".#", ".#", ".#", "#."],
    "[": ["##", "#.", "#.", "#.", "##"],
    "]": ["##", ".#", ".#", ".#", "##"],
    "%": ["#.#", "..#", ".#.", "#..", "#.#"],
    "<": ["..#", ".#.", "#..", ".#.", "..#"],
    ">": ["#..", ".#.", "..#", ".#.", "#.."],
    "_": ["...", "...", "...", "...", "###"],
    "#": [".#.#.", "#####", ".#.#.", "#####", ".#.#."],
    "&": [".#.", "#.#", ".#.", "#.#", ".##"],
    "$": [".#.", "###", "#.#", "###", ".#."],
    "|": ["#", "#", "#", "#", "#"],
    "×": ["...", "#.#", ".#.", "#.#", "..."],  # ×
    "♥": [".#.#.", "#####", "#####", ".###.", "..#.."],  # ♥
    "♦": ["..#..", ".###.", "#####", ".###.", "..#.."],  # ♦
    "♠": ["..#..", ".###.", "#####", "..#..", ".###."],  # ♠
    "♣": [".###.", "#.#.#", "#####", "..#..", ".###."],  # ♣
}

WHITE = PALETTE["w"]


def export_font(name: str, scale: int) -> None:
    glyph_h = 5 * scale
    line_h = 8 * scale
    base = 6 * scale
    chars = list(GLYPHS)
    width = sum(len(GLYPHS[c][0]) * scale + scale for c in chars)
    canvas = Canvas(width, glyph_h)
    entries: list[str] = []
    x = 0
    regions: dict[str, tuple[int, int]] = {}
    for ch in chars:
        g = GLYPHS[ch]
        w = len(g[0]) * scale
        canvas.stamp(x, 0, g, scale, WHITE)
        regions[ch] = (x, w)
        x += w + scale

    def char_line(code: int, ch: str) -> str:
        gx, gw = regions[ch]
        return (
            f"char id={code} x={gx} y=0 width={gw} height={glyph_h} xoffset=0 yoffset={base - glyph_h} "
            f"xadvance={gw + scale} page=0 chnl=15"
        )

    entries.append(f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={3 * scale} page=0 chnl=15")
    for ch in chars:
        entries.append(char_line(ord(ch), ch))
        if ch.isalpha() and ch.isascii():
            entries.append(char_line(ord(ch.lower()), ch))  # lowercase uses the capitals

    fnt = "\n".join(
        [
            f'info face="{name}" size={line_h} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
            "padding=0,0,0,0 spacing=1,1 outline=0",
            f"common lineHeight={line_h} base={base} scaleW={canvas.w} scaleH={canvas.h} pages=1 packed=0 "
            "alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
            f'page id=0 file="{name}.png"',
            f"chars count={len(entries)}",
            *entries,
            "kernings count=0",
        ]
    )
    canvas.save(ART / "fonts" / f"{name}.png")
    (ART / "fonts" / f"{name}.fnt").write_text(fnt + "\n")


def main() -> None:
    export_font("pixel", 1)
    export_font("pixel_big", 2)
    print(f"art written to {ART}")


if __name__ == "__main__":
    main()
