// The admin panel's inputs and wording (SPEC §6.11 ADMIN-2 to ADMIN-8,
// AUTH-6): what each callable accepts, the shared rules behind them, and
// the emails a super admin can send.
import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import {
  ADMIN_PAGE_MAX,
  BANNER_TEXT_MAX,
  configFields,
  CreateUserInput,
  DeleteGroupInput,
  iso,
  ListReportsInput,
  ListTeamsInput,
  ListUsersInput,
  plain,
  prefixEnd,
  REPORT_NOTE_MAX,
  resolutionFor,
  ResolveReportInput,
  SetSuspendedInput,
  teamStatus,
  UpdateConfigInput,
  UpdateGroupInput,
  UpdatePlayerInput,
  UpdateUserInput,
} from '../../src/admin/inputs.js';
import { accountSetupEmail, passwordResetEmail } from '../../src/email/templates.js';
import { Limits } from '../../src/shared/constants.js';

const ok = (schema: { safeParse: (d: unknown) => { success: boolean } }, data: unknown) => schema.safeParse(data).success;

/** A valid settings form (ADMIN-7). */
const config = (extra: object = {}) => ({
  allowUserGroupCreation: true,
  maxGroupsCreatedPerUserPerDay: 5,
  defaultStorageQuotaMb: 500,
  maxUploadMb: 10,
  supportEmail: 'support@getbattleplan.app',
  announcementBanner: { text: 'Maintenance Sunday night', severity: 'warning', expiresAt: '2026-11-01T06:00:00.000Z' },
  ...extra,
});

describe('list inputs (ADMIN-2, ADMIN-4, ADMIN-5)', () => {
  it('defaults the teams sort and page size, and lowercases a search', () => {
    expect(ListTeamsInput.parse({})).toEqual({ sort: 'created', limit: 25 });
    expect(ListTeamsInput.parse({ query: '  Thun ', sort: 'storage', status: 'suspended' })).toMatchObject({
      query: 'thun',
      sort: 'storage',
      status: 'suspended',
    });
    expect(ListTeamsInput.parse({ query: '   ' }).query).toBeUndefined();
  });

  it('keeps every page bounded at 50', () => {
    expect(ADMIN_PAGE_MAX).toBe(50);
    for (const schema of [ListTeamsInput, ListUsersInput, ListReportsInput]) {
      expect(ok(schema, { limit: 50 })).toBe(true);
      expect(ok(schema, { limit: 51 })).toBe(false);
      expect(ok(schema, { limit: 0 })).toBe(false);
    }
  });

  it('refuses unknown sorts, statuses, filters, and cursors that name a path', () => {
    expect(ok(ListTeamsInput, { sort: 'name' })).toBe(false);
    expect(ok(ListTeamsInput, { status: 'deleted' })).toBe(false);
    expect(ok(ListUsersInput, { filter: 'owner' })).toBe(false);
    expect(ok(ListUsersInput, { filter: 'superAdmin' })).toBe(true);
    expect(ok(ListTeamsInput, { cursor: 'groups/x' })).toBe(false);
    expect(ListReportsInput.parse({}).status).toBe('open');
    expect(ok(ListReportsInput, { status: 'closed' })).toBe(false);
  });
});

describe('team inputs (ADMIN-3)', () => {
  it('takes an optional suspension note up to 500 characters', () => {
    expect(ok(SetSuspendedInput, { groupId: 'g1', suspended: true })).toBe(true);
    expect(ok(SetSuspendedInput, { groupId: 'g1', suspended: true, note: 'x'.repeat(REPORT_NOTE_MAX + 1) })).toBe(false);
    expect(ok(SetSuspendedInput, { groupId: 'g1' })).toBe(false);
  });

  it('needs the typed name to delete a team', () => {
    expect(ok(DeleteGroupInput, { groupId: 'g1' })).toBe(false);
    expect(ok(DeleteGroupInput, { groupId: 'g1', confirmName: 'Thunder' })).toBe(true);
  });

  it('reads a suspended team as suspended even when archived', () => {
    const at = Timestamp.now();
    expect(teamStatus({})).toBe('active');
    expect(teamStatus({ archivedAt: null, suspendedAt: null })).toBe('active');
    expect(teamStatus({ archivedAt: at })).toBe('archived');
    expect(teamStatus({ suspendedAt: at })).toBe('suspended');
    expect(teamStatus({ archivedAt: at, suspendedAt: at })).toBe('suspended');
  });
});

describe('super-admin team and player edits (ADMIN-3)', () => {
  const group = (extra: object) => ({ groupId: 'g1', ...extra });

  it("takes the fields a team's admins may write, validated as the rules do", () => {
    expect(UpdateGroupInput.parse(group({ name: ' Thunder ', color: null, sport: 'soccer' }))).toEqual({
      groupId: 'g1', name: 'Thunder', color: null, sport: 'soccer',
    });
    expect(ok(UpdateGroupInput, group({ settings: { allowMaybe: false, defaultReminderOffsets: [15, 60, 120, 1440, 2880, 10080] } }))).toBe(true);
    expect(ok(UpdateGroupInput, group({ chatTheme: { bubbleColor: '#7C3AED', background: 'pattern', backgroundPath: null } }))).toBe(true);
    for (const bad of [
      {}, { color: '#000000' }, { sport: 'golf' }, { name: ' ' }, { name: 'x'.repeat(Limits.groupNameMax + 1) },
      { description: 'x'.repeat(501) }, { settings: { membersCanPost: true } }, { settings: { defaultReminderOffsets: [30] } },
      { settings: { defaultReminderOffsets: [15, 15, 15, 15, 15, 15, 15] } }, { chatTheme: { extra: 1 } },
      { timeZone: '' }, { storageQuotaBytes: 1 },
    ]) {
      expect(ok(UpdateGroupInput, group(bad))).toBe(false);
    }
  });

  it("names only files in the team's own logo and background folders", () => {
    expect(ok(UpdateGroupInput, group({ photoPath: 'groups/g1/avatar/1.jpg', backgroundPath: 'groups/g1/theme/1.jpg' }))).toBe(true);
    expect(ok(UpdateGroupInput, group({ photoPath: null }))).toBe(true);
    for (const bad of [
      { photoPath: 'groups/g2/avatar/1.jpg' }, { photoPath: 'groups/g1/theme/1.jpg' }, { photoPath: 'groups/g1/avatar/a/1.jpg' },
      { photoPath: 'groups/g1/avatar/' }, { backgroundPath: 'users/u/avatar/1.jpg' }, { chatTheme: { backgroundPath: 'groups/g1/avatar/1.jpg' } },
    ]) {
      expect(ok(UpdateGroupInput, group(bad))).toBe(false);
    }
  });

  it('edits only a name, number, position, and walk-up song, within validPlayer, a blank one clearing it (PLAYER-10)', () => {
    expect(UpdatePlayerInput.parse({ playerId: 'p1', displayName: ' Emma ', jerseyNumber: '', position: ' SS ' })).toEqual({
      playerId: 'p1', displayName: 'Emma', jerseyNumber: null, position: 'SS',
    });
    expect(UpdatePlayerInput.parse({ playerId: 'p1', walkUpSong: ' Jump Around ' })).toEqual({
      playerId: 'p1', walkUpSong: 'Jump Around',
    });
    expect(ok(UpdatePlayerInput, { playerId: 'p1', walkUpSong: 'x'.repeat(101) })).toBe(false);
    expect(UpdatePlayerInput.parse({ playerId: 'p1', jerseyNumber: null })).toEqual({ playerId: 'p1', jerseyNumber: null });
    for (const bad of [{}, { displayName: '' }, { displayName: 'x'.repeat(61) }, { jerseyNumber: '12345' }, { position: 'x'.repeat(31) }]) {
      expect(ok(UpdatePlayerInput, { playerId: 'p1', ...bad })).toBe(false);
    }
  });
});

describe('user inputs (ADMIN-4, AUTH-6)', () => {
  it('creates an account from a name and an email only, never a password', () => {
    expect(CreateUserInput.parse({ email: ' Pat@Example.COM ', displayName: ' Pat ' })).toEqual({
      email: 'pat@example.com',
      displayName: 'Pat',
    });
    expect(ok(CreateUserInput, { email: 'not-an-email', displayName: 'Pat' })).toBe(false);
    expect(ok(CreateUserInput, { email: 'pat@example.com', displayName: '' })).toBe(false);
    expect(CreateUserInput.parse({ email: 'pat@example.com', displayName: 'Pat', password: 'hunter2' })).not.toHaveProperty(
      'password',
    );
  });

  it('adds to a team as a member or an admin, never the owner, and a role needs a team', () => {
    const base = { email: 'pat@example.com', displayName: 'Pat' };
    expect(ok(CreateUserInput, { ...base, groupId: 'g1', role: 'admin' })).toBe(true);
    expect(ok(CreateUserInput, { ...base, groupId: 'g1', role: 'owner' })).toBe(false);
    expect(ok(CreateUserInput, { ...base, role: 'admin' })).toBe(false);
  });

  it('edits a name or adds to a team, and needs one of them', () => {
    expect(ok(UpdateUserInput, { uid: 'u1' })).toBe(false);
    expect(ok(UpdateUserInput, { uid: 'u1', displayName: 'x'.repeat(51) })).toBe(false);
    expect(UpdateUserInput.parse({ uid: 'u1', addToGroup: { groupId: 'g1' } }).addToGroup).toEqual({
      groupId: 'g1',
      role: 'member',
    });
  });
});

describe('report resolutions (ADMIN-5)', () => {
  it('needs a note of 1 to 500 characters', () => {
    expect(ok(ResolveReportInput, { reportId: 'r1', action: 'dismiss', note: '' })).toBe(false);
    expect(ok(ResolveReportInput, { reportId: 'r1', action: 'dismiss', note: '   ' })).toBe(false);
    expect(ok(ResolveReportInput, { reportId: 'r1', action: 'dismiss', note: 'Spam account' })).toBe(true);
    expect(ok(ResolveReportInput, { reportId: 'r1', action: 'dismiss', note: 'x'.repeat(501) })).toBe(false);
    expect(ok(ResolveReportInput, { reportId: 'r1', action: 'ban', note: 'x' })).toBe(false);
  });

  it('records what each action did', () => {
    expect(resolutionFor('deleteContent', 'message')).toBe('deletedMessage');
    expect(resolutionFor('deleteContent', 'document')).toBe('deletedDocument');
    expect(resolutionFor('deleteContent', 'user')).toBeNull();
    expect(resolutionFor('removeMember', 'message')).toBe('removedMember');
    expect(resolutionFor('disableUser', 'user')).toBe('disabledUser');
    expect(resolutionFor('suspendTeam', 'document')).toBe('suspendedTeam');
    expect(resolutionFor('dismiss', 'user')).toBe('none');
  });
});

describe('platform settings (ADMIN-7)', () => {
  it('accepts a full form, and no banner', () => {
    expect(ok(UpdateConfigInput, config())).toBe(true);
    expect(ok(UpdateConfigInput, config({ announcementBanner: null }))).toBe(true);
    expect(ok(UpdateConfigInput, config({ announcementBanner: undefined }))).toBe(false);
  });

  it('keeps limits within what the platform allows', () => {
    expect(ok(UpdateConfigInput, config({ maxUploadMb: Limits.maxUploadMb + 1 }))).toBe(false);
    expect(ok(UpdateConfigInput, config({ defaultStorageQuotaMb: Limits.storageQuotaMaxMb }))).toBe(true);
    expect(ok(UpdateConfigInput, config({ defaultStorageQuotaMb: Limits.storageQuotaMaxMb + 1 }))).toBe(false);
    expect(ok(UpdateConfigInput, config({ defaultStorageQuotaMb: 0 }))).toBe(false);
    expect(ok(UpdateConfigInput, config({ maxGroupsCreatedPerUserPerDay: 0 }))).toBe(false);
    expect(ok(UpdateConfigInput, config({ maxGroupsCreatedPerUserPerDay: 2.5 }))).toBe(false);
    expect(ok(UpdateConfigInput, config({ supportEmail: 'support' }))).toBe(false);
  });

  it('bounds the banner: text up to 280, a known severity, and an ISO end date', () => {
    const banner = (b: object) => config({ announcementBanner: { ...config().announcementBanner, ...b } });
    expect(ok(UpdateConfigInput, banner({ text: 'x'.repeat(BANNER_TEXT_MAX) }))).toBe(true);
    expect(ok(UpdateConfigInput, banner({ text: 'x'.repeat(BANNER_TEXT_MAX + 1) }))).toBe(false);
    expect(ok(UpdateConfigInput, banner({ text: '  ' }))).toBe(false);
    expect(ok(UpdateConfigInput, banner({ severity: 'error' }))).toBe(false);
    expect(ok(UpdateConfigInput, banner({ expiresAt: 'next week' }))).toBe(false);
    expect(ok(UpdateConfigInput, banner({ expiresAt: '2026-11-01T01:00:00-05:00' }))).toBe(true);
  });

  it('saves the alerts switch (ADMIN-9) only when the form sends it', () => {
    expect(ok(UpdateConfigInput, config({ emailAdminAlerts: false }))).toBe(true);
    expect(ok(UpdateConfigInput, config({ emailAdminAlerts: 'off' }))).toBe(false);
    expect(configFields(UpdateConfigInput.parse(config({ emailAdminAlerts: false })))).toMatchObject({
      emailAdminAlerts: false,
    });
    // An admin panel from before it leaves it as it was.
    expect(configFields(UpdateConfigInput.parse(config()))).not.toHaveProperty('emailAdminAlerts');
  });

  it('stores the banner end as a Timestamp', () => {
    const fields = configFields(UpdateConfigInput.parse(config()));
    const banner = fields.announcementBanner as { expiresAt: Timestamp };
    expect(banner.expiresAt).toBeInstanceOf(Timestamp);
    expect(banner.expiresAt.toDate().toISOString()).toBe('2026-11-01T06:00:00.000Z');
    expect(configFields(UpdateConfigInput.parse(config({ announcementBanner: null }))).announcementBanner).toBeNull();
  });
});

describe('response shapes', () => {
  it('sends dates as ISO 8601, nested ones too', () => {
    const at = Timestamp.fromDate(new Date('2026-10-12T12:00:00Z'));
    expect(iso(at)).toBe('2026-10-12T12:00:00.000Z');
    expect(iso(null)).toBeNull();
    expect(iso('2026-10-12')).toBeNull();
    expect(plain({ a: at, b: [at], c: { d: at, e: 1 }, f: null })).toEqual({
      a: '2026-10-12T12:00:00.000Z',
      b: ['2026-10-12T12:00:00.000Z'],
      c: { d: '2026-10-12T12:00:00.000Z', e: 1 },
      f: null,
    });
  });

  it('ranges a prefix search over every name that starts with it', () => {
    const end = prefixEnd('thu');
    expect('thunder' < end && 'thunder' >= 'thu').toBe(true);
    expect('tia' < end).toBe(false);
  });
});

describe('admin emails (ADMIN-4, AUTH-6)', () => {
  it('sets up an account without a team', () => {
    const email = accountSetupEmail('pat@example.com', 'Jordan', 'https://example.com/link');
    expect(email.to).toBe('pat@example.com');
    expect(email.subject).toBe('Jordan set up a Battleplan account for you');
    expect(email.text).toContain('Set up my account: https://example.com/link');
    expect(email.html).toContain('href="https://example.com/link"');
  });

  it('sends a reset link and never a password', () => {
    const email = passwordResetEmail('pat@example.com', 'https://example.com/reset');
    expect(email.subject).toBe('Reset your Battleplan password');
    expect(email.text).toContain('Choose a new password: https://example.com/reset');
    expect(email.text).toContain("If you sign in with Google or Apple, you don't need a password.");
    expect(email.text.toLowerCase()).not.toMatch(/your password is|temporary password/);
  });

  it('escapes names in the HTML', () => {
    const email = accountSetupEmail('pat@example.com', '<b>Jo</b>', 'https://example.com/link');
    expect(email.html).toContain('&lt;b&gt;Jo&lt;/b&gt;');
  });
});
