// Account domain service: the only code that writes users/{uid} (ARCH §6.4).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { randomUUID } from 'node:crypto';
import { auth, db, storage } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { initialDisplayName, needsSetup, signInMethodsOf, type AuthIdentity } from './profile.js';

export interface SetupInput {
  displayName: string;
  confirmAdult: true;
  acceptTerms: true;
}

export interface ProfileResult {
  created: boolean;
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
        notificationPrefs: {
          messages: true,
          replies: true,
          mentions: true,
          polls: true,
          events: true,
          reminders: true,
          documents: true,
        },
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
      tx.update(ref, { status: 'active', updatedAt: now });
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
      return { created, needsSetup: false };
    }
    return { created, needsSetup: needsSetup(data ?? {}) };
  });

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
 * hour) and can't refresh it.
 */
export async function signOutEverywhere(uid: string): Promise<void> {
  await auth().revokeRefreshTokens(uid);
}
