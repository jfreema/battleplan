#!/usr/bin/env python3
"""Revokes the Apple Development certificates Release iOS makes.

Xcode signs the archive with an Apple Development certificate. GitHub's macOS
machines start with none, so on each run Xcode makes one through the App Store
Connect API key, named "Created via API", and the machine and its private key
are thrown away afterwards. Apple allows an account only so many, and by
2026-11-12 the leftovers had filled it: "Your account has reached the maximum
number of certificates" (ROADMAP task 382). So release-ios.yml runs this before
the archive, for any earlier run's, and after the upload, for its own.

Only development certificates named "Created via API" are revoked: never a
distribution or Developer ID certificate, or one made in Xcode on a Mac.
Apps on the App Store and in TestFlight are signed for distribution, so they're
unaffected. A failure here is a warning, not a failed release.

Reads ASC_KEY_PATH (the .p8 file), ASC_KEY_ID, and ASC_ISSUER_ID. Uses only
Python's standard library and the openssl command, so the runner installs
nothing.
"""

import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

# ASC_API_BASE is for tests against a local stand-in; releases use Apple's.
API = os.environ.get("ASC_API_BASE", "https://api.appstoreconnect.apple.com")
DEVELOPMENT_TYPES = {"DEVELOPMENT", "IOS_DEVELOPMENT", "MAC_APP_DEVELOPMENT"}
MADE_BY_API = "Created via API"


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def raw_signature(der: bytes) -> bytes:
    """openssl's DER ECDSA signature as the JWT's r and s, 32 bytes each."""
    # SEQUENCE { INTEGER r, INTEGER s }; a P-256 signature fits short lengths.
    if len(der) < 8 or der[0] != 0x30 or der[1] & 0x80:
        raise ValueError("openssl's signature isn't a P-256 ECDSA signature")
    parts, i = [], 2
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("openssl's signature isn't a P-256 ECDSA signature")
        n = der[i + 1]
        parts.append(der[i + 2 : i + 2 + n].lstrip(b"\0").rjust(32, b"\0"))
        i += 2 + n
    return b"".join(parts)


def token(key_path: str, key_id: str, issuer_id: str) -> str:
    """An App Store Connect API token (ES256), good for 10 minutes."""
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    claims = b64url(
        json.dumps(
            {"iss": issuer_id, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}
        ).encode()
    )
    signing_input = f"{header}.{claims}".encode()
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", key_path],
        input=signing_input,
        capture_output=True,
        check=True,
    ).stdout
    return f"{header}.{claims}.{b64url(raw_signature(der))}"


def call(method: str, url: str, bearer: str):
    request = urllib.request.Request(
        url, method=method, headers={"Authorization": f"Bearer {bearer}"}
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        body = response.read()
    return json.loads(body) if body else None


def certificates(bearer: str):
    url = f"{API}/v1/certificates?limit=200"
    while url:
        page = call("GET", url, bearer)
        yield from page.get("data", [])
        url = (page.get("links") or {}).get("next")


def kind(cert: dict) -> str:
    return (cert.get("attributes") or {}).get("certificateType") or ""


def made_by_api(cert: dict) -> bool:
    attributes = cert.get("attributes") or {}
    names = f"{attributes.get('name') or ''} {attributes.get('displayName') or ''}"
    return kind(cert) in DEVELOPMENT_TYPES and MADE_BY_API in names


def main() -> int:
    key_path = os.environ.get("ASC_KEY_PATH", "")
    key_id = os.environ.get("ASC_KEY_ID", "")
    issuer_id = os.environ.get("ASC_ISSUER_ID", "")
    if not (key_path and os.path.isfile(key_path) and key_id and issuer_id):
        print("No App Store Connect key on this machine, so nothing to revoke.")
        return 0
    try:
        bearer = token(key_path, key_id, issuer_id)
        every = list(certificates(bearer))
        development = [c for c in every if kind(c) in DEVELOPMENT_TYPES]
        ours = [c for c in development if made_by_api(c)]
        print(
            f"{len(development)} development certificates on the account, "
            f'{len(ours)} of them "{MADE_BY_API}" by Release iOS.'
        )
        for cert in ours:
            attributes = cert.get("attributes") or {}
            call("DELETE", f"{API}/v1/certificates/{cert['id']}", bearer)
            print(
                f"Revoked {attributes.get('name') or MADE_BY_API} "
                f"(serial ending {(attributes.get('serialNumber') or '?')[-6:]}, "
                f"expiring {(attributes.get('expirationDate') or '?')[:10]})."
            )
        left = len(development) - len(ours)
        if left:
            print(f"Left alone: {left} development certificates made in Xcode on a Mac.")
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:600]
        print(f"::warning::App Store Connect answered {e.code} while revoking Release iOS's development certificates: {detail}")
    except subprocess.CalledProcessError as e:
        detail = e.stderr.decode(errors="replace").strip()[:300]
        print(f"::warning::openssl couldn't sign the App Store Connect token: {detail}")
    except (urllib.error.URLError, ValueError, KeyError, OSError) as e:
        print(f"::warning::Couldn't revoke Release iOS's development certificates: {e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
