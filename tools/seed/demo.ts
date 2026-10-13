// Creates the App Review demo account and its seeded teams (SPEC §10), on
// the dev project or the local emulators. Never prod (demo-target.ts).
//
// Dev, with your gcloud sign-in (gcloud auth application-default login; no
// key file):
//   DEMO_PASSWORD='<12+ characters>' npm --prefix tools/seed run demo -- \
//     --project battleplan-dev-ecce4 --write-to-dev
// Emulators (firebase emulators:start --project demo-battleplan):
//   npm --prefix tools/seed run demo:emulators
//
// Safe to run again: it resets the demo account's password and rewrites the
// same "demo-" documents. The password goes in the App Review notes only.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { DEMO_UID_FALLBACK, demoDocs } from './demo-data.js';
import { demoTarget } from './demo-target.js';

const target = demoTarget(process.argv.slice(2), process.env);
if ('error' in target) {
  console.error(target.error);
  process.exit(1);
}

initializeApp({
  projectId: target.projectId,
  ...(target.emulators ? {} : { credential: applicationDefault() }),
});
const auth = getAuth();
const db = getFirestore();

async function main(t: Exclude<typeof target, { error: string }>) {
  // The same account each run, so App Review's saved sign-in keeps working.
  const existing = await auth.getUserByEmail(t.email).catch(() => null);
  const user = existing
    ? await auth.updateUser(existing.uid, { password: t.password, emailVerified: true, disabled: false })
    : await auth.createUser({
        uid: DEMO_UID_FALLBACK,
        email: t.email,
        password: t.password,
        displayName: 'App Review',
        emailVerified: true,
      });

  const docs = demoDocs({ uid: user.uid, email: t.email }, new Date());
  // 500 writes per batch is Firestore's limit.
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) batch.set(db.doc(d.path), d.data);
    await batch.commit();
  }
  console.log(`Seeded ${docs.length} documents in ${t.projectId}.`);
  console.log(`Demo account: ${t.email} (${user.uid}). Its password is in DEMO_PASSWORD; put it in the App Review notes.`);
}

main(target).catch((e) => {
  console.error(e);
  process.exit(1);
});
