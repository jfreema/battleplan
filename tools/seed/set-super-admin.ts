// Grants or revokes the superAdmin claim (ARCH §6.1). The first super admin
// is set this way; after that, super admins manage the claim in the admin
// panel. Uses your gcloud sign-in, so no service-account key file exists.
//
//   npm --prefix tools/seed run super-admin -- <project> <email> [--revoke]
//   e.g. npm --prefix tools/seed run super-admin -- battleplan-dev-ecce4 you@gmail.com
//
// The person must have signed in once (their Auth account must exist). They
// see the change after their token refreshes (within an hour, or on sign-in).
import { execSync } from 'node:child_process';

const [project, email, flag] = process.argv.slice(2);
if (!project || !email) {
  console.error('Usage: set-super-admin <project> <email> [--revoke]');
  process.exit(1);
}
const grant = flag !== '--revoke';
const token = execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
const base = `https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts`;
const headers = {
  Authorization: `Bearer ${token}`,
  'x-goog-user-project': project,
  'Content-Type': 'application/json',
};

async function call(path: string, body: unknown) {
  const res = await fetch(`${base}:${path}`, { method: 'POST', headers, body: JSON.stringify(body) });
  const json = await res.json();
  if (!res.ok) throw new Error(`${path} failed: ${JSON.stringify(json)}`);
  return json;
}

const lookup = await call('lookup', { email: [email] });
const user = lookup.users?.[0];
if (!user) {
  console.error(`No account for ${email} in ${project}. Sign in once first.`);
  process.exit(1);
}
const claims = JSON.parse(user.customAttributes ?? '{}');
if (grant) claims.superAdmin = true;
else delete claims.superAdmin;
await call('update', { localId: user.localId, customAttributes: JSON.stringify(claims) });
console.log(`${grant ? 'Granted' : 'Revoked'} superAdmin for ${email} (${user.localId}) in ${project}.`);
