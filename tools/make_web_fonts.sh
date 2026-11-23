#!/usr/bin/env bash
# Makes the website's two fonts (website/fonts/, #94 Camo HQ) from the app's
# own (assets/fonts/, built by tools/make_fonts.sh), the same every time:
# Battleplan Stencil Black for titles, labels and buttons, and Comic Neue Bold
# for reading text, each cut to Google Fonts' Latin range and saved as WOFF2,
# with its SIL Open Font License beside it. The site serves them itself, so
# it makes no third-party requests. Uses fonttools in a temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p website/fonts

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -m venv "$tmp/venv"
"$tmp/venv/bin/pip" install --quiet --disable-pip-version-check fonttools==4.68.0 brotli==1.1.0

# Google Fonts' "latin" subset.
latin="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"

cut() { # cut <source ttf> <woff2 name> <license source>
  "$tmp/venv/bin/pyftsubset" "$1" --unicodes="$latin" --flavor=woff2 \
    --layout-features='*' --output-file="website/fonts/$2.woff2"
  cp "$3" "website/fonts/$2-OFL.txt"
}
cut assets/fonts/battleplan_stencil/BattleplanStencil-Black.ttf battleplan-stencil assets/fonts/battleplan_stencil/OFL.txt
cut assets/fonts/comic_neue/ComicNeue-Bold.ttf comic-neue assets/fonts/comic_neue/OFL.txt
ls -l website/fonts
