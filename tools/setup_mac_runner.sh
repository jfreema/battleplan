#!/usr/bin/env bash
# Sets this Mac up as a machine GitHub Actions runs Battleplan's jobs on (a
# "self-hosted runner"), so Release iOS builds here at no charge rather than
# on GitHub's macOS machine, which a private repository pays about $1.10 a
# run for (ROADMAP task 485), and, with --ci, CI's App job, Web build and
# Functions job run here too (task 486; DEVELOPMENT.md "Building on your
# Mac").
#
#   tools/setup_mac_runner.sh           set up, and Release iOS builds here
#   tools/setup_mac_runner.sh --ci      set up, and CI's tests and builds
#                                       run here as well as Release iOS
#   tools/setup_mac_runner.sh --ci-off  CI back on GitHub's machines, for
#                                       days the Mac will be off or away
#   tools/setup_mac_runner.sh --off     everything back on GitHub's machines
#                                       (the runner stays installed)
#   tools/setup_mac_runner.sh --on      here again (the same as setting up:
#                                       each step it finds done is skipped)
#   tools/setup_mac_runner.sh --remove  back on GitHub's, and the runner
#                                       unregistered and deleted
#
# Run it from Terminal on the Mac, in the repository. It needs the GitHub
# CLI signed in as the repository's owner (brew install gh, then
# gh auth login), which it uses to check the repository is private, to get
# GitHub's runner app and its checksum, to register the runner, and to set
# the repository variable IOS_ON_MAC that release-ios.yml reads. Nothing is
# typed into a website and no key is stored by it.
#
# In order, stopping at the first thing that's wrong with what to do:
# 1. The repository must be private. A runner on someone's own computer
#    shouldn't take a public repository's jobs (GitHub's advice), and the
#    workflow uses this Mac only while it's private either way.
# 2. What a build needs here: Xcode with the iOS SDK release-ios.yml asks
#    for (MIN_IOS_SDK), CocoaPods, git, python3, openssl. Not Flutter: the
#    workflow puts its own copy, the version CI uses, in the runner's folder.
# 3. GitHub's runner app for this Mac, into ~/actions-runner-battleplan
#    (RUNNER_DIR to change it), checked against the SHA-256 GitHub gives.
# 4. Registered with the repository under the label "battleplan", the one
#    release-ios.yml asks for, as a login item (launchd): it runs whenever
#    you're logged in, screen locked or not, and not while the Mac sleeps.
# 5. IOS_ON_MAC=on, and with --ci CI_ON_MAC=on.
#
# The runner keeps its PATH from this Terminal (its env.sh), so run it from a
# Terminal where `pod` works. A job here runs as you, with your keychain:
# that's how it signs, and why it's only for a private repository that only
# the owner pushes to.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=jfreema/battleplan
label=battleplan
dir=${RUNNER_DIR:-$HOME/actions-runner-battleplan}
mode=${1:-setup}

die() {
  echo "Stopped: $*" >&2
  exit 1
}

# The GitHub CLI, signed in.
command -v gh >/dev/null || die "the GitHub CLI isn't installed. Run: brew install gh, then gh auth login, then this again."
gh auth status >/dev/null 2>&1 || die "the GitHub CLI isn't signed in. Run: gh auth login (GitHub.com, HTTPS, log in with a web browser), then this again."

switch() { # on|off
  gh variable set IOS_ON_MAC --repo "$repo" --body "$1" >/dev/null
  if [ "$1" = on ]; then
    echo "IOS_ON_MAC is on: Release iOS builds on this Mac (tick on_github_mac for one run on GitHub's)."
  else
    echo "IOS_ON_MAC is off: Release iOS builds on GitHub's Mac."
  fi
}

switch_ci() { # on|off
  gh variable set CI_ON_MAC --repo "$repo" --body "$1" >/dev/null
  if [ "$1" = on ]; then
    echo "CI_ON_MAC is on: CI's App job, Web build and Functions job run on this Mac (not for pull requests)."
  else
    echo "CI_ON_MAC is off: CI runs on GitHub's machines."
  fi
}

case "$mode" in
  setup | --on | --ci) ;;
  --ci-off)
    switch_ci off
    exit 0
    ;;
  --off)
    switch_ci off
    switch off
    exit 0
    ;;
  --remove)
    switch_ci off
    switch off
    if [ -d "$dir" ]; then
      (
        cd "$dir"
        ./svc.sh stop || true
        ./svc.sh uninstall || true
        ./config.sh remove --token "$(gh api -X POST "repos/$repo/actions/runners/remove-token" -q .token)"
      )
      rm -rf "$dir"
    fi
    echo "The runner is unregistered and $dir is gone."
    exit 0
    ;;
  *) die "unknown option '$mode' (use --ci, --ci-off, --on, --off or --remove, or nothing to set up)" ;;
esac

# 1. Private.
[ "$(gh api "repos/$repo" -q .private)" = true ] ||
  die "$repo is public. Make it private first (Settings, General, Danger Zone, Change visibility), then run this again."

# 2. What a build needs.
[ "$(uname -s)" = Darwin ] || die "this is for the Mac."
min_sdk=$(sed -nE 's/^  MIN_IOS_SDK: ([0-9]+).*/\1/p' .github/workflows/release-ios.yml)
sdk=$(xcrun --sdk iphoneos --show-sdk-version 2>/dev/null) || die "Xcode's iOS SDK isn't found. Install Xcode, open it once, and check Xcode, Settings, Locations, Command Line Tools names it."
[ "${sdk%%.*}" -ge "${min_sdk:-0}" ] 2>/dev/null ||
  die "Xcode here has the iOS $sdk SDK, and Release iOS needs $min_sdk or later. Update Xcode, or select the newer one with: sudo xcode-select -s /Applications/Xcode.app"
command -v pod >/dev/null || die "CocoaPods isn't on this Terminal's PATH. Install it (brew install cocoapods), or run this from a Terminal where pod works."
for tool in git python3 openssl curl shasum; do
  command -v "$tool" >/dev/null || die "'$tool' isn't on this Terminal's PATH."
done
echo "Xcode $(xcodebuild -version | head -1 | cut -d' ' -f2) with the iOS $sdk SDK, CocoaPods $(pod --version)."

# 3. The runner app, checked.
if [ -x "$dir/run.sh" ]; then
  echo "The runner app is already in $dir."
else
  case "$(uname -m)" in
    arm64) arch=arm64 ;;
    *) arch=x64 ;;
  esac
  url='' sum='' name=''
  read -r url sum name < <(gh api "repos/$repo/actions/runners/downloads" \
    -q ".[] | select(.os == \"osx\" and .architecture == \"$arch\") | \"\(.download_url) \(.sha256_checksum) \(.filename)\"") || true
  [ -n "$url" ] && [ -n "$sum" ] && [ -n "$name" ] || die "GitHub didn't name a runner app for macOS $arch."
  mkdir -p "$dir"
  curl -fsSL --retry 3 -o "$dir/$name" "$url"
  echo "$sum  $dir/$name" | shasum -a 256 -c - >/dev/null ||
    { rm -f "$dir/$name"; die "the runner app's SHA-256 isn't the one GitHub gives. Nothing was installed."; }
  tar -xzf "$dir/$name" -C "$dir"
  rm -f "$dir/$name"
  echo "The runner app ($name) is in $dir, checksum checked."
fi

# 4. Registered, as a login item.
cd "$dir"
export LANG=${LANG:-en_US.UTF-8} # CocoaPods needs UTF-8; env.sh keeps it.
if [ ! -f .runner ]; then
  ./config.sh --unattended --replace \
    --url "https://github.com/$repo" \
    --token "$(gh api -X POST "repos/$repo/actions/runners/registration-token" -q .token)" \
    --name "$(scutil --get LocalHostName 2>/dev/null || hostname -s)-battleplan" \
    --labels "$label"
fi
./env.sh >/dev/null # the PATH and LANG the jobs get, from this Terminal
./svc.sh install >/dev/null 2>&1 || true # already installed is fine
./svc.sh start
echo "The runner is registered with $repo as \"$label\" and starts whenever you log in."

# 5. Release iOS here, and CI if asked.
switch on
if [ "$mode" = --ci ]; then
  switch_ci on
fi
echo "Done. The first Release iOS here takes longer (it installs Flutter in $dir)."
echo "If macOS asks whether codesign may use a key in your keychain, click Always Allow."
