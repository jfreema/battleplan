// Pure helpers for building the Battleplan profile (users/{uid}), kept free
// of Firebase so they can be unit tested.

/** What the profile needs from the Firebase Auth user. */
export interface AuthIdentity {
  uid: string;
  email?: string | null;
  displayName?: string | null;
  providerIds: string[];
}

export const SIGN_IN_METHODS = ['password', 'google.com', 'apple.com'] as const;

/** The sign-in methods we track (users.signInMethods, a cache of Auth). */
export function signInMethodsOf(providerIds: string[]): string[] {
  const known = new Set<string>(SIGN_IN_METHODS);
  // Email-link sign-in reports as "password" in providerData.
  return [...new Set(providerIds.filter((p) => known.has(p)))].sort();
}

/** A display name for a new profile: the provider's name, else the email's local part. */
export function initialDisplayName(identity: AuthIdentity): string {
  const name = identity.displayName?.trim();
  if (name) return name.slice(0, 50);
  const local = identity.email?.split('@')[0]?.trim();
  return local ? local.slice(0, 50) : 'New member';
}

/** True once the first-run setup is finished (AUTH-5). */
export function needsSetup(profile: { adultConfirmedAt?: unknown; acceptedTermsAt?: unknown }): boolean {
  return profile.adultConfirmedAt == null || profile.acceptedTermsAt == null;
}

/**
 * The new contact email when the sign-in email changed through the verified
 * change-email flow (AUTH-8, AUTH-12), else null. users.email follows only a
 * verified Auth email, so nobody can point the profile at an address they
 * don't own.
 */
export function changedEmail(
  profileEmail: string | null | undefined,
  authEmail: string | null | undefined,
  authEmailVerified: boolean,
): string | null {
  const next = authEmail?.trim().toLowerCase();
  if (!next || !authEmailVerified) return null;
  return next === profileEmail?.trim().toLowerCase() ? null : next;
}

/** True when an added account's first sign-in already chose a lasting method (AUTH-6). */
export function choseLastingMethod(providerIds: string[]): boolean {
  return providerIds.includes('google.com') || providerIds.includes('apple.com');
}
