# Draws the agent roster's Imperial pack (death-star layout): 16x12 front/top views as
# crisp-edged SVGs in ../art/imperial, plus each ship's lit pixels ('e') as <ship>-eye.svg.
# Usage: python3 draw-imperial.py [preview.png]   (the PNG shows every ship in every status)
import sys, struct, zlib, pathlib
out = pathlib.Path(__file__).resolve().parent.parent / "art" / "imperial"
preview = sys.argv[1] if len(sys.argv) > 1 else None
PAL = {"d": "#3a3a44", "s": "#6a6a74", "l": "#90909a", "h": "#b4b4bc", "c": "#7ee6e6", "e": "#16161c", "w": "#26262e", "g": "#50505a"}
SHIPS = {
  "star-destroyer": [  # Star Destroyer from above, nose right; the engines (left) glow
    ".ll.............", ".ssll...........", ".ssssll.........", "esssssssll......",
    "eshhhsssssll....", "eswcwhhhhhhhhll.", "edwwwggggggggss.", "edddddddddgg....",
    "edddddddgg......", ".ddddgg.........", ".ddgg...........", ".dg............."],
  "fighter": [  # TIE Fighter: straight wings, | o |
    ".l............l.", "ls............sl", "ls............sl", "ls....dddd....sl",
    "ls...dchhsd...sl", "lsllldseesdlllsl", "lssssdseesdssssl", "ls...dssssd...sl",
    "ls....dddd....sl", "ls............sl", "ls............sl", ".l............l."],
  "interceptor": [  # TIE Interceptor: dagger tips flared out, ) o (
    "h..............h", "lh............hl", ".ls..........sl.", "..ls..dddd..sl..",
    "..ls.dchhsd.sl..", "..lsldseesdlsl..", "..lssdseesdssl..", "..ls.dssssd.sl..",
    "..ls..dddd..sl..", ".ls..........sl.", "lh............hl", "h..............h"],
  "probe": [  # Probe droid: dome, eye band, dangling legs
    "......dddd......", "....ddsllsdd....", "...dslchhllsd...", "..dsllllllllsd..",
    "..deeeeeeeeeed..", "..dssssssssssd..", "...dddddddddd...", "....s.s..s.s....",
    "...s..s..s..s...", "...s..s..s..s...", "..s...s..s...s..", "..l...l..l...l.."],
  "shuttle": [  # Lambda shuttle: tall fin, wings folded down, cockpit below
    "................", ".......hl.......", ".......ls.......", ".......ls.......",
    "......slls......", ".....l.dd.l.....", "....l.dlld.l....", "...l.dleeld.l...",
    "..l..dssssd..l..", ".l...dddddd...l.", "l..............l", "................"],
}
def svg(rows, only=None):
    rects = []
    for y, row in enumerate(rows):
        assert len(row) == 16, (row, len(row))
        x = 0
        while x < 16:
            ch = row[x]; n = 1
            while x + n < 16 and row[x + n] == ch: n += 1
            if ch != "." and (only is None or ch == only):
                fill = "#000000" if only else PAL[ch]
                rects.append(f'<rect x="{x}" y="{y}" width="{n}" height="1" fill="{fill}"/>')
            x += n
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 12" width="16" height="12" shape-rendering="crispEdges">\n'
            + "\n".join(rects) + "\n</svg>\n")
out.mkdir(parents=True, exist_ok=True)
for name, rows in SHIPS.items():
    assert len(rows) == 12, name
    (out / f"{name}.svg").write_text(svg(rows))
    (out / f"{name}-eye.svg").write_text(svg(rows, only="e"))
# The header emblem: a plain hexagon, tinted with the theme accent at run time.
(out / "emblem.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M12 2l8.66 5v10L12 22l-8.66-5V7z M12 4.3l-6.67 3.85v7.7L12 19.7l6.67-3.85v-7.7z"/><path fill="currentColor" d="M12 8l3.46 2v4L12 16l-3.46-2v-4z"/></svg>\n')
if preview is None:
    sys.exit(0)
# preview: each ship in 4 states (cockpit amber/red/green/dim), 10x scale, on the void
STATES = ["#e0bc63", "#ef4f4f", "#79c987", None]
S, PADX, PADY = 10, 20, 20
W = (16 * S + PADX) * len(STATES) + PADX; H = (12 * S + PADY) * len(SHIPS) + PADY
hexrgb = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
img = [[hexrgb("#08080a")] * W for _ in range(H)]
for r, (name, rows) in enumerate(SHIPS.items()):
    for c, st in enumerate(STATES):
        ox = PADX + c * (16 * S + PADX); oy = PADY + r * (12 * S + PADY)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch == ".": continue
                col = hexrgb(st if (ch == "e" and st) else PAL[ch])
                if st is None:  # idle: dimmed
                    col = tuple(int(v * 0.45 + 8 * 0.55) for v in col)
                for yy in range(S):
                    line = img[oy + y * S + yy]
                    for xx in range(S): line[ox + x * S + xx] = col
raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in img)
ck = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))
open(preview, "wb").write(b"\x89PNG\r\n\x1a\n" + ck(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)) + ck(b"IDAT", zlib.compress(raw)) + ck(b"IEND", b""))
print("wrote", sorted(p.name for p in out.iterdir()), "preview", W, H)
