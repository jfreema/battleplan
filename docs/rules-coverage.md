# Security-rules test coverage

The roadmap task 104 review of `firestore.rules` and `storage.rules` against the rules tests in `functions/test/rules/` (run with `npm --prefix functions run emulators:test`). ARCH §9 asks for every collection and role to be tested. The Functions tests in `functions/test/emulator/` run as the Admin SDK, which skips rules, so they don't count here. There's no `test/emulator` in the Flutter app.

Reviewed 2026-10-12, and updated the same day for one team type (pending players, `self` links, and super admins' RSVPs and events) and for player details (`playerDetails`); updated 2026-10-13 for mentions, announcements, and pins (CHAT-14, CHAT-15) and contact sharing (TEAM-10), and for super admins on a team they've joined (§3: @everyone, announcements, polls, and documents whatever the team's switches). Update this page whenever a rule or a rules test changes.

**Legend:** ✓ tested and allowed · ✗ tested and refused · ✓\* / ✗\* added in this review (`coverage.test.ts`) · `=` the rule can't tell this role from the column to its left, so that test covers it · `·` doesn't apply · **gap** not tested.

**Roles:** *Signed out* has no auth. *Other team* is an admin or member of another team. *Member* is on the team. *Guardian* is a member linked to the player, as a parent or guardian or as the player themselves (`self`); the rules treat both relations alike (`isGuardian`). A *proposer* is the member who added a pending player. *Admin* has the team's `admin` role. *Owner* has `owner`; the rules treat it like admin everywhere (checked in `coverage.test.ts`). *Super admin* has the `superAdmin` claim and isn't on the team, except where a cell says "on the team".

**Test files:** F `firestore.test.ts`, T `teams.test.ts`, A `admin.test.ts`, P `polls.test.ts`, S `schedule.test.ts`, D `documents.test.ts`, N `notifications.test.ts`, U `users.test.ts`, St `storage.test.ts`, PD `player_details.test.ts`, As `assignments.test.ts`, C `coverage.test.ts`.

## Bugs found and fixed

1. **Storage ignored suspension.** `storage.rules`' `isMember` didn't check `suspendedAt`, unlike Firestore's, so members of a suspended team could still read its files and upload chat photos, documents, a logo, and a background. Fixed: membership needs an unsuspended team. Super admins still read (View team). Test: C "closes the team's files to its members, and takes no uploads".
2. **Storage took uploads on archived teams.** TEAM-9 makes archived teams read-only, but every Storage upload rule only checked the quota. Fixed: `underQuota` also needs `archivedAt == null`, for everyone, super admins included. Test: C "takes no uploads from anyone, super admins included, and still shows its files".
3. **Players stayed editable on archived teams.** The `players` update rule had no `active()`, so guardians and admins could rename players on an archived team. Fixed. Test: C "freezes the roster: guardians and admins edit no player".

Only those three tests fail against the old rules; they pass against the new ones. The rest of `coverage.test.ts` (signed-out visitors, the suspended team's Firestore reads and writes, "opens again when unsuspended", the archived team's mute and read marks, "edits players again once restored", and the spot checks) passes on the old rules too: it fills coverage gaps rather than proving a fix. Firestore's `isMember` already checked `suspendedAt`. The Storage fix stays within the two Firestore documents a Storage rule may read (the membership and the team).

## Team collections (Firestore)

| Collection | Operation | Signed out | Other team | Member | Guardian | Admin | Owner | Super admin | Tests |
|---|---|---|---|---|---|---|---|---|---|
| `groups` | get | ✗ | ✗ | ✓\* | ✓\* | ✓\* | ✓ | ✓ | F, A, C |
| | list | ✗\* | · | ✗\* | = | = | = | ✗\* | C |
| | create, delete | ✗\* | · | · | · | · | ✗ | · | T, C |
| | update (profile, settings, chat look) | ✗\* | ✗ | ✗ | ✗\* | ✓ | ✓ | ✗ | F, T, A, St, C |
| | update `pinnedMessageIds` (`pinMessage` only) | · | · | · | · | · | ✗ | · | F |
| | update storage fields | · | · | ✗ | · | · | ✗ | ✗ | St |
| `groupMembers` | get, list (roster) | ✗\* | ✗ | ✓ | = | = | = | ✓ | T, A, F |
| | list own (switcher) | · | ✗ (others') | ✓ | = | = | = | · | F |
| | create, delete | ✗\* | ✗ | ✗ | · | · | ✗ | ✗ | T, A |
| | update own prefs and read marks | · | · | ✓ | = | = | = | · | F, N |
| | update own shared phone and email (TEAM-10; clear any time, set on an open team) | · | ✗ | ✓ | = | = | = | · | T |
| | update role or another's doc | ✗\* | · | ✗ | · | · | ✗ | ✗ | F, T, A |
| `players` | get, list (active) | ✗\* | ✗ | ✓ | ✓\* | = | = | ✓ | T, A, C |
| | get, list (pending) | · | ✗ | ✗ / ✓ (proposer) | · | ✓ | = | ✓ | T |
| | create, delete | ✗\* | · | ✗ (create) | · | ✗ (✗\* delete) | · | · | F, T, C |
| | update (name, number, position) | ✗\* | ✗ | ✗ (proposer too) | ✓ (`self` too) | ✓ (pending too) | ✓\* | ✗ | F, T, A, C |
| | update `status`, `proposedBy`, decisions | · | · | ✗ (proposer) | · | ✗ | = | · | T |
| `playerGuardians` | get, list | ✗\* | ✗ | ✓ | ✓\* | = | = | ✓ | T, A, C |
| | create, update, delete | ✗\* | · | ✗ | ✗ | ✗ (✗\* update) | · | · | T, C |
| `guardianRequests` | get, list | ✗\* | ✗ | ✗ (others'), ✓ (own) | = | ✓ | = | ✓ | T, A |
| | create, update, delete | ✗\* | · | ✗ (✗\* delete) | · | ✗ (✗\* delete) | · | · | T, C |
| `playerDetails` | get | ✗ | ✗ | ✗ | ✓ (own player only) | ✓ | ✓ | ✓ | PD, C |
| | list (by `groupId`, limit ≤ 100) | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ (team filter required) | PD, C |
| | create, update | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ | ✗ | PD |
| | delete | ✗ | ✗ | ✗ | ✓ | ✓ | = | ✗ | PD |
| `messages` | get, list | ✗ | ✗ | ✓ | = | ✓ | = | ✓ | F, A |
| | create (rate limit, author snapshot, photos) | ✗\* | ✗ | ✓ | = | = | ✓ | ✗ | F, P, St, A |
| | update reactions | ✗\* | ✗ | ✓ | ✓ | ✓ | = | ✗ | F, A |
| | update text (author only) | ✗\* | ✗ | ✓ / ✗ (others') | = | = | ✗\* (others') | · | F, C |
| | create with `mentions` (≤ 20; not on polls) | · | · | ✓ | = | ✓ | = | · | F, P |
| | create with `mentionsEveryone` or `announcement` (admins; announcements text only) | · | · | ✗ | = | ✓ | ✓ | ✓ on the team | F, P |
| | update pin fields (`pinMessage` only) | · | · | ✗ | = | = | = | · | F |
| | delete | ✗\* | · | ✗\* | · | · | ✗\* | ✗\* | C |
| `polls` | get, list | ✗\* | ✗ | ✓\* | = | = | = | ✓ | A, C |
| | create (with its message) | ✗\* | ✗ | ✓ | = | = | ✓ | ✗ / ✓ on the team (setting off too) | P |
| | update, delete | ✗\* | · | · | · | · | ✗ | · | P |
| `pollVotes` | get, list (open ballot) | ✗\* | ✗ | ✓ | = | = | = | ✓ | P, A |
| | get, list (anonymous: only your own) | · | · | ✓ own, ✗ others' | = | = | ✗ | ✗ | P, A |
| | create, update | ✗\* | ✗ | ✓ | = | = | = | ✗ | P, A |
| | delete (own, open poll) | ✗\* | · | ✓ / ✗ (others') | = | = | = | · | P |
| `eventSeries` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | S, A |
| | create, update, delete | ✗\* | · | · | · | · | ✗ | ✗\* | S, C |
| `events` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | S, A |
| | create | ✗\* | ✗ | ✓ / ✗ (setting) | = | ✓ | ✓\* | ✓\* | S, C |
| | update, cancel | ✗\* | ✗\* | ✓ creator / ✗ | = | = | ✓ | ✓ | S, C |
| | delete | ✗\* | ✗ | ✓ creator / ✗ | = | ✓ | ✓ | ✓ | S |
| `rsvps` | get, list | ✗\* | ✗ | ✓\* | = | = | = | ✓ | A, C |
| | create, update | ✗\* | ✗ | ✓ self / ✗ others | ✓ their player (guardian or `self`) / ✗ unlinked | ✓ anyone | ✓ | ✓ anyone / ✗ self | F, S, A |
| | create, update for a pending player | · | · | ✗ (proposer) | · | ✗ | = | ✗ | S |
| | delete | ✗\* | · | ✗ | · | · | · | · | S |
| `assignments` (SCHED-15) | get, list (list names the team, limit ≤ 100) | ✗ | ✗ | ✓ | = | = | = | ✓ | As, C |
| | create, delete, edit kind and label | ✗ | ✗ | ✗ | = | ✓ | = | ✓ (✗ archived team) | As, C |
| | assign someone on the team, or nobody | · | · | ✗ | = | ✓ | = | ✓ | As |
| | volunteer for an open task, give up your own | · | ✗ | ✓ / ✗ (taken, or someone else's) | = | ✓ | = | ✗ not on the team | As, C |
| `groupDocuments` | get, list | ✗\* | ✗ | ✓ | = | = | = | ✓ | D, A |
| | create | ✗\* | ✗ | ✓ / ✗ (setting) | = | ✓ | ✓ | ✗ / ✓ on the team (setting off too) | D, A |
| | update | ✗\* | ✗ | ✓ uploader / ✗ | = | ✓ (pins) | ✓ | ✓ (pins) | D |
| | delete | ✗\* | ✗ | ✓ uploader / ✗ | = | ✓ | ✓ | ✓ | D |
| `reports` | get, list | ✗\* | ✗ | ✗ | ✗\* | ✓ | ✓ | ✓ | T, A, C |
| | create, update, delete | ✗\* | · | ✗ | · | ✗ | · | ✗ | T, A |

Team states, for every collection above: **archived** teams refuse every member and admin write (F, P, S, D, St, C), keep reads, and still take each person's own mute and read marks (C, on purpose). **Suspended** teams refuse members' reads and writes in every collection (F, C) while super admins still read (A); people still see their own membership and notifications (C).

Players and RSVPs under one team type: members list players with `status == 'active'`, and proposers with `proposedBy` equal to themselves; an unfiltered list is refused, because a query can't prove that a missing status means active (T). A get still treats a player with no status as active (T). A member linked as the player (`self`) edits the player and answers on its row, like a guardian, but can't change the link (T, S). Nobody answers for a pending player, admins and super admins included (S). `groupMembers.playerSummary` and `linksUpdatedAt`, and `players.linksUpdatedAt`, are Functions only: neither update rule's field list includes them.

**Player details conditions** (all in PD): a pending player, a missing player, or a player on another team is refused for everyone (a pending player's missing doc reads as not found for admins); an archived team allows reads and refuses writes and deletes; a suspended team refuses everything for its members (also in C), while super admins still read; a wrong or changed `groupId`, a bad `updatedBy` or `updatedAt`, unknown keys, sizes over the limits, and bad contacts are refused; a date of birth with a bad format, an impossible date, or a future date is refused, and past dates and null are allowed; `medicalNotes`, `medicalConsentAt`, and `medicalConsentBy` are unknown keys and refused (no health data, 2026-10-20).

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
| | upload (types, ≤ 10 MB, setting) | ✗\* | ✗ | ✓ / ✗ (setting) | ✓ | ✗ / ✓ on the team (setting off too) | D, T, St, A |
| | delete | · | · | ✗ | ✗ | · | D, St |

Every upload under `groups/{g}/` is refused on a full team (St, D, A), an archived team (C), and, for members, a suspended team (C). A guardian is a member here; Storage has no player paths.

## Remaining gaps

None of these is a known bug; each is a case the rules already refuse or allow through a path another test covers.

- A client writing `playerSummary` or `linksUpdatedAt` by name: the field lists refuse it, but no test tries. A super admin editing a pending player directly is refused the same way as an active one (A tests an active one).
- Size, type, and quota checks on the logo and background are tested for owners and super admins, not for a plain `admin` role (the rules don't distinguish them).
- `devices` update lets any signed-in person take over a device doc whose random ID they know (NOTIF-10, on purpose); the takeover itself isn't tested beyond the owner's refresh.
