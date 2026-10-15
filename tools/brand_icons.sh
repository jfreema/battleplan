#!/usr/bin/env bash
# Regenerates every icon and splash screen from the brand mark (SPEC §7.1:
# a white flag on a pole with an angular B cut out of it, on #2F5BEA).
#
#   assets/brand/icon.svg  the full icon: white mark on blue, square
#   assets/brand/mark.svg  the mark alone on transparent, inside the splash
#                          screens' safe zones (Android 12 crops a circle)
#   assets/brand/foreground.svg  the mark larger, for Android's adaptive icon
#                          (the tool insets it into the safe zone)
#   assets/brand/maskable.svg  the web app's maskable icon: the mark inside
#                          the 80% circle any mask keeps
#   website/favicon.svg    the website's favicon and header mark: the rounded
#                          tile, also the web app's 32 px favicon
#
# Renders each to 1024 px PNGs with headless Chrome (set CHROME to another
# Chromium binary if needed), runs flutter_launcher_icons and
# flutter_native_splash, whose settings are in pubspec.yaml, then sizes the
# web icons the tools don't make (or make from the square icon) with sips.
set -euo pipefail
cd "$(dirname "$0")/.."

chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
render() { # render <svg> <absolute png>: 1024 × 1024, transparent outside the art
  "$chrome" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --default-background-color=00000000 \
    --window-size=1024,1024 --screenshot="$2" "file://$PWD/$1" 2>/dev/null
}
size() { # size <png> <px> <out>
  sips -z "$2" "$2" "$1" --out "$3" >/dev/null
}

for name in icon mark foreground maskable; do
  render "assets/brand/$name.svg" "$PWD/assets/brand/$name.png"
done

dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Both tools rewrite files they don't need to (Info.plist's formatting, an
# Xcode build setting, the web manifest); keep ours.
git checkout -- ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist web/manifest.json

# The launcher tool makes the web app's maskable icons from the square icon,
# which a circle mask crops, and a 16 px favicon; replace them.
size assets/brand/maskable.png 512 web/icons/Icon-maskable-512.png
size assets/brand/maskable.png 192 web/icons/Icon-maskable-192.png
tile="$(mktemp -d)/favicon.png"
render website/favicon.svg "$tile"
size "$tile" 32 web/favicon.png
size "$tile" 32 website/favicon-32.png
# iOS rounds the home-screen icon itself, so it gets the square one.
size assets/brand/icon.png 180 website/apple-touch-icon.png
