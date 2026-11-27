#!/usr/bin/env python3
"""The website's color schemes (#111), from the app's own palettes.

Reads each Boot Camp Mix palette in lib/core/design/camp_palette.dart and
writes, for every scheme but Black (the website's own :root, written by
hand):

  * a block of the site's role tokens, `html[data-scheme="<value>"]`, between
    the GENERATED SCHEMES markers at the end of website/site.css, which
    a page's <html data-scheme="..."> turns on: every page's own markup
    names Army green, the site's default (#118), and website/scheme.js
    names the one a visitor tapped, for a day; and
  * website/images/camo-<value>.svg, the heroes' camouflage in the scheme's
    four camouflage colors: camo-black.svg with its four colors swapped. A
    scheme whose headers are plain in the app (CandyTouches.plainHeader:
    Royal & Yellow, #117) gets none: its heroes are the page's color under
    the page's dots, with no halftone.

It also checks the hand-written :root against the app's Black palette, and
stops if a color there has fallen out of step.

The tokens follow the app's roles: the page, the tab bar (the site's band),
panels, lettering, the trim, the bright faces, and their candy lips worked
out as Candy.lipOf does. Second lines and colored words are made to read on
what they sit on as ColorMath.readable does (CIE LCh lightness stepped until
4.5:1), so a light scheme's mustard links go darker, as the app's do.

Run from the repo root after a palette changes; the same palettes give the
same files on every run:

  python3 tools/make_web_schemes.py
"""
import colorsys
import math
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
PALETTES = ROOT / "lib/core/design/camp_palette.dart"
CSS = ROOT / "website/site.css"
CAMO = ROOT / "website/images/camo-black.svg"
BEGIN = "/* ---------- GENERATED SCHEMES (tools/make_web_schemes.py): do not edit by hand ---------- */"
END = "/* ---------- END GENERATED SCHEMES ---------- */"

# The website's value for each scheme (the stored value its picture is named
# for), the palette's name in camp_palette.dart, and its name.
SCHEMES = [
    ("army", "army", "Army green"),
    ("light", "light", "Light"),
    ("skyblue", "sky", "Sky Blue"),
    ("candypop", "royalYellow", "Royal & Yellow"),
    ("graphite", "graphite", "Graphite"),
    ("navy", "navySteel", "Navy Steel"),
    ("darkarmy", "forest", "Forest"),
    ("wildcat", "wildcat", "Central Wildcats"),
    ("purplegold", "purpleGold", "Geaux Tigahs"),
    ("deserttan", "desertTan", "Desert Tan"),
    ("sugarrush", "sugarRush", "Sugar Rush"),
]
# camo-black.svg's colors: ground, big, mid, small (Black's camouflage).
BLACK_CAMO = ["#23241F", "#161713", "#3A3C33", "#070706"]


def palettes():
    """Each palette's colors, as (a, r, g, b) in 0..255, by field, and under
    "plainHeader" whether its headers have no camouflage."""
    src = PALETTES.read_text()
    out = {}
    for m in re.finditer(r"static const (\w+) = CampPalette\((.*?)\n  \);", src, re.S):
        out[m.group(1)] = {
            f: tuple(int(v[i:i + 2], 16) for i in (0, 2, 4, 6))
            for f, v in re.findall(r"(\w+): Color\(0x([0-9A-Fa-f]{8})\)", m.group(2))
        }
        touches = re.search(r"touches: CandyTouches\.(\w+)", m.group(2))
        plain = False
        if touches:
            t = re.search(r"static const %s = CandyTouches\((.*?)\);" % touches.group(1), src, re.S)
            plain = bool(t and re.search(r"plainHeader:\s*true", t.group(1)))
        out[m.group(1)]["plainHeader"] = plain
    return out


def hex6(c):
    return "#%02x%02x%02x" % tuple(round(x) for x in c[-3:])


def rgba(c, alpha=None):
    a = c[0] / 255 if alpha is None else alpha
    return "rgba(%d, %d, %d, %s)" % (c[1], c[2], c[3], ("%.3f" % a).rstrip("0").rstrip("."))


def lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = c[-3:]
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def to_lch(c):
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(v) for v in c[-3:])
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x), f(y), f(z)
    L, A, B = 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)
    return L, math.hypot(A, B), math.atan2(B, A)


def from_lch(L, C, H):
    A, B = C * math.cos(H), C * math.sin(H)
    fy = (L + 16) / 116
    fx, fz = fy + A / 500, fy - B / 200
    inv = lambda t: t ** 3 if t ** 3 > 216 / 24389 else (116 * t - 16) / (24389 / 27)
    x, y, z = inv(fx) * 0.95047, inv(fy), inv(fz) * 1.08883
    r = 3.2406 * x - 1.5372 * y - 0.4986 * z
    g = -0.9689 * x + 1.8758 * y + 0.0415 * z
    b = 0.0557 * x - 0.2040 * y + 1.0570 * z
    gam = lambda v: 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return (255,) + tuple(max(0, min(255, round(gam(v) * 255))) for v in (r, g, b))


def readable(color, backgrounds, minimum=4.5):
    """ColorMath.readable: lighter on dark backgrounds, darker on light ones,
    by CIE LCh lightness, until it reads on every one."""
    if all(contrast(color, b) >= minimum for b in backgrounds):
        return color
    L, C, H = to_lch(color)
    up = sum(lum(b) for b in backgrounds) / len(backgrounds) < 0.18
    for step in range(1, 101):
        l = max(0.0, min(100.0, L + (step if up else -step)))
        cand = from_lch(l, C, H)
        if all(contrast(cand, b) >= minimum for b in backgrounds):
            return cand
        if l in (0.0, 100.0):
            break
    return (255, 255, 255, 255) if up else (255, 0, 0, 0)


def lip(face):
    """Candy.lipOf: the hue kept, HSL lightness x 0.66 and saturation x 0.85,
    or lightness x 0.46 under a face darker than 0.2."""
    r, g, b = (v / 255 for v in face[-3:])
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l *= 0.46 if l < 0.2 else 0.66
    s *= 0.85
    return (255,) + tuple(v * 255 for v in colorsys.hls_to_rgb(h, l, s))


def block(value, name, p):
    light_page = lum(p["page"]) > 0.18
    plain = p["plainHeader"]
    field = p["answerRow"]
    lines = [
        f'html[data-scheme="{value}"] {{',
        f"  /* {name} */",
        f"  color-scheme: {'light' if light_page else 'dark'};",
        f"  --page: {hex6(p['page'])};",
        f"  --band: {hex6(p['tabBar'])};",
        f"  --dots: {rgba(p['pageDots'])};",
        f"  --text: {hex6(p['text'])};",
        f"  --muted: {hex6(readable(p['muted'], [p['page'], p['tabBar']]))};",
        f"  --hairline: {rgba(p['text'], 0.14)};",
        f"  --outline: {rgba(p['text'], 0.3)};",
        f"  --field: {hex6(field)};",
        f"  --card: {hex6(p['panel'])};",
        f"  --rim: {hex6(p['ink'])};",
        f"  --card-muted: {hex6(readable(p['panelMuted'], [p['panel']]))};",
        f"  --drop: {hex6(p['shadow'])};",
        f"  --ink: {hex6(p['ink'])};",
        f"  --trim: {hex6(p['mustard'])};",
        f"  --trim-text: {hex6(readable(p['mustard'], [p['page'], p['tabBar'], p['panel']]))};",
        f"  --strong: {hex6(p['text'])};",
        f"  --card-text: {hex6(p['panelText'])};",
        f"  --name-filter: {'invert(1) hue-rotate(180deg)' if lum(p['tabBar']) > 0.18 else 'none'};",
        f"  --halftone: {'transparent' if plain else rgba(p['headerHalftone'])};",
        f"  --hero-text: {hex6(p['headerLettering'])};",
        f"  --hero-ground: {hex6(p['page'] if plain else p['camoGround'])};",
        "  --camo: none;" if plain else f"  --camo: url(\"/images/camo-{value}.svg\");",
        f"  --red: {hex6(p['red'])};",
        f"  --green: {hex6(p['green'])};",
        f"  --orange: {hex6(p['orange'])};",
        f"  --blue: {hex6(p['blue'])};",
        f"  --purple: {hex6(p['purple'])};",
        f"  --green-lip: {hex6(lip(p['green']))};",
        f"  --trim-lip: {hex6(lip(p['mustard']))};",
        f"  --red-lip: {hex6(lip(p['red']))};",
        f"  --orange-lip: {hex6(lip(p['orange']))};",
        f"  --purple-lip: {hex6(lip(p['purple']))};",
        f"  --card-lip: {hex6(lip(p['panel']))};",
        f"  --page-lip: {hex6(lip(p['page']))};",
        "}",
    ]
    if plain:
        # Plain headers: the page's dots on the page's color, as body has.
        lines.append(
            f'html[data-scheme="{value}"] :is(.hero, .feature-hero) '
            "{ background: radial-gradient(circle, var(--dots) 1.15px, transparent 1.45px) 0 0 / 8px 8px, var(--page); }"
        )
    return "\n".join(lines)


def check_root(black):
    """The hand-written :root is Black: its colors must be the palette's."""
    css = CSS.read_text()
    root = css[css.index(":root {"):css.index("}", css.index(":root {"))]
    want = {
        "--page": hex6(black["page"]), "--band": hex6(black["tabBar"]), "--text": hex6(black["text"]),
        "--card": hex6(black["panel"]), "--trim": hex6(black["mustard"]), "--drop": hex6(black["shadow"]),
        "--red": hex6(black["red"]), "--green": hex6(black["green"]), "--orange": hex6(black["orange"]),
        "--blue": hex6(black["blue"]), "--purple": hex6(black["purple"]),
        "--red-lip": hex6(lip(black["red"])), "--green-lip": hex6(lip(black["green"])),
        "--trim-lip": hex6(lip(black["mustard"])), "--orange-lip": hex6(lip(black["orange"])),
        "--purple-lip": hex6(lip(black["purple"])),
    }
    wrong = []
    for token, value in want.items():
        m = re.search(r"%s: (#[0-9a-fA-F]{6});" % re.escape(token), root)
        if not m or m.group(1).lower() != value:
            wrong.append(f"{token} is {m.group(1) if m else 'missing'}, the app's Black has {value}")
    if wrong:
        raise SystemExit("website/site.css :root is out of step with the app's Black scheme:\n  " + "\n  ".join(wrong))


def main():
    pal = palettes()
    blocks = [block(v, n, pal[k]) for v, k, n in SCHEMES]
    camo = CAMO.read_text()
    check_root(pal["black"])
    for value, key, _ in SCHEMES:
        p = pal[key]
        target = ROOT / f"website/images/camo-{value}.svg"
        if p["plainHeader"]:
            target.unlink(missing_ok=True)
            continue
        svg = camo
        for old, field in zip(BLACK_CAMO, ["camoGround", "camoBig", "camoMid", "camoSmall"]):
            svg = svg.replace(f'fill="{old}"', f'fill="{hex6(p[field]).upper()}"')
        target.write_text(svg)
    css = CSS.read_text()
    generated = (
        BEGIN + "\n/* Every scheme but Black (:root above), from the app's palettes in\n"
        "   lib/core/design/camp_palette.dart. Every page's <html> names Army\n"
        "   green, the site's default (#118); website/scheme.js sets\n"
        "   data-scheme to the one a visitor tapped, for a day (#111). */\n" + "\n".join(blocks) + "\n" + END + "\n"
    )
    if BEGIN in css:
        a = css.index(BEGIN)
        b = css.index(END) + len(END) + 1
        css = css[:a] + generated + css[b:]
    else:
        css = css.rstrip("\n") + "\n\n" + generated
    CSS.write_text(css)
    print(f"{len(blocks)} schemes written to {CSS.relative_to(ROOT)} and website/images/camo-*.svg")


if __name__ == "__main__":
    main()
