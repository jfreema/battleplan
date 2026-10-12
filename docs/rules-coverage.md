# Security-rules test coverage

The roadmap task 104 review of `firestore.rules` and `storage.rules` against the rules tests in `functions/test/rules/` (run with `npm --prefix functions run emulators:test`). ARCH §9 asks for every collection and role to be tested. The Functions tests in `functions/test/emulator/` run as the Admin SDK, which skips rules, so they don't count here. There's no `test/emulator` in the Flutter app.

Reviewed 2026-10-12. Update this page whenever a rule or a rules test changes.

**Legend:** ✓ tested and allowed · ✗ tested and refused · ✓\* / ✗\* added in this review (`coverage.test.ts`) · `=` the rule can't tell this role from the column to its left, so that test covers it · `·` doesn't apply · **gap** not tested.

**Roles:** *Signed out* has no auth. *Other team* is an admin or member of another team. *Member* is on the team. *Guardian* is a member linked to the player. *Admin* has the team's `admin` role. *Owner* has `owner`; the rules treat it like admin everywhere (checked in `coverage.test.ts`). *Super admin* has the `superAdmin` claim and isn't on the team.

**Test files:** F `firestore.test.ts`, T `teams.test.ts`, A `admin.test.ts`, P `polls.test.ts`, S `schedule.test.ts`, D `documents.test.ts`, N `notifications.test.ts`, U `users.test.ts`, St `storage.test.ts`, C `coverage.test.ts`.

## Bugs found and fixed

1. **Storage ignored suspension.** `storage.rules`' `isMember` didn't check `suspendedAt`, unlike Firestore's, so members of a suspended team could still read its files and upload chat photos, documents, a logo, and a background. Fixed: membership needs an unsuspended team. Super admins still read (View team). Test: C "a suspended team".
2. **Storage took uploads on archived teams.** TEAM-9 makes archived teams read-only, but every Storage upload rule only checked the quota. Fixed: `underQuota` also needs `archivedAt == null`, for everyone, super admins included. Test: C "an archived team".
3. **Players stayed editable on archived teams.** The `players` update rule had no `active()`, so guardians and admins could rename players on an archived team. Fixed. Test: C "freezes the roster".

Each new test fails against the old rules and passes against the new ones. The Storage fix stays within the two Firestore documents a Storage rule may read (the membership and the team).

## Team collections (Firestore)

| Collection | Operation | Signed out | Other team | Member | Guardian | Admin | Owner | Super admin | Tests |
|---|---|---|---|---|---|---|---|---|---|
| `groups` | get | ✗ | ✗ | ✓\* | ✓\* | ✓\* | ✓ | ✓ | F, A, C |
| | list | ✗\* | · | ✗\* | = | = | = | ✗\* | C |
| | create, delete | ✗\* | · | · | · | · | ✗ | · | T, C |
| | update (profile, settings, chat look) | ✗\* | ✗ | ✗ | ✗\* | ✓ | ✓ | ✗ | F, T, A, St, C |
| | update storage fields | · | · | ✗ | · | · | ✗ | ✗ | St |
| `groupMembers` | get, list (roster) | ✗\* | ✗ | ✓ | = | = | = | ✓ | T, A, F |
| | list own (switcher) | · | ✗ (others') | ✓ | = | = | = | · | F |
| | create, delete | ✗\* | ✗ | ✗ | · | · | ✗ | ✗ | T, A |
| | update own prefs and read marks | · | · | ✓ | = | = | = | · | F, N |
| | update role or another's doc | ✗\* | · | ✗ | · | · | ✗ | ✗ | F, T, A |
| `players` | get, list | ✗\* | ✗ | ✓ | ✓\* | = | = | ✓ | T, A, C |
| | create, delete | ✗\* | · | · | · | ✗ (✗\* delete) | · | · | F, C |
| | update (name, number, position) | ✗\* | ✗ | ✗ | ✓ | ✓ | ✓\* | ✗ | F, A, C |
| `playerGuardians` | get, list | ✗\* | ✗ | ✓ | ✓\* | = | = | ✓ | T, A, C |
| | create, update, delete | ✗\* | · | ✗ | ✗ | ✗ (✗\* update) | · | · | T, C |
| `guardianRequests` | get, list | ✗\* | ✗ | ✗ (others'), ✓ (own) | = | ✓ | = | ✓ | T, A |
| | create, update, delete | ✗\* | · | ✗ (✗\* delete) | · | ✗ (✗\* delete) | · | · | T, C |
| `messages` | get, list | ✗ | ✗ | ✓ | = | ✓ | = | ✓ | F, A |
| | create (rate limit, author snapshot, photos) | ✗\* | ✗ | ✓ | = | = | ✓ | ✗ | F, P, St, A |
| | update reactions | ✗\* | ✗ | ✓ | ✓ | ✓ | = | ✗ | F, A |
| | update text (author only) | ✗\* | ✗ | ✓ / ✗ (others') | = | = | ✗\* (others') | · | F, C |
| | delete | ✗\* | · | ✗\* | · | · | ✗\* | ✗\* | C |
| `polls` | get, list | ✗\* | ✗ | ✓\* | = | = | = | ✓ | A, C |
| | create (with its message) | ✗\* | ✗ | ✓ | = | = | ✓ | **gap**¹ | P |
| | update, delete | ✗\* | · | · | · | · | ✗ | · | P |
| `pollVotes` | get, list (open ballot) | ✗\* | ✗ | ✓ | = | = | = | ✓ | P, A |
| | get, list (anonymous: only your own) | · | · | ✓ own, ✗ others' | = | = | ✗ | ✗ | P, A |
| | create, update | ✗\* | ✗ | ✓ | = | = | = | ✗ | P, A |
| | delete (own, open poll) | ✗\* | · | ✓ / ✗ (others') | = | = | = | · | P |
| `eventSeries` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | S, A |
| | create, update, delete | ✗\* | · | · | · | · | ✗ | ✗\* | S, C |
| `events` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | S, A |
| | create | ✗\* | ✗ | ✓ / ✗ (setting) | = | ✓ | ✓\* | ✗\* | S, C |
| | update, cancel | ✗\* | ✗\* | ✓ creator / ✗ | = | = | ✓ | ✓ | S, C |
| | delete | ✗\* | ✗ | ✓ creator / ✗ | = | ✓ | ✓ | ✓ | S |
| `rsvps` | get, list | ✗\* | ✗ | ✓\* | = | = | = | ✓ | A, C |
| | create, update | ✗\* | ✗ | ✓ self / ✗ others | ✓ player / ✗ non-guardian | ✓ anyone | ✓ | ✗ | F, S, A |
| | delete | ✗\* | · | ✗ | · | · | · | · | S |
| `groupDocuments` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | D, A |
| | create | ✗\* | ✗ | ✓ / ✗ (setting) | = | ✓ | ✓ | ✗ | D, A |
| | update | ✗\* | ✗ | ✓ uploader / ✗ | = | ✓ (pins) | ✓ | **gap**² | D |
| | delete | ✗\* | ✗ | ✓ uploader / ✗ | = | ✓ | ✓ | ✓ | D |
| `reports` | get, list | ✗\* | ✗ | ✗ | ✗\* | ✓ | ✓ | ✓ | T, A, C |
| | create, update, delete | ✗\* | · | ✗ | · | ✗ | · | ✗ | T, A |

Team states, for every collection above: **archived** teams refuse every member and admin write (F, P, S, D, St, C), keep reads, and still take each person's own mute and read marks (C, on purpose). **Suspended** teams refuse members' reads and writes in every collection (F, C) while super admins still read (A); people still see their own membership and notifications (C).

¹ A super admin can't create a poll because the paired message needs membership, which A tests; the poll rule's own `isMember` isn't tested alone.
² `docEditorOk` lets super admins update documents too (for SAFE-4 they delete); nothing tests a super admin's rename.

## Personal and platform collections (Firestore)

| Collection | Operation | Signed out | Yourself | Someone else | Super admin | Tests |
|---|---|---|---|---|---|---|
| `users` | get | ✗ | ✓ | ✗ | ✓ | U |
| | list | ✗\* | ✗ | · | · | U, C |
| | update | ✗\* | ✓ (own fields, valid values) | ✗ | ✗\* | U, N, A, C |
| | create, delete | ✗\* | ✗ | · | · | U |
| `devices` | get, delete | ✗\* | ✓ | ✗ | ✗\* | N, C |
| | create, update | ✗\* | ✓ (valid only) | ✗ (in another uid) | · | N |
| `userBlocks` | get | ✗\* | ✓ | ✗ | · | T |
| | list | ✗\* | ✓\* | ✗\* | ✗\* | C |
| | create, delete | ✗\* | ✓ | ✗ | ✗\* | T, C |
| `notifications` | get, list | ✗\* | ✓ | ✗ | ✗\* | N, C |
| | update (`read: true` only) | ✗\* | ✓ | ✗ | · | N |
| | create, delete | ✗\* | ✗ | · | · | N |
| `auditLogs` | get, list | ✗\* | · | ✗ (owner) | ✓ (bounded) | A, T |
| | write | ✗\* | · | ✗ | ✗ | A, T |
| `config/app` | get | ✗ | ✓ | · | ✓ | A |
| | write | ✗\* | ✗ | · | ✗ | A |
| `config/*` (others) | any | · | ✗ | · | ✗ | A |
| `invites` | any | ✗ | · | ✗ (owner) | ✗\* | T, F, C |
| `rateLimits` | any | ✗\* | ✗ | · | ✗\* | F, T, C |

## Storage

| Path | Operation | Signed out | Other team | Member | Admin / owner | Super admin | Tests |
|---|---|---|---|---|---|---|---|
| `users/{uid}/avatar/*` | read | ✗ | ✓ (any signed in) | ✓ | = | = | U |
| | write | ✗\* | ✗ (another's folder) | ✓ own, images only | = | · | U |
| `groups/{g}/avatar/*` | read | ✗\* | ✗ | ✓ | = | ✓ | St, A, C |
| | upload | ✗\* | ✗ | ✗ | ✓ | ✓ | T, St, A |
| | delete | · | · | ✗ | ✗ | · | St |
| `groups/{g}/theme/*` | read | ✗\* | ✗ | ✓ | = | ✓ | St, A, C |
| | upload | ✗\* | ✗ | ✗ | ✓ | ✓ | St, A |
| | delete | · | · | ✗ | ✗ | · | St |
| `groups/{g}/messages/{m}/**` | read | ✗\* | ✗ | ✓ | = | ✓ | T, St, A |
| | upload (images ≤ 10 MB) | ✗\* | ✗ | ✓ | ✓ | ✗ | T, St, A |
| | delete | · | · | ✗ | ✗ | · | St |
| `groups/{g}/documents/{d}/*` | read | ✗\* | ✗ | ✓ | = | ✓ | St, A, D |
| | upload (types, ≤ 10 MB, setting) | ✗\* | ✗ | ✓ / ✗ (setting) | ✓ | ✗ | D, T, St, A |
| | delete | · | · | ✗ | ✗ | · | D, St |

Every upload under `groups/{g}/` is refused on a full team (St, D, A), an archived team (C), and, for members, a suspended team (C). A guardian is a member here; Storage has no player paths.

## Remaining gaps

None of these is a known bug; each is a case the rules already refuse or allow through a path another test covers.

- A super admin creating a poll (¹) and renaming a document (²).
- Size, type, and quota checks on the logo and background are tested for owners and super admins, not for a plain `admin` role (the rules don't distinguish them).
- `devices` update lets any signed-in person take over a device doc whose random ID they know (NOTIF-10, on purpose); the takeover itself isn't tested beyond the owner's refresh.
