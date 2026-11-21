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


# ---------------------------------------------------------------------------
# Enemy portraits (48x56): card soldiers per suit, and the Queen from the prototype
# ---------------------------------------------------------------------------

SUIT_PIP = {
    "hearts": GLYPHS["\u2665"],
    "diamonds": GLYPHS["\u2666"],
    "spades": GLYPHS["\u2660"],
    "clubs": GLYPHS["\u2663"],
}

QUEEN = [
    "......c..cc..c......",
    ".....kckkcckkck.....",
    ".....kcccccccck.....",
    ".....kcrcrrcrck.....",
    "....kkkkkkkkkkkk....",
    "...kkkcccccccckkk...",
    "...kkckkcccckkckk...",
    "...kkcckcccckcckk...",
    "...kkcccccccccckk...",
    "...kkcccrrrrccckk...",
    "....kkcccccccckk....",
    ".....kkkkkkkkkk.....",
    "...kccckrrrrkccck...",
    "..kcccckrrrrkcccck..",
    "..kkkkkrrrrrrkkkkk..",
    "...krrrrrrrrrrrrk...",
    "..krrkrrrrrrrrkrrk..",
    "..krrkrrcrrcrrkrrk..",
    ".kcrkrrrrrrrrrrkrck.",
    ".kckrrrrrrrrrrrrkck.",
    "..kkrrrcrrrrcrrrkk..",
    "..krrrcccrrcccrrrk..",
    ".krrrrrcrrrrcrrrrrk.",
    ".krrrrrrrrrrrrrrrrk.",
    "krrrrrrrrrrrrrrrrrrk",
    "kkkkkkkkkkkkkkkkkkkk",
]


def card_soldier(suit: str) -> Canvas:
    k, c, r = PALETTE["k"], PALETTE["c"], PALETTE["r"]
    ink = r if suit in ("hearts", "diamonds") else k
    cv = Canvas(48, 56)
    # head peeking over the card
    cv.rect(18, 1, 12, 10, k)
    cv.rect(19, 2, 10, 9, c)
    cv.set(21, 5, k)
    cv.set(26, 5, k)
    cv.rect(22, 8, 4, 1, r)
    # spear on the right
    cv.rect(43, 4, 1, 48, k)
    cv.stamp(41, 0, [".#.", "###", ".#."], 1, r)
    # arms
    cv.rect(4, 26, 5, 1, k)
    cv.rect(39, 22, 4, 1, k)
    # the card body
    cv.rect(8, 11, 32, 40, k)
    cv.rect(9, 12, 30, 38, c)
    cv.stamp(11, 14, SUIT_PIP[suit], 1, ink)
    cv.stamp(32, 43, SUIT_PIP[suit], 1, ink)
    cv.stamp(16, 23, SUIT_PIP[suit], 3, ink)
    # legs
    cv.rect(17, 51, 2, 5, k)
    cv.rect(29, 51, 2, 5, k)
    return cv


def queen(rage: bool) -> Canvas:
    rows = QUEEN
    if rage:
        swap = {"r": "k", "k": "r"}
        rows = ["".join(swap.get(ch, ch) for ch in row) for row in rows]
    cv = Canvas(48, 56)
    cv.stamp(4, 2, rows, 2)
    return cv


# ---------------------------------------------------------------------------
# Card icons (16x16) for the hand, at the "art" paths cards.json uses
# ---------------------------------------------------------------------------

ICONS: dict[str, list[str]] = {
    "drink_me": ["....kk....", "....cc....", "...kcck...", "..kggggk..", "..kcccck..", "..kckckk..", "..kcccck..", "..kggggk..", "...kkkk..."],
    "eat_me": ["....rr....", "..kkkkkk..", ".kcccccck.", ".krrrrrrk.", ".kcccccck.", ".kckckcck.", "..kkkkkk.."],
    "teacup": ["..........", ".kkkkkk...", ".kcrrck.k.", ".kccccckk.", ".kcccck...", "..kkkk....", "kkkkkkkk.."],
    "pocket_watch": ["....kk....", "...kkkk...", "..kcccck..", ".kcccrcck.", ".kccrccck.", ".kcckccck.", ".kcccccck.", "..kcccck..", "...kkkk..."],
    "white_rabbit": [".kk..kk...", ".kc..ck...", ".kc..ck...", ".kccccck..", "kcckcckk..", "kcccccck..", ".kcrrcck..", "..kkkkk..."],
    "looking_glass": ["...kkkk...", "..kcccck..", ".kcgcccck.", ".kcgcccck.", ".kcccccck.", "..kcccck..", "...kkkk...", "....kk....", "...kkkk..."],
    "painted_rose": ["...rrr....", "..rrcrr...", ".rrcrcrr..", "..rrrrr...", "...kgk....", "....g.....", "...gg.....", "....g....."],
    "mushroom": ["..rrrrr...", ".rrcrrcr..", "rrrrrrrrr.", "rcrrrrrcr.", "kkkkkkkkk.", "...kck....", "...kck....", "..kkkkk..."],
    "croquet_swing": [".kkkkkk...", ".krrrrk...", ".kkkkkk...", "...kk.....", "...kk.....", "...kk.....", "...kk..rr.", "...kk..rr."],
    "hedgehog_shield": ["..k.k.k...", ".kkkkkkk..", "kkkkkkkck.", "kkkkkkkkcc", "kkkkkkkk..", ".k.k.k.k.."],
    "caterpillar_smoke": ["...cc.....", "..c..c....", "...cc..cc.", ".......c..c", "..gg....cc.", ".gggg......", "gggggggg...", ".k.k.k.k..."],
    "vorpal_blade": ["........c.", ".......cc.", "......cc..", ".....cc...", "....cc....", ".r.cc.....", "..rk......", ".rkr......", "rk..r....."],
    "tweedle_twins": [".kkk..kkk.", "kccck kccck", "kckck kckck", "kccck kccck", ".krk...krk.", "krrrk.krrrk", "krrrk.krrrk", ".k.k...k.k."],
    "unbirthday_gift": ["...r..r...", "....rr....", ".kkkkkkkk.", ".kccrrcck.", ".kccrrcck.", ".krrrrrrk.", ".kccrrcck.", ".kkkkkkkk."],
}


def export_icons() -> None:
    for name, rows in ICONS.items():
        rows = [row.replace(" ", ".") for row in rows]
        cv = Canvas(16, 16)
        h = len(rows)
        w = max(len(row) for row in rows)
        cv.stamp((16 - w) // 2, (16 - h) // 2, rows, 1)
        cv.save(ART / "cards" / f"{name}.png")


# ---------------------------------------------------------------------------
# Sound effects: tiny jsfxr-style synth -> 16-bit mono WAV
# ---------------------------------------------------------------------------

import math
import random
import wave

RATE = 22050


def tone(freq0: float, freq1: float, dur: float, wave_kind: str = "square", vol: float = 0.4, delay: float = 0.0) -> list[float]:
    out = [0.0] * int(delay * RATE)
    n = int(dur * RATE)
    phase = 0.0
    rng = random.Random(7)
    for i in range(n):
        t = i / n
        f = freq0 * (freq1 / freq0) ** t
        phase += f / RATE
        if wave_kind == "square":
            v = 1.0 if (phase % 1.0) < 0.5 else -1.0
        elif wave_kind == "saw":
            v = 2.0 * (phase % 1.0) - 1.0
        elif wave_kind == "triangle":
            v = 4.0 * abs((phase % 1.0) - 0.5) - 1.0
        else:  # noise
            v = rng.uniform(-1, 1)
        env = min(1.0, i / (0.005 * RATE)) * (1.0 - t) ** 1.5
        out.append(v * env * vol)
    return out


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    return [max(-1.0, min(1.0, sum(p[i] for p in parts if i < len(p)))) for i in range(n)]


def save_wav(name: str, samples: list[float]) -> None:
    path = ROOT / "game" / "audio" / f"{name}.wav"
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))


def export_sfx() -> None:
    save_wav("deal", tone(2000, 900, 0.05, "noise", 0.25))
    save_wav("hit", tone(520, 780, 0.07, "square", 0.25))
    save_wav("play", mix(tone(440, 880, 0.12, "square", 0.22), tone(660, 1320, 0.12, "triangle", 0.2, 0.03)))
    save_wav("bust", mix(tone(330, 55, 0.45, "saw", 0.35), tone(1500, 80, 0.3, "noise", 0.3)))
    save_wav("win_round", mix(tone(523, 523, 0.1, "square", 0.22), tone(784, 784, 0.16, "square", 0.22, 0.09)))
    save_wav("lose_round", mix(tone(392, 392, 0.1, "square", 0.22), tone(262, 262, 0.2, "square", 0.22, 0.09)))
    save_wav("critical", mix(*[tone(f, f, 0.09, "square", 0.18, i * 0.05) for i, f in enumerate([523, 659, 784, 1047, 1319])], tone(5000, 120, 0.4, "noise", 0.3)))
    save_wav("surprise", mix(tone(140, 110, 0.35, "saw", 0.3), tone(280, 200, 0.3, "square", 0.12)))
    save_wav("blocked", mix(tone(1200, 900, 0.08, "square", 0.2), tone(1800, 1800, 0.12, "triangle", 0.15, 0.05)))
    save_wav("victory", mix(*[tone(f, f, 0.14, "square", 0.18, i * 0.1) for i, f in enumerate([392, 523, 659, 784, 1047])]))
    save_wav("defeat", mix(*[tone(f, f * 0.98, 0.3, "triangle", 0.3, i * 0.22) for i, f in enumerate([392, 330, 262, 196])]))
    save_wav("click", tone(660, 990, 0.04, "square", 0.15))


def main() -> None:
    export_font("pixel", 1)
    export_font("pixel_big", 2)
    for suit in SUIT_PIP:
        card_soldier(suit).save(ART / "enemies" / f"{suit[:-1]}_soldier.png")
    queen(False).save(ART / "enemies" / "queen_of_hearts.png")
    queen(True).save(ART / "enemies" / "queen_of_hearts_rage.png")
    export_icons()
    export_sfx()
    print(f"art written to {ART}")


if __name__ == "__main__":
    main()
