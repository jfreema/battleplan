/// Likely Google Play test accounts (ADMIN-4, ADMIN-9, #52). After every
/// Android upload, Google Play's automatic checks sign up with throwaway
/// accounts: its test lab's domain, or a Gmail address shaped like
/// name.12345@gmail.com. This is a guess for labels only: the admin panel
/// tags them, and nobody is ever blocked or treated differently because of
/// it.
///
/// Functions' copy, functions/src/accounts/play_test.ts, must match this
/// one, and both have the same test cases.
library;

/// Google's test lab.
final _testLab = RegExp(r'@cloudtestlabaccounts\.com$', caseSensitive: false);

/// Letters, a dot, then exactly five digits, at Gmail.
final _playGmail = RegExp(
  r'^[a-z]+\.[0-9]{5}@gmail\.com$',
  caseSensitive: false,
);

/// Whether [email] looks like one of Google Play's test accounts.
bool likelyPlayTestAccount(String? email) {
  final address = email?.trim() ?? '';
  return _testLab.hasMatch(address) || _playGmail.hasMatch(address);
}
