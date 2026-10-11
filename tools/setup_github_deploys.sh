#!/usr/bin/env bash
# One-time setup for keyless GitHub Actions deploys to the dev project
# (roadmap task 24, ARCH §9). Run it once from the repo folder, signed in to
# gcloud and gh as the project owner:
#
#   tools/setup_github_deploys.sh
#
# It lets workflows in jfreema/battleplan (and only that repo) act as the
# github-deployer service account through Workload Identity Federation, with
# no key file anywhere, and gives that account just enough access to deploy
# Hosting, Firestore rules, and indexes. Safe to re-run.
set -euo pipefail

PROJECT=battleplan-dev-ecce4
REPO=jfreema/battleplan
SA_NAME=github-deployer
SA="$SA_NAME@$PROJECT.iam.gserviceaccount.com"
POOL=github
PROVIDER=github

NUMBER=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com \
  sts.googleapis.com firebasehosting.googleapis.com firebaserules.googleapis.com \
  --project "$PROJECT"

gcloud iam service-accounts describe "$SA" --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam service-accounts create "$SA_NAME" --display-name="GitHub Actions deploys" --project "$PROJECT"

# What the deploy job needs: Hosting, Firestore rules and indexes, and enough
# to read the project and use its APIs.
for role in roles/firebasehosting.admin roles/firebaserules.admin \
  roles/datastore.indexAdmin roles/serviceusage.serviceUsageConsumer roles/firebase.viewer; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA" --role="$role" --condition=None >/dev/null
  echo "Granted $role"
done

# Trust GitHub's OIDC tokens, but only from this repository.
gcloud iam workload-identity-pools describe "$POOL" --location=global --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools create "$POOL" --location=global \
    --display-name="GitHub Actions" --project "$PROJECT"
gcloud iam workload-identity-pools providers describe "$PROVIDER" --workload-identity-pool="$POOL" \
  --location=global --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --workload-identity-pool="$POOL" --location=global --project "$PROJECT" \
    --display-name="GitHub" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository == '$REPO'"

gcloud iam service-accounts add-iam-policy-binding "$SA" --project "$PROJECT" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO" >/dev/null
echo "GitHub Actions in $REPO can now deploy as $SA"

# Tell the workflow where to authenticate, and switch deploys on.
gh variable set WIF_PROVIDER --repo "$REPO" \
  --body "projects/$NUMBER/locations/global/workloadIdentityPools/$POOL/providers/$PROVIDER"
gh variable set WIF_SERVICE_ACCOUNT --repo "$REPO" --body "$SA"
gh variable set FIREBASE_DEPLOYS --repo "$REPO" --body true
echo "Done. The next push to main deploys to https://$PROJECT.web.app"
