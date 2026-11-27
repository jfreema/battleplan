#!/usr/bin/env bash
# Makes the website's fonts (website/fonts/) from the app's own
# (assets/fonts/, built by tools/make_fonts.sh), the same every time, as
# WOFF2 with each family's SIL Open Font License beside it. Team Shirt
# (#104) sets three:
#
#   Lilita One          titles. Compressed as it comes, not cut: its license
#                       names the Reserved Font Name "Lilita", and a WOFF2
#                       that only compresses a font isn't a Modified Version
#                       of it (the license's FAQ, 2.2 and 2.3), so it keeps
#                       its name.
#   Battleplan Sans     Regular for reading text, Bold for bold spans and
#                       notes, Black for buttons and links.
#   Battleplan Stencil  Black, for the lettering that is stamped on: tags,
#                       dog tags and the starburst.
#
# Battleplan Sans and Battleplan Stencil are cut to Google Fonts' Latin
# range; both already carry their own names. The site serves all of them
# itself, so it makes no third-party requests. Uses fonttools in a
# temporary virtualenv.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p website/fonts

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -m venv "$tmp/venv"
"$tmp/venv/bin/pip" install --quiet --disable-pip-version-check fonttools==4.68.0 brotli==1.1.0

# Google Fonts' "latin" subset.
latin="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"

cut() { # cut <source ttf> <woff2 name>
  "$tmp/venv/bin/pyftsubset" "$1" --unicodes="$latin" --flavor=woff2 \
    --layout-features='*' --output-file="website/fonts/$2.woff2"
}
"$tmp/venv/bin/fonttools" ttLib.woff2 compress \
  -o website/fonts/lilita-one.woff2 assets/fonts/lilita_one/LilitaOne-Regular.ttf
cp assets/fonts/lilita_one/OFL.txt website/fonts/lilita-one-OFL.txt
cut assets/fonts/battleplan_sans/BattleplanSans-Regular.ttf battleplan-sans-regular
cut assets/fonts/battleplan_sans/BattleplanSans-Bold.ttf battleplan-sans-bold
cut assets/fonts/battleplan_sans/BattleplanSans-Black.ttf battleplan-sans-black
cp assets/fonts/battleplan_sans/OFL.txt website/fonts/battleplan-sans-OFL.txt
cut assets/fonts/battleplan_stencil/BattleplanStencil-Black.ttf battleplan-stencil
cp assets/fonts/battleplan_stencil/OFL.txt website/fonts/battleplan-stencil-OFL.txt
ls -l website/fonts
