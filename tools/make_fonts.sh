#!/usr/bin/env bash
# Builds the app's bundled fonts (SPEC §7.3) from the full fonts in
# tools/fonts/, the same every time. Team Shirt (#104, owner's go
# 2026-11-27: "look 56 Team Shirt with the Lato font") sets three:
#
#   Lilita One          names of things, titles and date numbers. Copied
#                       as it comes: its license names the Reserved Font
#                       Name "Lilita", so a cut of it couldn't keep the
#                       name, and at 28 KB it needs no cut.
#   Battleplan Sans     Lato's Regular, Bold and Black, for buttons,
#                       labels, tabs, people's names and all reading text.
#                       Cut to Latin, Latin-1, Latin Extended-A and
#                       Vietnamese, with kerning, ligatures and marks but
#                       not small capitals, old-style figures or the other
#                       optional alternates, and without hinting, which
#                       Flutter doesn't use (656 KB to about 100 KB a
#                       weight), so the web app downloads less before its
#                       first frame (ARCH §5.5). Greek, Cyrillic and other
#                       scripts draw in a fallback font, as they did under
#                       Nunito: on the web, Roboto, which the engine loads
#                       at startup anyway, and the system's on phones.
#                       Vietnamese stays, so no Latin word mixes two fonts.
#                       Renamed, as the SIL Open Font License requires of
#                       a Modified Version: Lato's names the Reserved Font
#                       Name "Lato".
#   Battleplan Stencil  Big Shoulders Stencil at its Display size and
#                       Black weight (opsz 72, wght 900), cut from the
#                       variable font to one static weight, for lettering
#                       that is stamped on: tags, stamps, dog tags, the
#                       weekday on a pennant, a starburst. Its small
#                       letters draw as capitals, so that lettering is in
#                       capitals however its string is written. Renamed,
#                       as a Modified Version should be (its license names
#                       no Reserved Font Name).
#
# All three are from Google Fonts (github.com/google/fonts, ofl/), with
# their licenses beside them here and in assets/fonts/<family>/OFL.txt.
# Uses fonttools in a temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts/battleplan_stencil assets/fonts/battleplan_sans \
  assets/fonts/lilita_one

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -m venv "$tmp/venv"
"$tmp/venv/bin/pip" install --quiet --disable-pip-version-check fonttools==4.68.0

"$tmp/venv/bin/python" -I - <<'PY'
import shutil
import unicodedata

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# recalcTimestamp off, and the first build's stamp kept below, so a rebuild
# is the committed file byte for byte.
src = TTFont("tools/fonts/BigShouldersStencil[opsz,wght].ttf",
             recalcTimestamp=False)
font = instancer.instantiateVariableFont(src, {"wght": 900, "opsz": 72})
font["head"].modified = 3878169982  # 2026-11-22, when it was first built

# Small letters draw as their capitals: each lowercase code point takes
# its capital's glyph, where the font has the capital.
for table in font["cmap"].tables:
    if not table.isUnicode():
        continue
    cmap = table.cmap
    for code in list(cmap):
        upper = unicodedata.normalize("NFC", chr(code).upper())
        if len(upper) == 1 and upper != chr(code) and ord(upper) in cmap:
            cmap[code] = cmap[ord(upper)]

family, style = "Battleplan Stencil", "Black"
names = font["name"]
for record in list(names.names):
    if record.nameID in (1, 2, 3, 4, 6, 16, 17, 21, 22, 25):
        names.removeNames(nameID=record.nameID)
for name_id, value in {
    1: family,
    2: "Regular",
    3: "BattleplanStencil-Black;based on Big Shoulders Stencil",
    4: f"{family} {style}",
    6: "BattleplanStencil-Black",
    16: family,
    17: style,
}.items():
    names.setName(value, name_id, 3, 1, 0x409)
    names.setName(value, name_id, 1, 0, 0)
font["OS/2"].usWeightClass = 900
font.save("assets/fonts/battleplan_stencil/BattleplanStencil-Black.ttf")
shutil.copy("tools/fonts/BigShouldersStencil-OFL.txt",
            "assets/fonts/battleplan_stencil/OFL.txt")

# Lilita One, as it comes.
shutil.copy("tools/fonts/LilitaOne-Regular.ttf",
            "assets/fonts/lilita_one/LilitaOne-Regular.ttf")
shutil.copy("tools/fonts/LilitaOne-OFL.txt", "assets/fonts/lilita_one/OFL.txt")

# Battleplan Sans: Lato cut to the Latin the app's languages write, and
# renamed. Google Fonts' "latin" range; Latin Extended-A with the letters
# Romanian, Welsh and German add, and the currency signs; and Vietnamese.
KEEP = [
    (0x0000, 0x00FF), (0x0131, 0x0131), (0x0152, 0x0153), (0x02BB, 0x02BC),
    (0x02C6, 0x02C6), (0x02DA, 0x02DA), (0x02DC, 0x02DC), (0x0304, 0x0304),
    (0x0308, 0x0308), (0x0329, 0x0329), (0x2000, 0x206F), (0x20AC, 0x20AC),
    (0x2122, 0x2122), (0x2191, 0x2191), (0x2193, 0x2193), (0x2212, 0x2212),
    (0x2215, 0x2215), (0xFEFF, 0xFEFF), (0xFFFD, 0xFFFD),
    (0x0100, 0x017F), (0x0218, 0x021B), (0x02C7, 0x02C7), (0x02D8, 0x02DD),
    (0x1E80, 0x1E85), (0x1E9E, 0x1E9E), (0x1EF2, 0x1EF3), (0x20A0, 0x20BF),
    (0x2113, 0x2113),
    (0x01A0, 0x01B0), (0x1EA0, 0x1EF9), (0x0300, 0x0303), (0x0309, 0x0309),
    (0x0323, 0x0323),
]
# Kerning, ligatures and marks; not small capitals, old-style figures or
# stylistic sets, which nothing in the app turns on.
FEATURES = ["kern", "liga", "clig", "calt", "ccmp", "locl", "mark", "mkmk",
            "rlig"]
family = "Battleplan Sans"
for weight, weight_class in [("Regular", 400), ("Bold", 700), ("Black", 900)]:
    options = subset.Options()
    options.layout_features = FEATURES
    options.name_IDs = ["*"]  # copyright, trademark, license and the rest
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.hinting = False
    sans = subset.load_font(f"tools/fonts/Lato-{weight}.ttf", options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[
        c for c in sans.getBestCmap()
        if any(lo <= c <= hi for lo, hi in KEEP)
    ])
    subsetter.subset(sans)
    # Its own name; Lato's copyright, trademark and license records stay.
    names = sans["name"]
    for record in list(names.names):
        if record.nameID in (1, 2, 3, 4, 6, 16, 17, 18, 21, 22, 25):
            names.removeNames(nameID=record.nameID)
    post = f"BattleplanSans-{weight}"
    for name_id, value in {
        # Regular and Bold are one style-linked family; Black is its own
        # in the old four-style scheme.
        1: family if weight != "Black" else f"{family} {weight}",
        2: weight if weight != "Black" else "Regular",
        3: f"{post};based on Lato 2.015",
        4: f"{family} {weight}",
        6: post,
        16: family,
        17: weight,
    }.items():
        names.setName(value, name_id, 3, 1, 0x409)
        names.setName(value, name_id, 1, 0, 0)
    sans["OS/2"].usWeightClass = weight_class
    subset.save_font(sans, f"assets/fonts/battleplan_sans/{post}.ttf", options)
shutil.copy("tools/fonts/Lato-OFL.txt", "assets/fonts/battleplan_sans/OFL.txt")
print("assets/fonts: Lilita One, Battleplan Sans Regular, Bold and Black, "
      "Battleplan Stencil Black")
PY
