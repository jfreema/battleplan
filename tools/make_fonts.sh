#!/usr/bin/env bash
# Builds the app's bundled fonts (#85, Boot Camp Mix; SPEC §7.3) from
# the full fonts in tools/fonts/, the same every time:
#
#   Battleplan Stencil  Big Shoulders Stencil at its Display size and
#                       Black weight (opsz 72, wght 900), cut from the
#                       variable font to one static weight. Its small
#                       letters draw as capitals, so every title, label,
#                       button and tab is in capitals however its string
#                       is written, as the design sets them. Renamed, as
#                       a Modified Version under the SIL Open Font License
#                       should be (it names no Reserved Font Name).
#   Nunito              SemiBold and Bold, for reading text (#97):
#                       messages, descriptions, fields, and every
#                       information line in SemiBold, bold spans in Bold.
#                       Cut to every character but Cyrillic (125 KB to
#                       79 KB a weight), so the web app downloads less
#                       before its first frame (ARCH §5.5). Cyrillic draws
#                       in a fallback font instead, as Greek and other
#                       scripts Nunito never had already do: on the web,
#                       Roboto, which the engine loads at startup anyway,
#                       and the system's on phones. Vietnamese stays, so no
#                       Latin word mixes two fonts. Neither license names a
#                       Reserved Font Name, so both allow the cut.
#
# Both are from Google Fonts (github.com/google/fonts, ofl/), with their
# licenses beside them here and in assets/fonts/<family>/OFL.txt. Uses
# fonttools in a temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts/battleplan_stencil assets/fonts/nunito

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

src = TTFont("tools/fonts/BigShouldersStencil[opsz,wght].ttf")
font = instancer.instantiateVariableFont(src, {"wght": 900, "opsz": 72})

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

# Nunito without Cyrillic, keeping its kerning, ligatures and names.
CYRILLIC = [(0x0400, 0x052F), (0x1C80, 0x1C8F), (0x2DE0, 0x2DFF),
            (0xA640, 0xA69F), (0xFE2E, 0xFE2F)]
for weight in ["SemiBold", "Bold"]:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True
    nunito = subset.load_font(f"tools/fonts/Nunito-{weight}.ttf", options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[
        c for c in nunito.getBestCmap()
        if not any(lo <= c <= hi for lo, hi in CYRILLIC)
    ])
    subsetter.subset(nunito)
    subset.save_font(nunito, f"assets/fonts/nunito/Nunito-{weight}.ttf",
                     options)
shutil.copy("tools/fonts/Nunito-OFL.txt", "assets/fonts/nunito/OFL.txt")
print("assets/fonts: Battleplan Stencil Black, Nunito SemiBold and Bold")
PY
