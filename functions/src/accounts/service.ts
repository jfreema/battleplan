// Account domain service: the only code that writes users/{uid} (ARCH §6.4).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { randomUUID } from 'node:crypto';
import type { UserRecord } from 'firebase-admin/auth';
import { HttpsError } from 'firebase-functions/v2/https';
import { auth, db, storage } from '../shared/admin.js';
import { Collections, notificationPrefValues, type NotificationPref } from '../shared/constants.js';
import { anonymizeAuthor } from '../chat/service.js';
import { anonymizeUploader } from '../documents/service.js';
import { removeAccountNotifications, removeDevices } from '../notify/service.js';
import { removeAccountFromPlayers } from '../players/service.js';
import { removeAccountBlocks } from '../safety/service.js';
import { removeUpcomingRsvps } from '../schedule/service.js';
import { removeAccountFromTeams, updateMemberSnapshots } from '../teams/service.js';
import {
  accountSetupEmail,
  methodName,
  passwordResetEmail,
  securityNoticeEmail,
  setupEmail,
} from '../email/templates.js';
import { sendEmail } from '../email/service.js';
import { activateUrl } from '../links/service.js';
import { projectId } from '../shared/project.js';
import { initialDisplayName, needsSetup, signInMethodsOf, type AuthIdentity } from './profile.js';

/** Every global notification switch on (NOTIF-4); the server reads a missing key as on. */
export function defaultNotificationPrefs(): Record<NotificationPref, boolean> {
  return Object.fromEntries(notificationPrefValues.map((k) => [k, true])) as Record<NotificationPref, boolean>;
}

export interface SetupInput {
  displayName: string;
  confirmAdult: true;
  acceptTerms: true;
}

export interface ProfileResult {
  created: boolean;
  activated?: boolean;
  needsSetup: boolean;
}

/**
 * Creates users/{uid} at first sign-in, or returns it as is (idempotent).
 * Provider details are used once, here, to prefill the profile; after that
 * only the person changes it (AUTH-12). With [setup], it also records the
 * 18+ confirmation and Terms acceptance and the chosen name (AUTH-5).
 */
export async function ensureUserProfile(uid: string, setup?: SetupInput): Promise<ProfileResult> {
  const user = await auth().getUser(uid);
  const identity: AuthIdentity = {
    uid,
    email: user.email,
    displayName: user.displayName,
    providerIds: user.providerData.map((p) => p.providerId),
  };
  const ref = db().collection(Collections.users).doc(uid);

  const result = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = FieldValue.serverTimestamp();
    let created = false;
    let activated = false;
    let data = snap.data();

    if (!snap.exists) {
      created = true;
      const name = initialDisplayName(identity);
      const email = identity.email ?? null;
      data = {
        displayName: name,
        displayNameLower: name.toLowerCase(),
        email,
        emailLower: email?.toLowerCase() ?? null,
        photoPath: null,
        status: 'active',
        signInMethods: signInMethodsOf(identity.providerIds),
        themeMode: 'system',
        notificationPrefs: defaultNotificationPrefs(),
        acceptedTermsAt: null,
        adultConfirmedAt: null,
        lastActiveAt: now,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      };
      tx.set(ref, data);
    } else if (data?.status === 'provisioned') {
      // An admin-added account signing in for the first time (AUTH-6).
      tx.update(ref, {
        status: 'active',
        signInMethods: signInMethodsOf(identity.providerIds),
        updatedAt: now,
      });
      activated = true;
    }

    if (setup) {
      const name = setup.displayName.trim().slice(0, 50);
      const update = {
        displayName: name,
        displayNameLower: name.toLowerCase(),
        adultConfirmedAt: now,
        acceptedTermsAt: now,
        updatedAt: now,
      };
      if (created) {
        tx.set(ref, { ...data, ...update });
      } else {
        tx.update(ref, update);
      }
      return { created, activated, needsSetup: false };
    }
    return { created, activated, needsSetup: needsSetup(data ?? {}) };
  });

  if (result.activated) await clearPendingMemberships(uid);

  if (result.created && user.photoURL) {
    await copyProviderPhoto(uid, user.photoURL);
  }
  return result;
}

/**
 * Copies the provider's photo into our Storage once, so the profile never
 * depends on a provider URL (ARCH §6.1). Failures are logged, never fatal.
 */
async function copyProviderPhoto(uid: string, url: string): Promise<void> {
  try {
    const response = await fetch(url);
    const type = response.headers.get('content-type') ?? '';
    if (!response.ok || !type.startsWith('image/')) return;
    const bytes = Buffer.from(await response.arrayBuffer());
    if (bytes.length > 5 * 1024 * 1024) return;
    const path = `users/${uid}/avatar/${randomUUID()}.jpg`;
    await storage().bucket().file(path).save(bytes, { contentType: type, resumable: false });
    await db().collection(Collections.users).doc(uid).update({
      photoPath: path,
      updatedAt: Timestamp.now(),
    });
  } catch (e) {
    logger.warn('Could not copy the provider photo', { uid, error: String(e) });
  }
}

/**
 * Ends every session for [uid] (AUTH-9): revokes refresh tokens, so other
 * devices are signed out when their current ID token expires (within an
 * hour) and can't refresh it, and removes every device so pushes stop
 * right away (NOTIF-10).
 */
export async function signOutEverywhere(uid: string): Promise<void> {
  await auth().revokeRefreshTokens(uid);
  await removeDevices(uid);
}

/** A person's display name for notification wording, or [fallback]. */
export async function displayNameOf(uid: string, fallback: string): Promise<string> {
  const profile = await db().collection(Collections.users).doc(uid).get();
  return (profile.get('displayName') as string | undefined) || fallback;
}

/**
 * Re-reads the caller's sign-in methods from Firebase Auth into
 * users.signInMethods after the app adds or removes one (AUTH-7). Returns
 * what changed. The emailed security notice joins once email sending exists
 * (roadmap task 46); until then the change is logged.
 */
export async function recordSignInMethodChange(
  uid: string,
): Promise<{ added: string[]; removed: string[] }> {
  const user = await auth().getUser(uid);
  const now = signInMethodsOf(user.providerData.map((p) => p.providerId));
  const ref = db().collection(Collections.users).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return { added: [], removed: [] };
  const before: string[] = snap.get('signInMethods') ?? [];
  const added = now.filter((m) => !before.includes(m));
  const removed = before.filter((m) => !now.includes(m));
  if (added.length || removed.length) {
    await ref.update({ signInMethods: now, updatedAt: FieldValue.serverTimestamp() });
    logger.info('sign_in_methods_changed', { uid, added, removed });
    // AUTH-7: tell the account's email about every change.
    const email = (snap.get('email') as string | undefined) ?? user.email;
    if (email) {
      const change = [
        ...added.map((m) => `${methodName(m)} sign-in was added to your Battleplan account.`),
        ...removed.map((m) => `${methodName(m)} sign-in was removed from your Battleplan account.`),
      ].join(' ');
      await sendEmail(securityNoticeEmail(email, change));
    }
  }
  return { added, removed };
}

/**
 * Deletes an account (AUTH-10, required by both stores). Each domain clears
 * its own data through its service (a deleted person's messages and
 * documents stay, from "Deleted user"); then the profile, avatar files, and the
 * Auth user go. Safe to retry: every step skips what's already gone.
 */
export async function deleteAccount(uid: string): Promise<void> {
  await removeAccountFromTeams(uid);
  await removeAccountFromPlayers(uid);
  await removeUpcomingRsvps(uid);
  await anonymizeAuthor(uid);
  await anonymizeUploader(uid);
  await removeAccountNotifications(uid);
  await removeAccountBlocks(uid);
  await storage()
    .bucket()
    .deleteFiles({ prefix: `users/${uid}/` })
    .catch((e) => logger.warn('Avatar cleanup failed', { uid, error: String(e) }));
  await db().collection(Collections.users).doc(uid).delete();
  await auth()
    .deleteUser(uid)
    .catch((e: { code?: string }) => {
      if (e.code !== 'auth/user-not-found') throw e;
    });
  logger.info('account_deleted', { uid });
}

export interface FoundUser {
  uid: string;
  displayName: string;
  photoPath: string | null;
  /** True if the account was just created and the person hasn't signed in. */
  provisioned: boolean;
}

/**
 * The account for [email], creating an added ("local") account if there is
 * none (AUTH-6): a Firebase Auth user with no password and a users doc with
 * status "provisioned". Nobody ever sets or sees its password; the person
 * gets in through a setup email.
 */
export async function findOrProvisionUser(email: string, name: string | null): Promise<FoundUser> {
  const address = email.trim().toLowerCase();
  try {
    const existing = await auth().getUserByEmail(address);
    const profile = await db().collection(Collections.users).doc(existing.uid).get();
    return {
      uid: existing.uid,
      displayName: (profile.get('displayName') as string | undefined) ?? existing.displayName ?? address,
      photoPath: (profile.get('photoPath') as string | null | undefined) ?? null,
      provisioned: profile.get('status') === 'provisioned',
    };
  } catch (e) {
    if ((e as { code?: string }).code !== 'auth/user-not-found') throw e;
  }
  const displayName = (name?.trim() || address.split('@')[0]).slice(0, 50);
  const user = await auth().createUser({ email: address, displayName, emailVerified: false });
  const now = FieldValue.serverTimestamp();
  await db().collection(Collections.users).doc(user.uid).set({
    displayName,
    displayNameLower: displayName.toLowerCase(),
    email: address,
    emailLower: address,
    photoPath: null,
    status: 'provisioned',
    signInMethods: [],
    themeMode: 'system',
    notificationPrefs: defaultNotificationPrefs(),
    acceptedTermsAt: null,
    adultConfirmedAt: null,
    lastActiveAt: null,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  });
  return { uid: user.uid, displayName, photoPath: null, provisioned: true };
}

/**
 * A one-time setup link for an added account (AUTH-6): an email-link
 * sign-in that lands on /activate, opening the app through App Links.
 */
export async function setupLink(email: string): Promise<string> {
  const prod = projectId() === 'battleplan-prod';
  const bundle = prod ? 'app.getbattleplan' : 'app.getbattleplan.dev';
  return auth().generateSignInWithEmailLink(email, {
    url: activateUrl(),
    handleCodeInApp: true,
    iOS: { bundleId: bundle },
    android: { packageName: bundle, installApp: false },
    // linkDomain must be a custom domain (M0 spike 2): only prod has one.
    ...(prod ? { linkDomain: 'getbattleplan.app' } : {}),
  });
}

/** Sends the setup email for an added account. Returns false if not sent. */
export async function sendSetupEmail(email: string, teamName: string, addedBy: string): Promise<boolean> {
  const link = await setupLink(email);
  return sendEmail(setupEmail(email, teamName, addedBy, link));
}

/** When an added account signs in, its memberships stop showing "Not joined yet". */
export async function clearPendingMemberships(uid: string): Promise<void> {
  const memberships = await db().collection(Collections.groupMembers).where('uid', '==', uid).limit(100).get();
  const pending = memberships.docs.filter((d) => d.get('pending') === true);
  if (!pending.length) return;
  const batch = db().batch();
  pending.forEach((d) => batch.update(d.ref, { pending: false }));
  await batch.commit();
}

// ---- Super admin account actions (ADMIN-4) ---------------------------------
// The admin callables check the superAdmin claim; these do the work.

/** The users doc for [uid], or `not-found`. */
async function profileOrThrow(uid: string): Promise<FirebaseFirestore.DocumentSnapshot> {
  const profile = await db().collection(Collections.users).doc(uid).get();
  if (!profile.exists) throw new HttpsError('not-found', 'No such user.');
  return profile;
}

/** Whether [e] is Firebase Auth's "no such user". */
function isUserNotFound(e: unknown): boolean {
  return (e as { code?: string }).code === 'auth/user-not-found';
}

/**
 * Sends a setup email for an account a super admin created without a team
 * (ADMIN-4, AUTH-6): the same one-time sign-in link as an added member gets.
 */
export async function sendAccountSetupEmail(email: string, addedBy: string): Promise<boolean> {
  const link = await setupLink(email);
  return sendEmail(accountSetupEmail(email, addedBy, link));
}

/**
 * Renames a person (ADMIN-4): the profile and the copies on their
 * memberships, which the roster and new messages read. Returns the old name.
 */
export async function setDisplayName(uid: string, displayName: string): Promise<string> {
  const profile = await profileOrThrow(uid);
  const name = displayName.trim().slice(0, 50);
  await profile.ref.update({
    displayName: name,
    displayNameLower: name.toLowerCase(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  // A callable does its own follow-up (ARCH §6.4 rule 3); the users trigger
  // writes the same values again, which changes nothing.
  await updateMemberSnapshots(uid, name, (profile.get('photoPath') as string | null | undefined) ?? null);
  return (profile.get('displayName') as string | undefined) ?? '';
}

/**
 * Disables or re-enables an account (ADMIN-4, SAFE-4). Disabling blocks
 * sign-in in Firebase Auth, signs the person out everywhere, and marks the
 * profile 'disabled' (notify drops disabled accounts). Enabling puts the
 * profile back to 'active', or 'provisioned' if they never signed in (no
 * sign-in methods yet).
 * Returns the profile's status before.
 */
export async function setAccountDisabled(uid: string, disabled: boolean): Promise<string> {
  const profile = await profileOrThrow(uid);
  const before = (profile.get('status') as string | undefined) ?? 'active';
  await auth().updateUser(uid, { disabled });
  // An added account that never signed in has no sign-in methods yet (AUTH-6).
  const methods = (profile.get('signInMethods') as string[] | undefined) ?? [];
  const status = disabled ? 'disabled' : methods.length ? 'active' : 'provisioned';
  await profile.ref.update({ status, updatedAt: FieldValue.serverTimestamp() });
  if (disabled) await signOutEverywhere(uid);
  return before;
}

/**
 * Emails [uid] a link to choose a new password (ADMIN-4, AUTH-6). Nobody
 * but the person ever sets or sees the password; the link isn't returned.
 */
export async function sendPasswordReset(uid: string): Promise<void> {
  const profile = await profileOrThrow(uid);
  const user = await requireAccount(uid);
  const email = (profile.get('email') as string | null | undefined) ?? user.email;
  if (!email) throw new HttpsError('failed-precondition', 'no-email');
  const link = await auth().generatePasswordResetLink(email);
  await sendEmail(passwordResetEmail(email, link));
}

/**
 * Grants or revokes the superAdmin claim (ARCH §6.1), keeping the person's
 * other claims, and keeps users.superAdmin in step so super admins can be
 * listed and counted. Revoking also revokes their refresh tokens, so the
 * power goes with their sessions instead of lingering on a signed-in
 * device; a grant applies when the app refreshes its token. Returns
 * whether they had the claim before.
 */
export async function setSuperAdminClaim(uid: string, superAdmin: boolean): Promise<boolean> {
  const user = await requireAccount(uid);
  const claims: Record<string, unknown> = { ...(user.customClaims ?? {}) };
  const before = claims.superAdmin === true;
  if (superAdmin) claims.superAdmin = true;
  else delete claims.superAdmin;
  await auth().setCustomUserClaims(uid, claims);
  await db()
    .collection(Collections.users)
    .doc(uid)
    .update({ superAdmin, updatedAt: FieldValue.serverTimestamp() })
    .catch((e: { code?: number }) => {
      if (e.code !== 5) throw e; // 5 = NOT_FOUND: no profile yet, the claim is enough
    });
  if (!superAdmin) await auth().revokeRefreshTokens(uid);
  return before;
}

/** The uid of the account with [email] in Firebase Auth, or null. */
export async function uidForEmail(email: string): Promise<string | null> {
  try {
    return (await auth().getUserByEmail(email.trim().toLowerCase())).uid;
  } catch (e) {
    if (isUserNotFound(e)) return null;
    throw e;
  }
}

/** The account's Firebase Auth record, or `not-found`. */
export async function requireAccount(uid: string): Promise<UserRecord> {
  try {
    return await auth().getUser(uid);
  } catch (e) {
    if (isUserNotFound(e)) throw new HttpsError('not-found', 'No such user.');
    throw e;
  }
}

/** The account's sign-in email in Firebase Auth, or `not-found` / `no-email`. */
export async function authEmailOf(uid: string): Promise<string> {
  const email = (await requireAccount(uid)).email;
  if (!email) throw new HttpsError('failed-precondition', 'no-email');
  return email;
}
