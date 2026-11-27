#!/usr/bin/env python3
"""Stops Release iOS before the build when Apple takes no more of its version.

Once App Review approves a version, App Store Connect refuses every new build
with that version or a lower one ("Invalid Pre-Release Train. The train
version '1.4.3' is closed for new build submissions"), and Release iOS only
found that out at its last step, the upload, after a quarter of an hour on the
macOS machine: runs #15 (1.4.2) and #17 (1.4.3) in November 2026, about $0.90
each once the repository is private. release-ios.yml runs this in its first
job, on Linux, so a closed version stops the run in seconds with a message
saying what to change.

It reads the version from pubspec.yaml (the part before "+"), asks App Store
Connect for the app's iOS versions, and fails when the pubspec version isn't
higher than every version Apple has approved. Anything else passes. If App
Store Connect can't be asked, or answers something unexpected, it warns and
passes: the upload still catches a closed version, as it always has.

Reads ASC_KEY_PATH (the .p8 file), ASC_KEY_ID, and ASC_ISSUER_ID, as
tools/revoke_ci_certificates.py does, whose token and request code it uses;
ASC_APP_ID and PUBSPEC are for tests. Uses only Python's standard library and
the openssl command.
"""

import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse

from revoke_ci_certificates import API, call, token

# The app's Apple ID in App Store Connect (App Information), also in its App
# Store link, apps.apple.com/app/id6823884728.
APP_ID = os.environ.get("ASC_APP_ID", "6823884728")
PUBSPEC = os.environ.get(
    "PUBSPEC", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pubspec.yaml")
)

# A version in any of these states has been approved, so its train is closed.
# App Store Connect gives a version's state as appVersionState and, in the
# older field it still fills in, appStoreState; their names differ a little,
# so both lists are here. A state not named here counts as open: waiting for
# review, in review, rejected, being prepared, and any state Apple adds later.
APPROVED_STATES = {
    "ACCEPTED",
    "PENDING_APPLE_RELEASE",
    "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_APP_STORE",
    "PROCESSING_FOR_DISTRIBUTION",
    "READY_FOR_SALE",
    "READY_FOR_DISTRIBUTION",
    "PREORDER_READY_FOR_SALE",
    "REPLACED_WITH_NEW_VERSION",
    "REMOVED_FROM_SALE",
    "DEVELOPER_REMOVED_FROM_SALE",
}


def parse(version: str):
    """'1.4.6' as (1, 4, 6), or None if it isn't numbers and dots."""
    if not re.fullmatch(r"\d+(\.\d+)*", version or ""):
        return None
    return tuple(int(part) for part in version.split("."))


def next_patch(version) -> str:
    """The version after it, raising only the last number (the owner's rule)."""
    return ".".join(str(n) for n in (*version[:-1], version[-1] + 1))


def pubspec_version(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        for line in f:
            match = re.match(r"version:\s*([^\s+#]+)", line)
            if match:
                return match.group(1)
    raise ValueError(f"no version line in {path}")


def app_store_versions(bearer: str):
    """Every iOS version of the app in App Store Connect: (version, states)."""
    query = urllib.parse.urlencode({"filter[platform]": "IOS", "limit": 200})
    url = f"{API}/v1/apps/{APP_ID}/appStoreVersions?{query}"
    while url:
        page = call("GET", url, bearer)
        for item in page.get("data", []):
            attributes = item.get("attributes") or {}
            states = {attributes.get("appVersionState"), attributes.get("appStoreState")}
            yield attributes.get("versionString") or "", states - {None}
        url = (page.get("links") or {}).get("next")


def main() -> int:
    key_path = os.environ.get("ASC_KEY_PATH", "")
    key_id = os.environ.get("ASC_KEY_ID", "")
    issuer_id = os.environ.get("ASC_ISSUER_ID", "")
    try:
        ours = pubspec_version(PUBSPEC)
    except (OSError, ValueError) as e:
        print(f"::warning::Couldn't read the app's version, so it isn't checked with Apple: {e}")
        return 0
    if parse(ours) is None:
        print(f"::warning::The app's version, '{ours}', isn't numbers and dots, so it isn't checked with Apple.")
        return 0
    if not (key_path and os.path.isfile(key_path) and key_id and issuer_id):
        print("::warning::No App Store Connect key here, so the version isn't checked with Apple.")
        return 0
    try:
        versions = list(app_store_versions(token(key_path, key_id, issuer_id)))
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:600]
        print(f"::warning::App Store Connect answered {e.code} when asked for the app's versions, so {ours} isn't checked: {detail}")
        return 0
    except subprocess.CalledProcessError as e:
        detail = e.stderr.decode(errors="replace").strip()[:300]
        print(f"::warning::openssl couldn't sign the App Store Connect token, so {ours} isn't checked: {detail}")
        return 0
    except (urllib.error.URLError, ValueError, KeyError, TypeError, AttributeError, OSError) as e:
        print(f"::warning::Couldn't ask App Store Connect for the app's versions, so {ours} isn't checked: {e}")
        return 0

    for version, states in sorted(versions, key=lambda v: parse(v[0]) or ()):
        print(f"App Store Connect has {version or '?'}: {', '.join(sorted(states)) or 'no state given'}.")
    approved = [parse(v) for v, states in versions if states & APPROVED_STATES and parse(v)]
    if not approved or parse(ours) > max(approved):
        print(f"Apple still takes builds of {ours}.")
        return 0
    highest = ".".join(str(n) for n in max(approved))
    if parse(ours) == max(approved):
        why = f"Apple has already approved {ours}, so App Store Connect takes no more {ours} builds"
    else:
        why = f"The app is {ours}, and Apple has already approved {highest}, so App Store Connect takes only a higher version"
    print(
        f"::error::{why}. Set version in pubspec.yaml to {next_patch(max(approved))} "
        "(keep the +1 after it), commit, push, and run Release iOS again once CI passes."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
