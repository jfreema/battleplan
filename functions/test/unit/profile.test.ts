import { describe, expect, it } from 'vitest';
import {
  changedEmail,
  choseLastingMethod,
  initialDisplayName,
  needsSetup,
  signInMethodsOf,
} from '../../src/accounts/profile.js';
import { requireVerifiedEmail } from '../../src/shared/guards.js';

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

  it('follows only a verified, different sign-in email (AUTH-8, AUTH-12)', () => {
    expect(changedEmail('old@example.com', 'New@Example.com', true)).toBe('new@example.com');
    expect(changedEmail('old@example.com', 'new@example.com', false)).toBeNull();
    expect(changedEmail('Old@Example.com', 'old@example.com', true)).toBeNull();
    expect(changedEmail('old@example.com', null, true)).toBeNull();
    expect(changedEmail(null, 'new@example.com', true)).toBe('new@example.com');
  });

  it('treats Google or Apple as an added account already choosing (AUTH-6)', () => {
    expect(choseLastingMethod(['password'])).toBe(false);
    expect(choseLastingMethod(['google.com'])).toBe(true);
    expect(choseLastingMethod(['password', 'apple.com'])).toBe(true);
  });
});

describe('requireVerifiedEmail (AUTH-3)', () => {
  const request = (token: object) => ({ auth: { uid: 'u', token } }) as never;
  it('passes a verified email and refuses the rest', () => {
    expect(() => requireVerifiedEmail(request({ email_verified: true }))).not.toThrow();
    expect(() => requireVerifiedEmail(request({ email_verified: false }))).toThrow('email-not-verified');
    expect(() => requireVerifiedEmail(request({}))).toThrow('email-not-verified');
  });
});
