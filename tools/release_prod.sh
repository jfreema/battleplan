#!/usr/bin/env bash
# Releases main to prod by hand (ROADMAP task 117): Firestore rules and
# indexes, Storage rules, Functions, and the Hosting site (the website, and
# the web app at /app). Run it from the repo folder, signed in to firebase
# and gh, after tools/setup_prod.sh has set up the project once:
#
#   tools/release_prod.sh
#   APP_CHECK_WEB_KEY=<site key> tools/release_prod.sh   # once App Check has a key
#
# It releases only what's on GitHub: main, with nothing uncommitted, the
# same commit as origin/main, and CI passed on it. Pass --skip-ci-check to
# release a commit whose CI hasn't finished (say, a fix during an outage).
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=battleplan-prod

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != main ]; then
  echo "Release from main (this is $branch)." >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "Commit or set aside your changes first: only what's on GitHub is released." >&2
  exit 1
fi
git fetch -q origin main
sha=$(git rev-parse HEAD)
if [ "$sha" != "$(git rev-parse origin/main)" ]; then
  echo "main isn't the same as GitHub's: push (or pull) first." >&2
  exit 1
fi
if [ "${1:-}" != --skip-ci-check ]; then
  ci=$(gh run list --commit "$sha" --workflow ci.yml --limit 1 --json status,conclusion \
    -q '.[0] | "\(.status) \(.conclusion)"')
  if [ "$ci" != "completed success" ]; then
    echo "CI hasn't passed on ${sha:0:7} (${ci:-no run}). Wait for it, or pass --skip-ci-check." >&2
    exit 1
  fi
fi

echo "Releasing ${sha:0:7} to $PROJECT."
tools/build_hosting.sh prod ${APP_CHECK_WEB_KEY:+--dart-define=APP_CHECK_WEB_KEY=$APP_CHECK_WEB_KEY}
firebase deploy --project "$PROJECT" --non-interactive \
  --only firestore:rules,firestore:indexes,storage,functions,hosting \
  --message "Release ${sha:0:7}"
echo "Released ${sha:0:7}: https://getbattleplan.app (and https://$PROJECT.web.app)."
