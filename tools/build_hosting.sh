#!/usr/bin/env bash
# Builds the one Hosting site (ARCH §6.6, D40) into build/hosting/:
#
#   build/hosting/              the website (website/, copied as is; on dev,
#                               every page gets a robots noindex meta tag)
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
  # The dev site serves the same pages as getbattleplan.app: keep search
  # engines from listing it. Its canonical links still point to
  # getbattleplan.app, and robots.txt still lets crawlers in, so they see this.
  if [ "$flavor" = dev ]; then
    for page in "$out"/*.html; do
      python3 - "$page" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
if '<meta name="robots"' not in text:
    head = '<meta charset="utf-8">'
    if head not in text:
        sys.exit(f"{path} has no {head} to put the noindex after")
    text = text.replace(head, head + '\n  <meta name="robots" content="noindex">', 1)
    open(path, "w").write(text)
PY
    done
  fi
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

# Long-cached app files (ARCH §6.6): the big files get names with a hash of
# their contents, so firebase.json's hashed-file rule lets browsers keep them
# for a year, and a new release has new names. flutter_bootstrap.js, which
# names them, stays no-cache. dart2js's deferred parts first, since
# main.dart.js names them.
hashed() { # file -> name with an 8-character content hash before the extension
  local dir name stem ext
  dir=$(dirname "$1"); name=$(basename "$1")
  case "$name" in
    *.part.js) stem="${name%.js}"; ext=js ;;
    *) stem="${name%.*}"; ext="${name##*.}" ;;
  esac
  echo "$stem.$(shasum -a 256 "$1" | cut -c1-8).$ext"
}
rename_in() { # file old new: replaces the quoted name old with new in file
  python3 - "$@" <<'PY'
import sys
path, old, new = sys.argv[1:]
text = open(path).read()
if f'"{old}"' not in text:
    sys.exit(f"{path} doesn't name {old}")
open(path, "w").write(text.replace(f'"{old}"', f'"{new}"'))
PY
}
for part in "$app"/main.dart.js_*.part.js; do
  [ -f "$part" ] || continue
  new=$(hashed "$part")
  mv "$part" "$app/$new"
  rename_in "$app/main.dart.js" "$(basename "$part")" "$new"
done
for main in main.dart.wasm main.dart.mjs main.dart.js; do
  [ -f "$app/$main" ] || continue
  new=$(hashed "$app/$main")
  mv "$app/$main" "$app/$new"
  rename_in "$app/flutter_bootstrap.js" "$main" "$new"
done
grep -q '<base href="/app/">' "$app/index.html" || {
  echo "$app/index.html doesn't have base href /app/." >&2
  exit 1
}

# Firebase's own scripts, which the app loads from www.gstatic.com once it
# runs and its first frame waits for, get modulepreload links in index.html,
# so browsers fetch them alongside the app (ARCH §5.6).
dart run tools/preload_firebase.dart "$app/index.html"

# The web engine's fallback fonts (Roboto, the emoji, and Noto for other
# scripts), served from /app/fonts/fallback/ so browsers never fetch them
# from fonts.gstatic.com; web/flutter_bootstrap.js points the engine there
# (ARCH §5.5). About 22 MB, downloaded here, not kept in the repo.
dart run tools/fetch_fallback_fonts.dart "$app/fonts/fallback"
grep -q "fontFallbackBaseUrl" "$app/flutter_bootstrap.js" || {
  echo "$app/flutter_bootstrap.js doesn't set fontFallbackBaseUrl." >&2
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
# assetlinks.json lists the SHA-256 of every key that signs the Android app:
# the upload key (the Android build's run summary) and, for prod, Play App
# Signing's key (Play Console, App integrity). They only exist once the
# upload key is made and the first bundle is in Google Play, so until then
# there's no file and this warns (docs/DEVELOPMENT.md, App Links).
[ -f "$out/.well-known/assetlinks.json" ] ||
  echo "No hosting/well-known/$flavor/assetlinks.json yet: Android App Links won't verify. It needs the upload key's and (prod) Play App Signing's SHA-256 (docs/DEVELOPMENT.md, App Links)." >&2

for f in "$out"/.well-known/*; do
  [ -f "$f" ] || continue
  python3 -m json.tool "$f" > /dev/null || { echo "$f isn't valid JSON." >&2; exit 1; }
done

echo "Built $out ($flavor): website at /, app at /app/, .well-known at the root."
