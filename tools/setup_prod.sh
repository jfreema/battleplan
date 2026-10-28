#!/usr/bin/env bash
# One-time setup of the prod project for the Phase 1 go-live (ROADMAP tasks
# 115 and 116; ARCH §6.10, §6.12). Run it once from the repo folder, signed
# in to gcloud and firebase as the project owner, after battleplan-prod is
# on the Blaze plan (task 114):
#
#   tools/setup_prod.sh
#
# It creates the Firestore database in us-central1 (permanent, Q11) with
# point-in-time recovery and daily backups kept 7 days, the TTL policies,
# the Storage bucket, the Resend key in Secret Manager (copied from dev),
# the function-image cleanup policy, the sign-in providers and authorized
# domains, and the custom domains, then prints the DNS records to add in
# Cloudflare (DNS only, grey cloud). Safe to re-run: each step checks
# first. Deploying the code is tools/release_prod.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=battleplan-prod
DEV=battleplan-dev-ecce4
REGION=us-central1
DOMAIN=getbattleplan.app
BUCKET="$PROJECT.firebasestorage.app"

say() { printf '\n== %s\n' "$*"; }
token() { gcloud auth print-access-token; }
# Google's admin APIs with the signed-in user's credentials, billed to prod.
api() {
  local method=$1 url=$2 body=${3:-}
  curl -sS -X "$method" "$url" \
    -H "Authorization: Bearer $(token)" \
    -H "x-goog-user-project: $PROJECT" \
    -H 'Content-Type: application/json' \
    ${body:+-d "$body"}
}

say "Blaze plan (task 114)"
if [ "$(gcloud billing projects describe "$PROJECT" --format='value(billingEnabled)')" != True ]; then
  echo "$PROJECT isn't on the Blaze plan yet: upgrade it in the Firebase console first."
  exit 1
fi

say "APIs"
gcloud services enable firestore.googleapis.com firebasestorage.googleapis.com \
  secretmanager.googleapis.com identitytoolkit.googleapis.com \
  firebasehosting.googleapis.com --project "$PROJECT"

say "Firestore database in $REGION"
if ! gcloud firestore databases describe --database='(default)' --project "$PROJECT" >/dev/null 2>&1; then
  gcloud firestore databases create --location="$REGION" --type=firestore-native --project "$PROJECT"
fi

say "Point-in-time recovery, and daily backups kept 7 days (ARCH §6.12)"
gcloud firestore databases update --database='(default)' --enable-pitr --project "$PROJECT" >/dev/null
if [ -z "$(gcloud firestore backups schedules list --database='(default)' --project "$PROJECT" --format='value(name)')" ]; then
  gcloud firestore backups schedules create --database='(default)' --recurrence=daily \
    --retention=7d --project "$PROJECT"
fi

say "TTL policies (ARCH §6.2)"
for group in notifications rateLimits auditLogs notifyLog; do
  gcloud firestore fields ttls update expiresAt --collection-group="$group" \
    --enable-ttl --async --project "$PROJECT" >/dev/null
  echo "$group.expiresAt"
done

say "Storage bucket $BUCKET"
if ! gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then
  api POST "https://firebasestorage.googleapis.com/v1alpha/projects/$PROJECT/defaultBucket" \
    "{\"location\":\"$REGION\"}"
  echo
fi

# Storage rules check team membership in Firestore (DEVELOPMENT.md): without
# this role every chat photo, team logo, and document upload is refused.
say "Storage rules may read Firestore"
NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:service-$NUMBER@gcp-sa-firebasestorage.iam.gserviceaccount.com" \
  --role=roles/firebaserules.firestoreServiceAgent --condition=None >/dev/null

# The web app loads photos with fetch, so the bucket must allow our sites
# (CORS); without it every photo in the browser is a black box.
say "Storage CORS for the web app (tools/storage-cors.json)"
gcloud storage buckets update "gs://$BUCKET" --cors-file=tools/storage-cors.json >/dev/null

say "Resend API key in Secret Manager (copied from dev)"
if ! gcloud secrets describe RESEND_API_KEY --project "$PROJECT" >/dev/null 2>&1; then
  gcloud secrets versions access latest --secret=RESEND_API_KEY --project "$DEV" |
    firebase functions:secrets:set RESEND_API_KEY --data-file=- --project "$PROJECT"
fi

say "Function-image cleanup policy"
firebase functions:artifacts:setpolicy --location "$REGION" --days 1 --force --project "$PROJECT"

say "Sign-in providers (firebase.json: email and password, Google)"
firebase deploy --only auth --project "$PROJECT" --non-interactive ||
  echo "Turn on Email/Password and Google in the console: Authentication → Sign-in method."

say "Authorized domains"
api PATCH "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT/config?updateMask=authorizedDomains" \
  "{\"authorizedDomains\":[\"localhost\",\"$PROJECT.firebaseapp.com\",\"$PROJECT.web.app\",\"$DOMAIN\"]}" |
  jq -r '.authorizedDomains | join(", ")'

say "Custom domains: $DOMAIN, and www.$DOMAIN redirecting to it"
domains="https://firebasehosting.googleapis.com/v1beta1/projects/$PROJECT/sites/$PROJECT/customDomains"
for d in "$DOMAIN" "www.$DOMAIN"; do
  if ! api GET "$domains/$d" | jq -e '.name' >/dev/null; then
    body='{}'
    [ "$d" = "www.$DOMAIN" ] && body="{\"redirectTarget\":\"$DOMAIN\"}"
    api POST "$domains?customDomainId=$d" "$body" >/dev/null
  fi
done

say "DNS records to add in Cloudflare (DNS only, grey cloud)"
# The records can take a minute to appear after the domains are created.
for d in "$DOMAIN" "www.$DOMAIN"; do
  api GET "$domains/$d" |
    jq -r '.requiredDnsUpdates.desired[]?.records[]? | "\(.type)\t\(.domainName)\t\(.rdata)"' | sort -u
done
echo
echo "Then, after the first release (tools/release_prod.sh) and your first sign-in,"
echo "make yourself a super admin (task 118):"
echo "  npm --prefix tools/seed run super-admin -- $PROJECT <your email>"
