// Loads sample data into the local Emulator Suite (ARCH §5.7). Refuses to
// run against anything but the emulators.
//
//   firebase emulators:start --project demo-battleplan   (in one terminal)
//   npm --prefix tools/seed run seed                      (in another)
//
// Every account's password is "password".
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Refusing to seed: the emulator hosts are not set.');
  process.exit(1);
}
if (!process.env.GCLOUD_PROJECT?.startsWith('demo-')) {
  console.error('Refusing to seed: use a demo- project ID.');
  process.exit(1);
}

initializeApp({ projectId: process.env.GCLOUD_PROJECT });
const auth = getAuth();
const db = getFirestore();

const PASSWORD = 'password';
const now = Date.now();
const minutesAgo = (m: number) => Timestamp.fromMillis(now - m * 60_000);
const daysFromNow = (d: number, hour: number) => {
  const date = new Date(now);
  date.setDate(date.getDate() + d);
  date.setHours(hour, 0, 0, 0);
  return Timestamp.fromDate(date);
};

interface Person { uid: string; name: string; email: string; superAdmin?: boolean }

const people: Person[] = [
  { uid: 'coach', name: 'Jordan Coach', email: 'coach@example.com' },
  { uid: 'alex', name: 'Alex Kim', email: 'alex@example.com' },
  { uid: 'sam', name: 'Sam Rivera', email: 'sam@example.com' },
  { uid: 'maria', name: 'Maria Rodriguez', email: 'maria@example.com' },
  { uid: 'luis', name: 'Luis Rodriguez', email: 'luis@example.com' },
  { uid: 'priya', name: 'Priya Shah', email: 'priya@example.com' },
  { uid: 'admin', name: 'Platform Admin', email: 'admin@example.com', superAdmin: true },
];

const settings = {
  membersCanCreateEvents: false,
  membersCanCreatePolls: true,
  membersCanUploadDocs: true,
  membersCanInvite: true,
  allowMaybe: true,
  defaultReminderOffsets: [1440],
};

const teams = [
  { id: 'thunder', name: 'Thunder', sport: 'softball', teamType: 'adult', color: '#2F5BEA' },
  { id: 'lightning', name: 'Lightning U10', sport: 'soccer', teamType: 'youth', color: '#0F8A5F' },
  { id: 'hawks', name: 'Hawks U14', sport: 'basketball', teamType: 'youth', color: '#C2410C' },
] as const;

// [team, uid, role, playerSummary?]. Coach and Maria are on more than one team.
const memberships: [string, string, string, string?][] = [
  ['thunder', 'coach', 'owner'],
  ['thunder', 'alex', 'admin'],
  ['thunder', 'sam', 'member'],
  ['thunder', 'maria', 'member'],
  ['lightning', 'coach', 'owner'],
  ['lightning', 'maria', 'member', 'Emma #7'],
  ['lightning', 'luis', 'member', 'Emma #7'],
  ['lightning', 'priya', 'member', 'Arjun #11'],
  ['hawks', 'priya', 'owner'],
  ['hawks', 'maria', 'member', 'Liam #23'],
];

// A parent with players on two teams, two guardians for one player, and a
// player whose guardian hasn't joined yet.
const players = [
  { id: 'emma', groupId: 'lightning', name: 'Emma Rodriguez', number: '7', position: 'Forward', guardians: ['maria', 'luis'] },
  { id: 'arjun', groupId: 'lightning', name: 'Arjun Shah', number: '11', position: 'Keeper', guardians: ['priya'] },
  { id: 'noah', groupId: 'lightning', name: 'Noah Bennett', number: '4', position: 'Defense', guardians: [] },
  { id: 'liam', groupId: 'hawks', name: 'Liam Rodriguez', number: '23', position: 'Guard', guardians: ['maria'] },
];

async function main() {
  for (const p of people) {
    await auth.deleteUser(p.uid).catch(() => undefined);
    await auth.createUser({
      uid: p.uid,
      email: p.email,
      password: PASSWORD,
      displayName: p.name,
      emailVerified: true,
    });
    if (p.superAdmin) await auth.setCustomUserClaims(p.uid, { superAdmin: true });
    await db.doc(`users/${p.uid}`).set({
      displayName: p.name,
      displayNameLower: p.name.toLowerCase(),
      email: p.email,
      emailLower: p.email.toLowerCase(),
      photoPath: null,
      status: 'active',
      signInMethods: ['password'],
      themeMode: 'system',
      notificationPrefs: { messages: true, replies: true, mentions: true, polls: true, events: true, reminders: true, documents: true },
      acceptedTermsAt: minutesAgo(60 * 24 * 30),
      adultConfirmedAt: minutesAgo(60 * 24 * 30),
      lastActiveAt: minutesAgo(5),
      createdAt: minutesAgo(60 * 24 * 30),
      updatedAt: minutesAgo(60 * 24 * 30),
      schemaVersion: 1,
    });
  }
  const nameOf = (uid: string) => people.find((p) => p.uid === uid)!.name;

  const batch = db.batch();
  for (const t of teams) {
    const members = memberships.filter((m) => m[0] === t.id);
    const owner = members.find((m) => m[2] === 'owner')![1];
    batch.set(db.doc(`groups/${t.id}`), {
      name: t.name,
      nameLower: t.name.toLowerCase(),
      description: '',
      photoPath: null,
      color: t.color,
      sport: t.sport,
      teamType: t.teamType,
      ownerId: owner,
      createdBy: owner,
      timeZone: 'America/Chicago',
      settings,
      memberCount: members.length,
      playerCount: players.filter((p) => p.groupId === t.id).length,
      lastMessageAt: null,
      lastMessagePreview: null,
      storageBytes: 0,
      storageQuotaBytes: 5 * 1024 ** 3,
      createdAt: minutesAgo(60 * 24 * 30),
      updatedAt: minutesAgo(60 * 24 * 30),
      schemaVersion: 1,
    });
  }
  for (const [groupId, uid, role, playerSummary] of memberships) {
    batch.set(db.doc(`groupMembers/${groupId}_${uid}`), {
      groupId,
      uid,
      role,
      title: role === 'owner' ? 'Coach' : null,
      displayName: nameOf(uid),
      photoPath: null,
      playerSummary: playerSummary ?? null,
      notificationLevel: 'all',
      mutedUntil: null,
      lastReadAt: minutesAgo(90),
      lastPostedAt: null,
      joinedAt: minutesAgo(60 * 24 * 20),
      addedBy: 'coach',
    });
  }
  for (const p of players) {
    batch.set(db.doc(`players/${p.id}`), {
      groupId: p.groupId,
      displayName: p.name,
      displayNameLower: p.name.toLowerCase(),
      jerseyNumber: p.number,
      position: p.position,
      createdBy: 'coach',
      createdAt: minutesAgo(60 * 24 * 20),
      updatedAt: minutesAgo(60 * 24 * 20),
    });
    for (const uid of p.guardians) {
      batch.set(db.doc(`playerGuardians/${p.id}_${uid}`), {
        playerId: p.id,
        groupId: p.groupId,
        uid,
        addedBy: 'coach',
        via: 'admin',
        createdAt: minutesAgo(60 * 24 * 20),
      });
    }
  }
  await batch.commit();

  // Messages, with the team preview the messages trigger would write (M3).
  const chats: Record<string, [string, string, number][]> = {
    thunder: [
      ['coach', 'Field 3 is open tonight. See everyone at 6!', 240],
      ['alex', 'I can bring the extra bats.', 200],
      ['sam', 'On my way!', 30],
    ],
    lightning: [
      ['coach', 'Reminder: shin guards for everyone on Saturday.', 600],
      ['maria', 'Emma will be there. Can someone carpool?', 120],
    ],
    hawks: [['priya', 'Great hustle at practice today, team.', 45]],
  };
  for (const [groupId, list] of Object.entries(chats)) {
    for (const [i, [uid, text, ago]] of list.entries()) {
      const m = memberships.find((x) => x[0] === groupId && x[1] === uid)!;
      await db.doc(`messages/${groupId}-seed-${i}`).set({
        groupId,
        authorId: uid,
        authorName: nameOf(uid),
        authorPhotoPath: null,
        authorPlayerSummary: m[3] ?? null,
        type: 'text',
        text,
        attachments: [],
        reactions: i === 0 ? { alex: 'like', sam: 'love' } : {},
        createdAt: minutesAgo(ago),
      });
    }
    const [lastUid, lastText, lastAgo] = list[list.length - 1];
    await db.doc(`groups/${groupId}`).update({
      lastMessageAt: minutesAgo(lastAgo),
      lastMessagePreview: { authorName: nameOf(lastUid), text: lastText, type: 'text' },
    });
  }

  // Upcoming events with a few RSVPs; youth RSVPs are per player.
  const events = [
    { id: 'thunder-practice', groupId: 'thunder', type: 'practice', title: 'Practice', day: 2, hour: 18, rsvpFor: 'members' },
    { id: 'thunder-game', groupId: 'thunder', type: 'game', title: 'vs. Eagles', day: 5, hour: 10, rsvpFor: 'members', opponent: 'Eagles', homeAway: 'home' },
    { id: 'lightning-practice', groupId: 'lightning', type: 'practice', title: 'Practice', day: 1, hour: 17, rsvpFor: 'players' },
    { id: 'hawks-game', groupId: 'hawks', type: 'game', title: '@ Bulls', day: 3, hour: 19, rsvpFor: 'players', opponent: 'Bulls', homeAway: 'away' },
  ];
  for (const e of events) {
    const startAt = daysFromNow(e.day, e.hour);
    await db.doc(`events/${e.id}`).set({
      groupId: e.groupId,
      type: e.type,
      title: e.title,
      description: '',
      location: { name: 'Riverside Park, Field 3', address: '100 River Rd' },
      allDay: false,
      startAt,
      endAt: Timestamp.fromMillis(startAt.toMillis() + 90 * 60_000),
      timeZone: 'America/Chicago',
      opponent: e.opponent ?? null,
      homeAway: e.homeAway ?? null,
      rsvpEnabled: true,
      rsvpFor: e.rsvpFor,
      reminderOffsets: [1440],
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
      createdBy: 'coach',
      createdAt: minutesAgo(60 * 24),
      updatedAt: minutesAgo(60 * 24),
      schemaVersion: 1,
    });
  }
  const rsvps: [string, 'member' | 'player', string, string, string][] = [
    ['thunder-practice', 'member', 'alex', 'going', 'alex'],
    ['thunder-practice', 'member', 'sam', 'maybe', 'sam'],
    ['lightning-practice', 'player', 'emma', 'going', 'luis'],
    ['lightning-practice', 'player', 'arjun', 'not_going', 'priya'],
  ];
  for (const [eventId, participantType, participantId, status, respondedBy] of rsvps) {
    const e = events.find((x) => x.id === eventId)!;
    await db.doc(`rsvps/${eventId}_${participantId}`).set({
      eventId,
      groupId: e.groupId,
      participantType,
      participantId,
      participantName: participantType === 'player'
        ? players.find((p) => p.id === participantId)!.name
        : nameOf(participantId),
      eventStartAt: daysFromNow(e.day, e.hour),
      status,
      guests: 0,
      respondedBy,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  for (const e of events) {
    const answers = rsvps.filter((r) => r[0] === e.id);
    await db.doc(`events/${e.id}`).update({
      rsvpCounts: {
        going: answers.filter((r) => r[3] === 'going').length,
        maybe: answers.filter((r) => r[3] === 'maybe').length,
        notGoing: answers.filter((r) => r[3] === 'not_going').length,
      },
    });
  }

  await db.doc('config/app').set({
    allowUserGroupCreation: true,
    maxGroupsCreatedPerUserPerDay: 5,
    defaultStorageQuotaGb: 5,
    maxUploadMb: 25,
    maxImageMb: 10,
    supportEmail: 'support@getbattleplan.app',
  });

  console.log(`Seeded ${people.length} people, ${teams.length} teams, ${players.length} players.`);
  console.log('Sign in as coach@example.com (two teams) or maria@example.com (three teams); password "password".');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
