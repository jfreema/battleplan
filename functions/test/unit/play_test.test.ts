// Likely Google Play test accounts (#52): the same cases as the app's
// test/play_test_test.dart, since the two copies of the rule must match.
import { describe, expect, it } from 'vitest';
import { likelyPlayTestAccount } from '../../src/accounts/play_test.js';
import { newAccountEmail, signupSpikeEmail } from '../../src/email/templates.js';

describe('likelyPlayTestAccount', () => {
  it("knows Google's test lab and Gmail shaped like name.12345", () => {
    for (const email of ['jane.48213@gmail.com', 'x@cloudtestlabaccounts.com', 'JANE.48213@GMAIL.COM', ' jane.48213@gmail.com ']) {
      expect(likelyPlayTestAccount(email), email).toBe(true);
    }
  });

  it('leaves everyone else alone', () => {
    for (const email of [
      'jane48213@gmail.com',
      'jane.4821@gmail.com',
      'jane.482131@gmail.com',
      'jane.48213@yahoo.com',
      'jane.smith@gmail.com',
      'jane.48213@gmail.com.example',
      '',
    ]) {
      expect(likelyPlayTestAccount(email), email).toBe(false);
    }
    expect(likelyPlayTestAccount(null)).toBe(false);
    expect(likelyPlayTestAccount(undefined)).toBe(false);
  });
});

describe('the emails (ADMIN-9)', () => {
  const pat = { name: 'Pat Lee', email: 'pat@example.com', methods: ['Google'], addedByAdmin: false };

  it('labels a likely Google Play test account, and only that', () => {
    const plain = newAccountEmail('root@example.com', pat, 'https://app.test/admin/users/pat');
    expect(plain.subject).toBe('New account: Pat Lee');
    expect(plain.text).not.toContain('Google Play');
    const test = newAccountEmail(
      'root@example.com',
      { ...pat, email: 'jane.48213@gmail.com', playTest: true },
      'https://app.test/admin/users/jane',
    );
    expect(test.subject).toBe('New account (likely Google Play test): Pat Lee');
    expect(test.text.split('\n\n')[0]).toBe(
      "This looks like one of Google Play's test accounts, from its automatic checks after an Android upload. " +
        'Nothing needs doing.',
    );
    expect(test.text).toContain('Pat Lee (jane.48213@gmail.com) finished signing up for BattlePlan, with Google.');
  });

  it('names up to 20 in a spike, then how many more', () => {
    const people = Array.from({ length: 20 }, (_, i) => ({ name: `Person ${i + 1}`, email: `p${i + 1}@example.com` }));
    const spike = signupSpikeEmail('root@example.com', { count: 27, people }, 'https://app.test/admin/users');
    expect(spike.subject).toBe('Sign-up spike: 27 new accounts in the last hour');
    expect(spike.text).toContain('27 new accounts finished signing up for BattlePlan in the last hour:');
    expect(spike.text).toContain('Person 1 (p1@example.com)');
    expect(spike.text).toContain('Person 20 (p20@example.com)');
    expect(spike.text).toContain('and 7 more');
    expect(spike.text).toContain(
      "If these look like bots, you can disable them on the Users page. Google Play test accounts aren't counted.",
    );
    expect(spike.text).toContain('Open Users: https://app.test/admin/users');
    const ten = signupSpikeEmail('root@example.com', { count: 10, people: people.slice(0, 10) }, 'https://x');
    expect(ten.text).not.toContain('more');
  });
});
