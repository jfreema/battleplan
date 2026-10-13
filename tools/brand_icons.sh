#!/usr/bin/env bash
# Regenerates the app icons and splash screens from the placeholder mark
# (SPEC §7.1 and Q9: the flag mark on #2F5BEA until a logo is designed).
#
#   assets/brand/icon.svg  the full icon: white mark on blue, square
#   assets/brand/mark.svg  the mark alone on transparent, inside the splash
#                          screens' safe zones (Android 12 crops a circle)
#   assets/brand/foreground.svg  the mark larger, for Android's adaptive icon
#                          (the tool insets it into the safe zone)
#
# Renders each to 1024 px PNGs with headless Chrome (set CHROME to another
# Chromium binary if needed), then runs flutter_launcher_icons and
# flutter_native_splash, whose settings are in pubspec.yaml.
set -euo pipefail
cd "$(dirname "$0")/.."

chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
for name in icon mark foreground; do
  "$chrome" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --default-background-color=00000000 \
    --window-size=1024,1024 \
    --screenshot="$PWD/assets/brand/$name.png" "file://$PWD/assets/brand/$name.svg" \
    2>/dev/null
done

dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Both tools rewrite files they don't need to (Info.plist's formatting, an
# Xcode build setting, the web manifest); keep ours.
git checkout -- ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist web/manifest.json
