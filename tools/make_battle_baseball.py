#!/usr/bin/env python3
"""Draws website/images/battle-baseball.svg: Battle Baseball's name as the
owner's picture has it (#116; battle-baseball-military-300dpi.png, 2700 x
1131): BATTLE in Lilita One, cream, over BASEBALL in Black Ops One, coral,
each letter in a thick ink outline, on a hard ink shadow down and to the
right. The letters are the fonts' own outlines (both SIL OFL), placed where
the picture has them, so the page needs neither font and the file is 4 KB.

Lilita One is the app's (assets/fonts/lilita_one/). Black Ops One left the
app with the stencil change of 2026-11-22, so give its file; the repo's
history has it:

  git show 15cdd966^:tools/fonts/BlackOpsOne-Regular.ttf > /tmp/BlackOpsOne-Regular.ttf
  python3 -m venv /tmp/venv && /tmp/venv/bin/pip install fonttools==4.68.0
  /tmp/venv/bin/python tools/make_battle_baseball.py /tmp/BlackOpsOne-Regular.ttf

The same fonts give the same file on every run.
"""
import pathlib
import sys

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
lilita = str(ROOT / "assets/fonts/lilita_one/LilitaOne-Regular.ttf")
blackops = sys.argv[1]
out = str(ROOT / "website/images/battle-baseball.svg")

# The picture, measured: the cream letters' box, the coral letters' box, the
# outline's width, and how far the shadow reaches past the outline.
W, H = 2700, 1131
CREAM_BOX = (56, 56, 2623, 612)
CORAL_BOX = (122, 731, 2557, 1007)
OUTLINE = 29
SHADOW = (20, 67)
CREAM, CORAL, INK = "#F4EAD0", "#F45B5B", "#1A1A18"


def kerning(font, left, right):
    """The pair's kerning from the font's GPOS, if it has a simple one."""
    gpos = font.get("GPOS")
    if gpos is None:
        return 0
    for lookup in gpos.table.LookupList.Lookup:
        for sub in lookup.SubTable:
            if getattr(sub, "ExtensionLookupType", None):
                sub = sub.ExtSubTable
            if sub.LookupType != 2:
                continue
            if sub.Format == 1:
                if left in sub.Coverage.glyphs:
                    for rec in sub.PairSet[sub.Coverage.glyphs.index(left)].PairValueRecord:
                        if rec.SecondGlyph == right and rec.Value1 is not None:
                            return rec.Value1.XAdvance or 0
            elif sub.Format == 2 and left in sub.Coverage.glyphs:
                c1 = sub.ClassDef1.classDefs.get(left, 0)
                c2 = sub.ClassDef2.classDefs.get(right, 0)
                v = sub.Class1Record[c1].Class2Record[c2].Value1
                if v is not None and v.XAdvance:
                    return v.XAdvance
    return 0


def line(path, text, box):
    """[text]'s outlines as one SVG path, fitted to [box] (font units, y up,
    to picture pixels, y down)."""
    font = TTFont(path)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    names = [cmap[ord(ch)] for ch in text]
    xs, x = [], 0
    for i, name in enumerate(names):
        if i:
            x += kerning(font, names[i - 1], name)
        xs.append(x)
        x += glyphs[name].width
    def box_of(track):
        pen = BoundsPen(glyphs)
        for i, (name, gx) in enumerate(zip(names, xs)):
            glyphs[name].draw(TransformPen(pen, (1, 0, 0, 1, gx + i * track, 0)))
        return pen.bounds

    # One scale for both directions, from the letters' height, and the same
    # extra space after every letter so the line is as wide as the picture's
    # (its letters are spaced out, not stretched).
    x0, y0, x1, y1 = box_of(0)
    bx0, by0, bx1, by1 = box
    scale = (by1 - by0) / (y1 - y0)
    track = ((bx1 - bx0) / scale - (x1 - x0)) / (len(names) - 1)
    x0, y0, x1, y1 = box_of(track)
    print(f"{text}: scale {scale:.4f}, {track:.0f} font units ({track * scale:.1f} px) between letters", file=sys.stderr)
    pen = SVGPathPen(glyphs, ntos=lambda v: ("%.1f" % v).rstrip("0").rstrip("."))
    for i, (name, gx) in enumerate(zip(names, xs)):
        glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, bx0 + (gx + i * track - x0) * scale, by1 + y0 * scale)))
    return pen.getCommands()


battle = line(lilita, "BATTLE", CREAM_BOX)
baseball = line(blackops, "BASEBALL", CORAL_BOX)
steps = 8
shadow = "".join(
    f'<use href="#o" transform="translate({SHADOW[0] * i / steps:.1f} {SHADOW[1] * i / steps:.1f})"/>'
    for i in range(1, steps + 1)
)
svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<!-- Battle Baseball's name as the owner's picture has it (#116): BATTLE in Lilita One over BASEBALL in Black Ops One (both SIL OFL), the fonts' own outlines, in an ink outline on a hard ink shadow. Made by tools/make_battle_baseball.py from the picture's measurements. -->
<defs><g id="o" fill="{INK}" stroke="{INK}" stroke-width="{OUTLINE * 2}" stroke-linejoin="round"><path id="a" d="{battle}"/><path id="b" d="{baseball}"/></g></defs>
{shadow}
<use href="#o"/>
<use href="#a" fill="{CREAM}"/>
<use href="#b" fill="{CORAL}"/>
</svg>
"""
open(out, "w").write(svg)
print(len(svg), "bytes", file=sys.stderr)
