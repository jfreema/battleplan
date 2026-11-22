#!/usr/bin/env bash
# Builds the app's two bundled fonts (#85, Boot Camp Mix; SPEC §7.3) from
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
#   Comic Neue          Bold, as it comes, for reading text: messages,
#                       descriptions, and fields.
#
# Both are from Google Fonts (github.com/google/fonts, ofl/), with their
# licenses beside them here and in assets/fonts/<family>/OFL.txt. Uses
# fonttools in a temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts/battleplan_stencil assets/fonts/comic_neue

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -m venv "$tmp/venv"
"$tmp/venv/bin/pip" install --quiet --disable-pip-version-check fonttools==4.68.0

"$tmp/venv/bin/python" -I - <<'PY'
import shutil
import unicodedata

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

shutil.copy("tools/fonts/ComicNeue-Bold.ttf",
            "assets/fonts/comic_neue/ComicNeue-Bold.ttf")
shutil.copy("tools/fonts/ComicNeue-OFL.txt", "assets/fonts/comic_neue/OFL.txt")
print("assets/fonts: Battleplan Stencil Black, Comic Neue Bold")
PY
