#!/usr/bin/env bash
# CI only: puts PDFium where pdfium_dart's build hook looks for it, before a
# build, so the build doesn't depend on the hook's own download from GitHub's
# release downloads, which sometimes answer 504 for many minutes (2026-11-09).
#
#   tools/fill_pdfium.sh linux-x64 [android-arm64 android-arm android-x64 ...]
#
# For each target it fetches the release's archive through the GitHub API
# (gh, with GH_TOKEN), falling back to a patient curl, and writes
# .dart_tool/hooks_runner/shared/pdfium_dart/build/<release>/<target>/<library>,
# the file the hook skips its download for. A file already there is kept.
# When pdfium_dart is upgraded, update release to its _pdfiumRelease.
set -euo pipefail
cd "$(dirname "$0")/.."

release=chromium/8125 # pdfium_dart 0.4.1's _pdfiumRelease
dir=".dart_tool/hooks_runner/shared/pdfium_dart/build/${release//\//_}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for target in "$@"; do
  case "$target" in
    win-*) lib=pdfium.dll; inner=bin/pdfium.dll ;;
    mac-*) lib=libpdfium.dylib; inner=lib/libpdfium.dylib ;;
    *) lib=libpdfium.so; inner=lib/libpdfium.so ;;
  esac
  out="$dir/$target/$lib"
  if [ -s "$out" ]; then
    echo "PDFium $target: already in $out"
    continue
  fi
  archive="$tmp/pdfium-$target.tgz"
  if ! gh release download "$release" -R bblanchon/pdfium-binaries \
      -p "pdfium-$target.tgz" -O "$archive" 2>/dev/null; then
    curl -fsSL --retry 12 --retry-all-errors --retry-delay 15 -o "$archive" \
      "https://github.com/bblanchon/pdfium-binaries/releases/download/${release//\//%2F}/pdfium-$target.tgz"
  fi
  mkdir -p "$tmp/$target" "$dir/$target"
  tar -xzf "$archive" -C "$tmp/$target" "$inner"
  cp "$tmp/$target/$inner" "$out"
  echo "PDFium $target -> $out"
done
