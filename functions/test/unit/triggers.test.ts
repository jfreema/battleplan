import { describe, expect, it } from 'vitest';
import { snapshotChanged } from '../../src/accounts/triggers.js';

describe('users trigger early exit', () => {
  it('runs only when the name or photo changed', () => {
    const base = { displayName: 'Sam', photoPath: null, themeMode: 'system' };
    expect(snapshotChanged(base, { ...base, themeMode: 'dark' })).toBe(false);
    expect(snapshotChanged(base, { ...base, displayName: 'Sam R' })).toBe(true);
    expect(snapshotChanged(base, { ...base, photoPath: 'users/u/avatar/1.jpg' })).toBe(true);
    expect(snapshotChanged(undefined, base)).toBe(false);
  });
});
