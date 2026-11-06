#!/usr/bin/env bash
# Cuts two bundled fonts down to the letters the app draws in them, so the
# web app downloads less before its first frame (ARCH §5.5):
#
#   Black Ops One  A–Z, the space and "·" (166 KB to about 11 KB). It only
#                  draws the header and event eyebrows, in capitals, from
#                  the English strings ("GAME · HOME"; shell_test checks
#                  every eyebrow fits). Add the letters a new language's
#                  eyebrows need and run this again.
#   Nunito         every character but Cyrillic (125 KB to 69 KB a weight).
#                  Cyrillic draws in a fallback font instead, as Greek and
#                  other scripts Nunito never had already do: on the web,
#                  Roboto, which the engine loads at startup anyway, and the
#                  system's on phones. Vietnamese stays, so no Latin word
#                  mixes two fonts.
#
# The full fonts from Google Fonts are in tools/fonts/ (their licenses are
# beside the cut ones, in assets/fonts/<family>/OFL.txt, and allow the cut:
# neither names a Reserved Font Name). This writes the cut ones over
# assets/fonts/, the same every time, with fonttools installed in a
# temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -m venv "$tmp/venv"
"$tmp/venv/bin/pip" install --quiet --disable-pip-version-check fonttools==4.68.0

"$tmp/venv/bin/python" -I - <<'PY'
from fontTools import subset

CYRILLIC = [(0x0400, 0x052F), (0x1C80, 0x1C8F), (0x2DE0, 0x2DFF),
            (0xA640, 0xA69F), (0xFE2E, 0xFE2F)]

def cut(name, family, keep):
    options = subset.Options()
    options.layout_features = ["*"]  # kerning, ligatures, and the rest
    options.name_IDs = ["*"]  # copyright, license, and the other names
    options.name_languages = ["*"]
    options.notdef_outline = True
    font = subset.load_font(f"tools/fonts/{name}", options)
    before = len(font.getBestCmap())
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[c for c in font.getBestCmap() if keep(c)])
    subsetter.subset(font)
    out = f"assets/fonts/{family}/{name}"
    subset.save_font(font, out, options)
    print(f"{out}: {len(font.getBestCmap())} of {before} characters")

cut("BlackOpsOne-Regular.ttf", "black_ops_one",
    lambda c: c == 0x20 or c == 0xB7 or 0x41 <= c <= 0x5A)
for weight in ["Regular", "SemiBold", "Bold", "ExtraBold", "Black"]:
    cut(f"Nunito-{weight}.ttf", "nunito",
        lambda c: not any(lo <= c <= hi for lo, hi in CYRILLIC))
PY
