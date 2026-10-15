#!/usr/bin/env bash
# One-time setup for keyless GitHub Actions deploys (roadmap task 24, ARCH
# §9). Run it once per project from the repo folder, signed in to gcloud and
# gh as the project owner:
#
#   tools/setup_github_deploys.sh dev
#   tools/setup_github_deploys.sh prod
#
# It lets workflows in jfreema/battleplan act as the project's
# github-deployer service account through Workload Identity Federation, with
# no key file anywhere, and gives that account what a full release needs:
# Firestore rules and indexes, Storage rules, Functions, and Hosting.
#
#   dev   any workflow in the repo: CI's deploy on every push to main, and
#         Release to dev (release-dev.yml)
#   prod  only Release to prod (release-prod.yml), started by hand on main;
#         Google refuses a token from any other workflow, branch, or event
#
# Then it saves where to authenticate as repository variables (WIF_PROVIDER
# and WIF_SERVICE_ACCOUNT for dev, the same with _PROD for prod). Safe to
# re-run.
set -euo pipefail

REPO=jfreema/battleplan
SA_NAME=github-deployer
POOL=github
PROVIDER=github

case "${1:-}" in
  dev)
    PROJECT=battleplan-dev-ecce4
    VAR_SUFFIX=
    CONDITION="assertion.repository == '$REPO'"
    ;;
  prod)
    PROJECT=battleplan-prod
    VAR_SUFFIX=_PROD
    CONDITION="assertion.repository == '$REPO' && assertion.event_name == 'workflow_dispatch' && assertion.ref == 'refs/heads/main' && assertion.workflow_ref == '$REPO/.github/workflows/release-prod.yml@refs/heads/main'"
    ;;
  *)
    echo "Usage: $0 dev|prod" >&2
    exit 64
    ;;
esac

SA="$SA_NAME@$PROJECT.iam.gserviceaccount.com"
NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')
# Functions run as the default compute service account; deploying them acts
# as it.
RUNTIME_SA="$NUMBER-compute@developer.gserviceaccount.com"

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com \
  sts.googleapis.com firebasehosting.googleapis.com firebaserules.googleapis.com \
  --project "$PROJECT"

gcloud iam service-accounts describe "$SA" --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam service-accounts create "$SA_NAME" --display-name="GitHub Actions deploys" --project "$PROJECT"

# What a release needs: Hosting; Firestore and Storage rules; indexes;
# Functions (Cloud Functions Admin covers their Cloud Run services and
# Eventarc triggers, and making callables public), their schedules, and
# reading the Resend secret's metadata; and enough to read the project and
# use its APIs.
for role in roles/firebasehosting.admin roles/firebaserules.admin \
  roles/datastore.indexAdmin roles/cloudfunctions.admin roles/cloudscheduler.admin \
  roles/secretmanager.viewer roles/serviceusage.serviceUsageConsumer roles/firebase.viewer; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA" --role="$role" --condition=None >/dev/null
  echo "Granted $role"
done
gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA" --project "$PROJECT" \
  --member="serviceAccount:$SA" --role=roles/iam.serviceAccountUser >/dev/null
echo "Granted roles/iam.serviceAccountUser on $RUNTIME_SA"

# Trust GitHub's OIDC tokens, but only those the condition allows.
gcloud iam workload-identity-pools describe "$POOL" --location=global --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools create "$POOL" --location=global \
    --display-name="GitHub Actions" --project "$PROJECT"
mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.workflow_ref=assertion.workflow_ref"
if gcloud iam workload-identity-pools providers describe "$PROVIDER" --workload-identity-pool="$POOL" \
  --location=global --project "$PROJECT" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers update-oidc "$PROVIDER" \
    --workload-identity-pool="$POOL" --location=global --project "$PROJECT" \
    --attribute-mapping="$mapping" --attribute-condition="$CONDITION" >/dev/null
else
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --workload-identity-pool="$POOL" --location=global --project "$PROJECT" \
    --display-name="GitHub" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="$mapping" --attribute-condition="$CONDITION"
fi

gcloud iam service-accounts add-iam-policy-binding "$SA" --project "$PROJECT" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO" >/dev/null
echo "GitHub Actions in $REPO can now deploy to $PROJECT as $SA"

# Tell the workflows where to authenticate.
gh variable set "WIF_PROVIDER$VAR_SUFFIX" --repo "$REPO" \
  --body "projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/providers/$PROVIDER"
gh variable set "WIF_SERVICE_ACCOUNT$VAR_SUFFIX" --repo "$REPO" --body "$SA"
if [ "$1" = dev ]; then
  gh variable set FIREBASE_DEPLOYS --repo "$REPO" --body true
fi
echo "Done: run Release to ${1} from the Actions tab."
