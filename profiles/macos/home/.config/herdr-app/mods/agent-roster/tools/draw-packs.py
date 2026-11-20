# Draws the agent roster's themed packs: 16x12 characters as
# crisp-edged SVGs in ../art/<pack>, each one's lit pixels ('e') as <sprite>-eye.svg, and
# the pack's header emblem.svg.
# Usage: python3 draw-packs.py [preview-folder]   (writes art-<pack>.png sheets there)
import sys, struct, zlib, pathlib
root = pathlib.Path(__file__).resolve().parent.parent / "art"
previews = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
PACKS = {
 "witcher": {
  "bg": "#0b0f12", "status": ["#e0b85f", "#d75f4f", "#8fcf4f"],
  "pal": {"h": "#e8e4d8", "l": "#c1bbaa", "s": "#9a948a", "d": "#5e5a52", "k": "#1b2428", "e": "#0b0f12",
          "a": "#d89a2b", "r": "#b84a42"},
  "sprites": {
   "wolf": ["..l..........l..", ".lsl........lsl.", ".lssl......lssl.", ".lsssllllllsssl.",
            "..lssssssssssl..", "..lseesssseesl..", "...lssshhsssl...", "...lsddhhddsl...",
            "....lsdhhdsl....", "....ldkkkkdl....", ".....lhkkhl.....", "......lddl......"],
   "cat":  ["..l..........l..", "..ll........ll..", "..lsl......lsl..", "..lssllllllssl..",
            ".lssssssssssssl.", ".lsseesssseessl.", ".lsssssddsssssl.", "h.lssssddssssl.h",
            ".h.lssskksssl.h.", "...lssssssssl...", "....llssssll....", "......llll......"],
   "griffin": ["...ll......ll...", "..lsl......lsl..", "..lssl....lssl..", "..lsssllllsssl..",
            ".lssssssssssssl.", ".lsseesssseessl.", ".lssssaaaassssl.", "..lsssaaaasssl..",
            "...lssaaaassl...", "....lsdaadsl....", ".....lsaasl.....", ".......aa......."],
   "viper": ["....llllllll....", "...lssssssssl...", "..lssshhhhsssl..", ".leessddddsseel.",
            ".lssssshhsssssl.", "..lssddssddssl..", "...lssssssssl...", "....lsshhssl....",
            ".....lsddsl.....", "......lssl......", "......hkkh......", "......r..r......"],
   "bear": ["..ll........ll..", ".lssl......lssl.", ".lsdsllllllsdsl.", "..lssssssssssl..",
            ".lssssssssssssl.", ".lsseesssseessl.", ".lssssshhsssssl.", "..lssshhhhsssl..",
            "..lsssdkkdsssl..", "...lsshhhhssl...", "....lssssssl....", ".....llllll....."],
  },
  "emblem": '<path d="M12 1l1.6 3v11h-3.2V4z M6 15h12v2.2H6z M10.9 17.2h2.2v3.6h-2.2z"/><circle cx="12" cy="22" r="1.6"/>',
 },
 "hallownest": {
  "bg": "#0d0d14", "status": ["#f0dc8a", "#d95f74", "#8ae6d0"],
  "pal": {"w": "#f4f1ff", "p": "#c8c3e0", "e": "#0d0d14", "c": "#3a3a56", "b": "#55557a",
          "r": "#c62828", "R": "#8a1c1c", "x": "#7a9ab8", "X": "#55708c", "k": "#6f6a8f",
          "g": "#a8d8b8", "G": "#6a9a80", "n": "#5a5670", "N": "#8a86a8", "q": "#1e1e2c"},
  "sprites": {
   "knight": ["....w......w....", "....w......w....", "....ww....ww....", ".....wwwwww.....",
            "....wwwwwwwp....", "....weewweep....", "....weewweep....", "....weewweew....",
            ".....wwwwwp.....", "....cccccccc....", "...cccbbbbccc...", "...cc.cccc.cc..."],
   "hornet": [".....w....w.....", ".....ww..ww.....", "......wwww......", "....wwwwwwww....",
            "....weewweew....", "....weewweep....", ".....wwwwwp.....", "...rrrrrrrrrr...",
            "..rrrRRrrRRrrr..", "..rrRRrrrrRRrr..", "...rrrrrrrrrr...", "....rr.rr.rr...."],
   "quirrel": ["................", "......pppp......", ".....wwwwww.....", "....wwwwkwww....",
            "....wwwwwkwp....", "....weewweep....", "....weewweep....", ".....wwwwwp.....",
            "....xxxxxxxx....", "...xxxXXXXxxx...", "...xxxxxxxxxx...", "....xx....xx...."],
   "grub": ["................", "......gggg......", "....gggggggg....", "...gggggggggg...",
            "..ggeeggggeegg..", "..ggeeggggeegg..", "..ggggqggqgggg..", "..gggggqqggggg..",
            "...GggggggggG...", "....GGggggGG....", ".....GGGGGG.....", "................"],
   "husk": ["................", ".....nnnnnn.....", "...nnNNNNNNnn...", "..nNNNNNNNNNNn..",
            "..nnnnnnnnnnnn..", "...qqeeqqeeqq...", "...qqeeqqeeqq...", "....qqqqqqqq....",
            "...nnnnnnnnnn...", "..nnNNnnnnNNnn..", "..nn.nnnnnn.nn..", "...n..n..n..n..."],
  },
  "emblem": '<path fill-rule="evenodd" d="M5 1.5c.2 4.5 1.4 7 3.4 8.2C6.9 11 6 13 6 15.5 6 19.6 8.7 22.5 12 22.5s6-2.9 6-7c0-2.5-.9-4.5-2.4-5.8 2-1.2 3.2-3.7 3.4-8.2l-1.3.2c-.4 3.6-1.6 5.6-3.4 6.4h-4.6C7.9 7.3 6.7 5.3 6.3 1.7z M7.6 15.5a1.6 2.4 0 1 0 3.2 0a1.6 2.4 0 1 0 -3.2 0z M13.2 15.5a1.6 2.4 0 1 0 3.2 0a1.6 2.4 0 1 0 -3.2 0z"/>',
 },
 "outlaws": {
  "bg": "#1a1410", "status": ["#e0a040", "#c84a3c", "#8aaa4a"],
  "pal": {"H": "#6b5a48", "h": "#2e2620", "b": "#2a201a", "f": "#c8a07a", "F": "#a07850", "e": "#1a1410",
          "B": "#6b5040", "m": "#4a3426", "r": "#a8382a", "R": "#7a2a20", "u": "#8a6e50", "U": "#5e4a36",
          "y": "#d8b878", "Y": "#a08048", "w": "#e4d8c2", "c": "#5a4636"},
  "sprites": {
   "gunslinger": ["....HHHHHHHH....", "....HHHHHHHH....", "....bbbbbbbb....", ".HHHHHHHHHHHHHH.",
            "....ffffffff....", "....feeffeef....", "....fffFFfff....", "....BffffffB....",
            "....BBmmmmBB....", ".....BBBBBB.....", "..cccwwwwwwccc..", ".cccccwwwwccccc."],
   "sharpshooter": ["................", ".....hhhhhh.....", ".....bbbbbb.....", "hhhhhhhhhhhhhhhh",
            "....ffffffff....", "....feeffeef....", "....rrrrrrrr....", "....rrRrrRrr....",
            ".....rrRRrr.....", "......rRRr......", "..cccwwwwwwccc..", ".cccccwwwwccccc."],
   "bounty-hunter": ["................", "......hhhh......", ".....hhhhhh.....", ".....hhhhhh.....",
            "...hhbbbbbbhh...", "....ffffffff....", "....feeffeef....", "....fffFFfff....",
            "...mmmmmmmmmm...", ".....ffmmff.....", "..cccwwwwwwccc..", ".cccccwrrwccccc."],
   "trapper": ["......uuuu......", "....uuUUUUuu....", "...uuuuuuuuuuU..", "...UUUUUUUUUUuU.",
            "....ffffffff.uU.", "....feeffeef.Uu.", "....BffFFffB..U.", "...BBBffffBBB...",
            "...BBBBmmBBBB...", "....BBBBBBBB....", "..uuuwwwwwwuuu..", ".uuuuuwwwwuuuuu."],
   "drifter": ["................", ".....yyyyyy.....", ".....YYYYYY.....", ".yyyyyyyyyyyyyy.",
            "....ffffffff....", "....feeffeef....", "....fffFFfff....", "....ffffffff....",
            ".....fFmmFf.....", "......ffff......", "..cccrrrrrrccc..", ".cccccrRRrccccc."],
  },
  "emblem": '<path d="M4.5 2h5v10.5a2.5 2.5 0 0 0 5 0V2h5v10.5a7.5 7.5 0 0 1-15 0z"/>',
 },
 "mandalorian": {
  "bg": "#0a0a0f", "status": ["#e8c070", "#e85858", "#78c878"],
  "pal": {"s": "#7888a8", "h": "#c8c8d6", "d": "#39455d", "e": "#0a0a0f",
          "b": "#2d84a8", "w": "#e4e4ec", "g": "#78c878", "G": "#589858", "a": "#c09848"},
  "sprites": {
   "mando": ["....ssssssss....", "...sshhhhhhss...", "..sshhhhhhsss...", "..shhhhhssssss..", "..seeeeeeeeees..", "..ssssseesssss..",
            "..shhsseesssss..", "..shssseessdds..", "...dssseessdd...", "....ssseesss....", "..ddssddddssdd..", ".ddssddddddssdd."],
   "bo-katan": [".....bbbbbb.....", "....bbwwwwbb....", "...bbwwbbwwbb...", "..bbbwwbbwwbbb..", "..bbeewwwweebb..", "..bbbeewweebb...",
            "..bbwwweewwbbb..", "..bgwwweewwggb..", "...bgwweewgbb...", "....bgweewgb....", "...ddbbbbbbdd...", "..ddbbddddbbdd.."],
   "ig-11": ["......dddd......", ".....dssssd.....", ".....seesss.....", ".....sssess.....", ".....dssssd.....", "......ssss......",
            "......dssd......", ".....daaaad.....", "...ddsaaaasdd...", "..dd.dssssd.dd..", "..s..ddssdd..s..", ".....ds..sd....."],
   "grogu": [".......gg.......", ".....gggggg.....", "ggg.gggggggg.ggg", ".GggggggggggggG.", "..GGggeeggeeGG..", "....gggggggg....",
            ".....ggGGgg.....", ".....aaGGaa.....", "...aaaaaaaaaa...", "...aaddddaaa....", "....aaaaaaa.....", ".....dddddd....."],
   "armorer": [".....aaaaaa.....", "...a.aaaaaa.a...", "...aaaaaaaaaa...", "..aawwaaaawwaa..", "..aaeeeeeeeeaa..", "..aaaddaaddaaa..",
            "..aadddeeddaaa..", "...adadeeadaa...", "....aadeeda.....", "...ddaaaaaadd...", "..ddaaddddaadd..", ".dddaddddddaddd."],
  },
  "emblem": '<path fill-rule="evenodd" d="M12 2a8 8 0 0 1 8 8v8l-5 4H9l-5-4v-8a8 8 0 0 1 8-8zM6 10v3h4.5v7h3v-7H18v-3z"/>',
 },
}
def svg(rows, pal, only=None):
    rects = []
    for y, row in enumerate(rows):
        assert len(row) == 16, (row, len(row))
        x = 0
        while x < 16:
            ch = row[x]; n = 1
            while x + n < 16 and row[x + n] == ch: n += 1
            if ch != "." and (only is None or ch == only):
                rects.append(f'<rect x="{x}" y="{y}" width="{n}" height="1" fill="{"#000000" if only else pal[ch]}"/>')
            x += n
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 12" width="16" height="12" shape-rendering="crispEdges">\n'
            + "\n".join(rects) + "\n</svg>\n")
hexrgb = lambda h: tuple(int(h[i:i+2], 16) for i in (1, 3, 5))
for pack, P in PACKS.items():
    out = root / pack; out.mkdir(parents=True, exist_ok=True)
    for name, rows in P["sprites"].items():
        assert len(rows) == 12, (pack, name)
        (out / f"{name}.svg").write_text(svg(rows, P["pal"]))
        (out / f"{name}-eye.svg").write_text(svg(rows, P["pal"], only="e"))
    (out / "emblem.svg").write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">{P["emblem"]}</svg>\n')
    if previews is None:
        print(pack, "drawn"); continue
    states = P["status"] + [None]; K, PAD = 8, 18
    W = PAD + 4 * (16 * K + PAD); H = PAD + len(P["sprites"]) * (12 * K + PAD)
    bg = hexrgb(P["bg"]); img = [[bg] * W for _ in range(H)]
    for r, rows in enumerate(P["sprites"].values()):
        for c, st in enumerate(states):
            ox = PAD + c * (16 * K + PAD); oy = PAD + r * (12 * K + PAD)
            for y, row in enumerate(rows):
                for x, ch in enumerate(row):
                    if ch == ".": continue
                    col = hexrgb(st if (ch == "e" and st) else P["pal"][ch])
                    if st is None: col = tuple(int(v * 0.45 + b * 0.55) for v, b in zip(col, bg))
                    for yy in range(K):
                        line = img[oy + y * K + yy]
                        for xx in range(K): line[ox + x * K + xx] = col
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in img)
    ck = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))
    (previews / f"art-{pack}.png").write_bytes(b"\x89PNG\r\n\x1a\n" + ck(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)) + ck(b"IDAT", zlib.compress(raw)) + ck(b"IEND", b""))
    print(pack, sorted(p.name for p in out.iterdir() if not p.name.endswith("-eye.svg")))
