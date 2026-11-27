#!/usr/bin/env bash
# CI only: says which of CI's jobs a push needs, from the files it changed,
# so a push doesn't wait for jobs it can't affect. A website edit doesn't run
# the app's tests, an app change doesn't run the server's, and the deploy to
# dev sends only the parts that changed (ARCH §9).
#
#   tools/ci_changes.sh                   in CI (ci.yml's "What changed" job)
#   tools/ci_changes.sh --base <commit>   by hand: what a push of HEAD would
#                                         run if CI last passed on <commit>
#   tools/ci_changes.sh --classify        the answer alone, as name=true or
#                                         name=false lines, for the paths on
#                                         stdin, one a line (the tests' way in)
#   tools/ci_changes.sh --each            what each path on stdin needs, a
#                                         line each: the needs (or "none"), a
#                                         tab, and the path
#
# It looks at every commit since the last one CI passed on, on the same
# branch, and not only at the push itself: a push whose run failed or was
# canceled stays in the comparison until a run passes, so nothing gets
# skipped on the strength of a run that never finished. It counts every file
# those commits touched, even one that a later commit put back as it was,
# because a run that failed may have deployed it by then. So "CI passed on
# this commit", which the releases wait for, still means every check passed
# on these files: a skipped job passed on an earlier commit, and nothing it
# reads has changed since. And a part of dev that isn't deployed again holds
# what that earlier run left there.
#
# The last commit CI passed on is the one whose run started last (a run
# started again counts from then), since that run deployed last.
#
# Whenever it can't be sure, it runs everything, as CI did before: a pull
# request, a run started by hand (the Actions tab's "Run workflow" is the way
# to run and deploy everything again), no passing run in the last month,
# GitHub not answering, a branch whose history was rewritten, a Release to
# dev since the last passing run (dev may hold another branch), a CI run
# since then on a commit that isn't part of this push (dev may hold some of
# it), or a path the rules below don't name.
#
# It can't see a deploy made from someone's computer. After one, start CI by
# hand so dev matches main again.
#
# It prints the answer, and in CI also writes it to $GITHUB_OUTPUT as
# app, functions, web, rules and fdeploy (each true or false), deploy (true
# if any of the last three is), and to the run's summary.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

# What a change to one path needs, as words from: app (the App job),
# functions (the Functions and security rules job), web (the Web build, and
# so Hosting's deploy), rules (the rules' deploy), fdeploy (the Functions'
# deploy), or all. Nothing printed means no job reads the file.
#
# A job may only be left off a path's line if nothing that job runs reads
# the file: test/tools/ci_changes_test.dart and
# functions/test/unit/ci_changes.test.ts check every file the tests open by
# name against these rules, and fail when a rule would skip their job.
needs_of() {
  case "$1" in
    # Words and pictures no job reads: the docs, the stores' listings and
    # screenshots, editor settings, and the website's editing notes, which
    # tools/build_hosting.sh leaves out of the site.
    docs/* | store/* | .vscode/* | .claude/* | website/README.md) ;;
    # The website and the .well-known files: only the Hosting build.
    website/* | hosting/*) echo web ;;
    # The server's constants are written by tools/gen_constants.dart, which
    # the App job checks, and the recurrence vectors are read by the app's
    # tests and the server's.
    functions/src/shared/constants.ts) echo app functions fdeploy ;;
    functions/test/unit/fixtures/*) echo app functions ;;
    # The server's tests aren't deployed (firebase.json ignores test/).
    functions/test/*) echo functions ;;
    functions/*) echo functions fdeploy ;;
    # The demo seed's tests run in the Functions job.
    tools/seed/*) echo functions ;;
    # The rules: the Functions job tests them, and the deploy sends them.
    firestore.rules | storage.rules | firestore.indexes.json) echo functions rules ;;
    # What only the App job reads: the app's tests and the analyzer's
    # settings, and the iOS and Android projects, which CI doesn't build but
    # the app's tests read (Info.plist, AndroidManifest.xml).
    test/* | integration_test/* | dart_test.yaml | analysis_options.yaml | ios/* | android/*)
      echo app ;;
    # The app's chat colors, which the server's palette test reads to check
    # its own list against.
    lib/features/groups/domain/chat_colors.dart) echo app functions web ;;
    # The app itself: its tests, and the web app in the Hosting build.
    lib/* | assets/* | pubspec.yaml | pubspec.lock | l10n.yaml | build.yaml) echo app web ;;
    # The web app's page, icons and scripts: only the Hosting build reads
    # them, and the server's push_sw test reads the push worker.
    web/firebase-messaging-sw.js) echo functions web ;;
    web/*) echo web ;;
    # CI's own workflow can change any job. The other workflows (the
    # releases and the Android build) are started by hand: no job here reads
    # them and nothing here checks them, so a fix to one doesn't wait for the
    # tests. That holds while ci.yml uses none of them, which the Dart test
    # checks.
    .github/workflows/ci.yml) echo all ;;
    .github/workflows/*) ;;
    # Notes at the top of the repo (README.md, TODO.md, AGENTS.md).
    *.md)
      case "$1" in
        */*) echo all ;;
        *) ;;
      esac
      ;;
    # Everything else, which more than one job reads or which is rare enough
    # not to sort out: shared/, tools/, firebase.json, and any path not named
    # above.
    *) echo all ;;
  esac
}

app=false functions=false web=false rules=false fdeploy=false
reason=""
compared=""
changed=0
folders=""
head=${GITHUB_SHA:-HEAD}

everything() {
  app=true functions=true web=true rules=true fdeploy=true
  reason=$1
}

# Reads paths, one a line, and turns on what each needs.
classify() {
  local path need first
  while IFS= read -r path || [ -n "$path" ]; do
    [ -n "$path" ] || continue
    changed=$((changed + 1))
    first=${path%%/*}
    case ", $folders, " in
      *", $first, "*) ;;
      *) folders="${folders:+$folders, }$first" ;;
    esac
    for need in $(needs_of "$path"); do
      case "$need" in
        app) app=true ;;
        functions) functions=true ;;
        web) web=true ;;
        rules) rules=true ;;
        fdeploy) fdeploy=true ;;
        all) app=true functions=true web=true rules=true fdeploy=true ;;
      esac
    done
  done
}

# Says what will run, and tells GitHub.
report() {
  local deploy=false parts="" text
  if $rules; then parts="the rules"; fi
  if $fdeploy; then parts="${parts:+$parts, }Functions"; fi
  if $web; then parts="${parts:+$parts, }Hosting"; fi
  if [ -n "$parts" ]; then deploy=true; fi

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    answer >> "$GITHUB_OUTPUT"
  fi

  text=$(
    echo "### What this run checks"
    echo
    if [ -n "$reason" ]; then
      echo "Everything: $reason."
    elif [ "$changed" -eq 0 ]; then
      echo "Nothing: no commit has changed a file since \`${compared:0:7}\`, the last commit CI passed on."
    else
      echo "Only what changed since \`${compared:0:7}\`, the last commit CI passed on: $changed file(s), in $folders."
    fi
    echo
    echo "| Job | |"
    echo "|---|---|"
    echo "| App (format, analyze, test) | $(ran $app) |"
    echo "| Functions and security rules | $(ran $functions) |"
    echo "| Web build | $(ran $web) |"
    if $deploy; then
      echo "| Deploy to dev (pushes to main only) | $parts |"
    else
      echo "| Deploy to dev (pushes to main only) | skipped: nothing it deploys changed |"
    fi
  )
  printf '%s\n' "$text"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n' "$text" >> "$GITHUB_STEP_SUMMARY"
  fi
}

# The answer as name=value lines, the way $GITHUB_OUTPUT takes them.
answer() {
  local deploy=false
  if $rules || $fdeploy || $web; then deploy=true; fi
  echo "app=$app"
  echo "functions=$functions"
  echo "web=$web"
  echo "rules=$rules"
  echo "fdeploy=$fdeploy"
  echo "deploy=$deploy"
}

# "runs", or why not, for the report.
ran() {
  if $1; then echo "runs"; else echo "skipped: nothing it checks changed"; fi
}

# Every file that a commit after $1, up to the pushed one, touched, one a
# line (a merge counts against each of its parents). Names only, and no
# rename matching, which would need the files' contents: CI's clone for this
# job has none.
changed_since() {
  git -c core.quotePath=false log --no-renames --name-only --format= -m "$1..$head" -- | sort -u
}

# Runs everything, saying why, and stops.
run_everything() {
  everything "$1"
  report
  exit 0
}

# Whether a line of the run list is as expected: an ID in digits, a full
# commit ID, a word for how it ended, a time like 2026-11-27T16:44:32Z, and
# nothing after. The times are compared as text, so their form matters.
is_run_line() {
  case "$1" in '' | *[!0-9]*) return 1 ;; esac
  case "$2" in *[!0-9a-f]*) return 1 ;; esac
  [ "${#2}" -eq 40 ] || return 1
  case "$3" in '' | *[!a-z_]*) return 1 ;; esac
  case "$4" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;;
    *) return 1 ;;
  esac
  [ -z "$5" ]
}

case "${1:-}" in
  --classify)
    classify
    answer
    exit 0
    ;;
  --each)
    while IFS= read -r path || [ -n "$path" ]; do
      [ -n "$path" ] || continue
      need=$(needs_of "$path")
      printf '%s\t%s\n' "${need:-none}" "$path"
    done
    exit 0
    ;;
  --base)
    base=${2:?Usage: $0 --base <commit>}
    if ! git merge-base --is-ancestor "$base" "$head" 2> /dev/null; then
      echo "$base isn't a commit in HEAD's history." >&2
      exit 1
    fi
    if ! files=$(changed_since "$base"); then
      echo "Can't list the changes since $base." >&2
      exit 1
    fi
    compared=$(git rev-parse "$base")
    classify <<< "$files"
    report
    exit 0
    ;;
  "") ;;
  *)
    echo "Usage: $0 [--base <commit> | --classify | --each]" >&2
    exit 64
    ;;
esac

# In CI. Only a push is compared; anything else runs everything.
if [ "${GITHUB_EVENT_NAME:-}" != push ]; then
  run_everything "this run wasn't started by a push (${GITHUB_EVENT_NAME:-no event})"
fi

# This branch's CI runs of the last month, a line each: the run's ID, its
# commit, how it ended ("none" while it runs), and when its latest attempt
# started. A month covers every run that can still be started again (GitHub
# allows that for 30 days). The times are UTC in ISO 8601, which sort as
# text.
since=$(date -u -d '31 days ago' +%F 2> /dev/null || date -u -v-31d +%F)
limit=1000
if ! runs=$(gh run list --repo "${GITHUB_REPOSITORY:-}" --workflow ci.yml \
    --branch "${GITHUB_REF_NAME:-}" --created ">=$since" --limit "$limit" \
    --json databaseId,headSha,conclusion,startedAt \
    -q '.[] | "\(.databaseId) \(.headSha) \(.conclusion // "" | if . == "" then "none" else . end) \(.startedAt)"' \
    2> /dev/null); then
  run_everything "GitHub didn't list this branch's CI runs"
fi
if [ "$(grep -c . <<< "$runs")" -ge "$limit" ]; then
  run_everything "there are too many CI runs this month to go through"
fi

# The last run that passed: of those, the one that started last. This run
# is still going, and isn't counted even if an earlier attempt of it passed.
base="" base_id="" base_at=""
while read -r id sha how at rest; do
  [ -n "$id" ] || continue
  if ! is_run_line "$id" "$sha" "$how" "$at" "$rest"; then
    run_everything "GitHub's list of CI runs wasn't in the form expected"
  fi
  [ "$id" != "${GITHUB_RUN_ID:-}" ] || continue
  if [ "$how" = success ] && [[ "$at" > "$base_at" ]]; then
    base=$sha base_id=$id base_at=$at
  fi
done <<< "$runs"
if [ -z "$base" ]; then
  run_everything "CI hasn't passed on ${GITHUB_REF_NAME:-this branch} in the last month"
fi
if ! git merge-base --is-ancestor "$base" "$head" 2> /dev/null; then
  run_everything "the last commit CI passed on (${base:0:7}) isn't in this push's history"
fi

# A run that started after that one, on a commit that isn't among this
# push's, may have deployed some of its own files: a run of an older commit
# started again, say, or of a commit since rewritten away. The commits
# between the last passing one and this one are fine: their files are in
# the comparison.
while read -r id sha how at rest; do
  [ -n "$id" ] || continue
  if [ "$id" = "$base_id" ] || [ "$id" = "${GITHUB_RUN_ID:-}" ] || [[ "$at" < "$base_at" ]]; then
    continue
  fi
  if ! git merge-base --is-ancestor "$base" "$sha" 2> /dev/null ||
    ! git merge-base --is-ancestor "$sha" "$head" 2> /dev/null; then
    run_everything "a CI run on another commit (${sha:0:7}) started after CI last passed, so dev may hold some of it"
  fi
done <<< "$runs"

# A Release to dev that was still going after that run started, or began
# later, may have put another branch on dev, so the deploy sends everything
# again.
if ! released=$(gh run list --repo "${GITHUB_REPOSITORY:-}" --workflow release-dev.yml \
    --limit 100 --json updatedAt -q '[.[].updatedAt] | max // ""' 2> /dev/null); then
  run_everything "GitHub didn't say when Release to dev last ran"
fi
if [ -n "$released" ] && [[ ! "$released" < "$base_at" ]]; then
  run_everything "Release to dev ran after CI last passed, so dev gets everything again"
fi

if ! files=$(changed_since "$base"); then
  run_everything "git couldn't list the changes since ${base:0:7}"
fi
compared=$base
classify <<< "$files"
report
