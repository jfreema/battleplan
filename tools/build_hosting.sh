#!/usr/bin/env bash
# Builds the one Hosting site (ARCH §6.6, D40) into build/hosting/:
#
#   build/hosting/              the website (website/, copied as is)
#   build/hosting/app/          the Flutter web app, built with --base-href /app/
#   build/hosting/.well-known/  apple-app-site-association and assetlinks.json
#                               for the flavor (hosting/well-known/<flavor>/)
#
# Usage: tools/build_hosting.sh [dev|prod] [extra flutter build web args...]
#   tools/build_hosting.sh dev
#   tools/build_hosting.sh dev --dart-define=USE_EMULATORS=true
#   APPLE_TEAM_ID=ABCDE12345 tools/build_hosting.sh prod
#
# APPLE_TEAM_ID (not a secret) fills in apple-app-site-association; until it
# is set the file keeps a placeholder and iOS Universal Links don't verify
# (ROADMAP task 110). Works without a website/ folder: the root then gets a
# one-line page linking to the app.
set -euo pipefail
cd "$(dirname "$0")/.."

flavor="${1:-dev}"
if [ $# -gt 0 ]; then shift; fi
case "$flavor" in
  dev | prod) ;;
  *) echo "Usage: $0 [dev|prod] [flutter build web args...]" >&2; exit 64 ;;
esac

out=build/hosting
app="$out/app"
well_known_src="hosting/well-known/$flavor"

rm -rf "$out"
mkdir -p "$out"

# 1. The website at the root. It must not have its own app/ folder.
if [ -d website ]; then
  if [ -e website/app ]; then
    echo "website/app would be replaced by the web app; rename it." >&2
    exit 1
  fi
  cp -R website/. "$out/"
  # The editing notes are for the repo, not the public site.
  rm -f "$out/README.md"
fi
if [ ! -f "$out/index.html" ]; then
  echo "No website/index.html yet: writing a placeholder root page." >&2
  cat > "$out/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Battleplan</title>
  <style>
    :root { color-scheme: light dark; }
    body { font: 18px/1.5 system-ui, sans-serif; margin: 0; padding: 48px 16px; text-align: center; }
  </style>
</head>
<body>
  <h1>Battleplan</h1>
  <p>Free team chat and scheduling for sports teams.</p>
  <p><a href="/app/">Open Battleplan</a></p>
</body>
</html>
HTML
fi

# 2. The web app under /app/ (WASM, with the JS fallback, like CI), numbered
# (ARCH §9): the build number is the count of commits in the checked-out
# history, so every build of a commit has the same number and each push to
# main a higher one, and the commit's short ID goes in too. Settings → About
# shows both. A shallow clone would count wrong, so it needs the full history
# (CI checks out with fetch-depth: 0).
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "This is a shallow clone, so the build number would be wrong: fetch the full history." >&2
  exit 1
fi
build_number=$(git rev-list --count HEAD)
commit=$(git rev-parse --short=7 HEAD)
echo "Building $flavor build $build_number ($commit)."
flutter build web --wasm -t "lib/main_$flavor.dart" --base-href /app/ -o "$PWD/$app" \
  --build-number="$build_number" --dart-define=APP_COMMIT="$commit" "$@"

rm -f "$app/.last_build_id"
grep -q '<base href="/app/">' "$app/index.html" || {
  echo "$app/index.html doesn't have base href /app/." >&2
  exit 1
}

# 3. .well-known at the root, for Universal Links and App Links.
mkdir -p "$out/.well-known"
if [ -d "$well_known_src" ]; then
  cp -R "$well_known_src/." "$out/.well-known/"
fi
aasa="$out/.well-known/apple-app-site-association"
if [ -f "$aasa" ]; then
  if [ -n "${APPLE_TEAM_ID:-}" ]; then
    sed -i.bak "s/APPLE_TEAM_ID/$APPLE_TEAM_ID/g" "$aasa" && rm -f "$aasa.bak"
  else
    echo "APPLE_TEAM_ID isn't set: apple-app-site-association keeps its placeholder." >&2
  fi
fi
[ -f "$out/.well-known/assetlinks.json" ] ||
  echo "No assetlinks.json for $flavor yet: Android App Links won't verify." >&2

for f in "$out"/.well-known/*; do
  [ -f "$f" ] || continue
  python3 -m json.tool "$f" > /dev/null || { echo "$f isn't valid JSON." >&2; exit 1; }
done

echo "Built $out ($flavor): website at /, app at /app/, .well-known at the root."
