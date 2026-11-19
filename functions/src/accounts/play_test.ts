// Likely Google Play test accounts (ADMIN-4, ADMIN-9, #52). After every
// Android upload, Google Play's automatic checks sign up with throwaway
// accounts: its test lab's domain, or a Gmail address shaped like
// name.12345@gmail.com. This is a guess for labels only: the new-account
// email says so, the admin panel tags them, and sign-up spikes leave them
// out. Nobody is ever blocked or treated differently because of it.
//
// The app's copy, lib/features/admin/domain/play_test.dart, must match this
// one, and both have the same test cases.

/** Google's test lab. */
const TEST_LAB = /@cloudtestlabaccounts\.com$/i;

/** Letters, a dot, then exactly five digits, at Gmail. */
const PLAY_GMAIL = /^[a-z]+\.[0-9]{5}@gmail\.com$/i;

/** Whether [email] looks like one of Google Play's test accounts. */
export function likelyPlayTestAccount(email: string | null | undefined): boolean {
  const address = email?.trim() ?? '';
  return TEST_LAB.test(address) || PLAY_GMAIL.test(address);
}
