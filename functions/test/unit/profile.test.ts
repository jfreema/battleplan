import { describe, expect, it } from 'vitest';
import { initialDisplayName, needsSetup, signInMethodsOf } from '../../src/accounts/profile.js';

describe('profile helpers', () => {
  it('prefills the name from the provider, else the email', () => {
    expect(initialDisplayName({ uid: 'u', displayName: ' Maria R ', providerIds: [] })).toBe('Maria R');
    expect(initialDisplayName({ uid: 'u', email: 'sam@example.com', providerIds: [] })).toBe('sam');
    expect(initialDisplayName({ uid: 'u', providerIds: [] })).toBe('New member');
  });

  it('keeps only known sign-in methods, once each', () => {
    expect(signInMethodsOf(['google.com', 'password', 'google.com', 'phone'])).toEqual(['google.com', 'password']);
  });

  it('needs setup until both confirmations exist', () => {
    expect(needsSetup({})).toBe(true);
    expect(needsSetup({ adultConfirmedAt: 1 })).toBe(true);
    expect(needsSetup({ adultConfirmedAt: 1, acceptedTermsAt: 1 })).toBe(false);
  });
});
