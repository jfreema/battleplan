#!/usr/bin/env bash
# Fails the build if Firebase leaks out of the data layer, or Flutter into
# domain/ (ARCH §5.2, SPEC ENG-1). Runs in CI on every PR.
set -euo pipefail
cd "$(dirname "$0")/.."

status=0
bad=$(grep -rlE "package:(cloud_firestore|cloud_functions|firebase_[a-z_]+)/" lib \
      | grep -vE "^lib/(app|features/[a-z_]+/data)/" || true)
if [ -n "$bad" ]; then echo "Firebase imported outside data/ or app/:"; echo "$bad"; status=1; fi

bad=$(grep -rlE "package:(flutter|material_ui|cupertino_ui|flutter_riverpod|riverpod)[a-z_]*/" lib/features/*/domain || true)
if [ -n "$bad" ]; then echo "Flutter or Riverpod imported in domain/:"; echo "$bad"; status=1; fi

# Features use each other only through domain/ and application/ (rule 7).
for f in $(grep -rlE "package:battleplan/features/[a-z_]+/(data|presentation)/" lib/features || true); do
  own=$(echo "$f" | sed -E 's#^lib/features/([a-z_]+)/.*#\1#')
  if grep -qE "package:battleplan/features/([a-z_]+)/(data|presentation)/" "$f" \
     && grep -oE "package:battleplan/features/[a-z_]+/(data|presentation)/" "$f" \
        | grep -vq "features/$own/"; then
    echo "Imports another feature's data/ or presentation/: $f"; status=1
  fi
done

exit $status
