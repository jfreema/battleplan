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
  { uid: 'tasha', name: 'Tasha Brooks', email: 'tasha@example.com' },
  { uid: 'ben', name: 'Ben Carter', email: 'ben@example.com' },
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

// One team type (TEAM-1): every team has players.
const teams = [
  { id: 'thunder', name: 'Thunder', sport: 'softball', color: '#2F5BEA' },
  { id: 'cyclone', name: 'Cyclone', sport: 'soccer', color: '#0F8A5F' },
  { id: 'possums', name: 'Rally Possums', sport: 'basketball', color: '#C2410C' },
] as const;

// [team, uid, role, playerSummary?]. Coach and Maria are on more than one team.
const memberships: [string, string, string, string?][] = [
  ['thunder', 'coach', 'owner'],
  ['thunder', 'alex', 'admin', '#3'],
  ['thunder', 'sam', 'member', '#12'],
  ['thunder', 'maria', 'member'],
  ['cyclone', 'coach', 'owner'],
  ['cyclone', 'maria', 'member', 'Emma #7, Mia #9'],
  ['cyclone', 'luis', 'member', 'Emma #7'],
  ['cyclone', 'priya', 'member', 'Arjun #11'],
  ['possums', 'priya', 'owner'],
  ['possums', 'maria', 'member', 'Liam #23'],
  ['possums', 'tasha', 'member', 'Dee #4'],
  ['possums', 'ben', 'member', 'Owen #12'],
];

// A parent with players on two teams and two on one (for "All my
// players", PLAYER-11), two guardians for one player, a
// player whose guardian hasn't joined yet, adults who are players
// themselves ('self'), an unclaimed player, and a pending player Maria
// asked to add to Thunder (PLAYER-3, PLAYER-4).
const players: {
  id: string;
  groupId: string;
  name: string;
  number: string | null;
  position: string | null;
  guardians: string[];
  self?: string;
  pendingBy?: string;
}[] = [
  { id: 'emma', groupId: 'cyclone', name: 'Emma Rodriguez', number: '7', position: 'Forward', guardians: ['maria', 'luis'] },
  { id: 'mia', groupId: 'cyclone', name: 'Mia Rodriguez', number: '9', position: 'Midfield', guardians: ['maria'] },
  { id: 'arjun', groupId: 'cyclone', name: 'Arjun Shah', number: '11', position: 'Keeper', guardians: ['priya'] },
  { id: 'noah', groupId: 'cyclone', name: 'Noah Bennett', number: '4', position: 'Defense', guardians: [] },
  { id: 'liam', groupId: 'possums', name: 'Liam Rodriguez', number: '23', position: 'Guard', guardians: ['maria'] },
  { id: 'dee', groupId: 'possums', name: 'Dee Brooks', number: '4', position: 'Forward', guardians: ['tasha'] },
  { id: 'owen', groupId: 'possums', name: 'Owen Carter', number: '12', position: 'Center', guardians: ['ben'] },
  { id: 'alex-kim', groupId: 'thunder', name: 'Alex Kim', number: '3', position: 'Pitcher', guardians: [], self: 'alex' },
  { id: 'sam-rivera', groupId: 'thunder', name: 'Sam Rivera', number: '12', position: 'Shortstop', guardians: [], self: 'sam' },
  { id: 'casey-park', groupId: 'thunder', name: 'Casey Park', number: '5', position: 'Outfield', guardians: [] },
  { id: 'maria-rodriguez', groupId: 'thunder', name: 'Maria Rodriguez', number: null, position: null, guardians: [], pendingBy: 'maria' },
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
      notificationPrefs: { messages: true, replies: true, mentions: true, polls: true, eventsNew: true, eventsChanged: true, reminders: true, documents: true },
      acceptedTermsAt: minutesAgo(60 * 24 * 30),
      adultConfirmedAt: minutesAgo(60 * 24 * 30),
      lastActiveAt: minutesAgo(5),
      // Kept in step with the claim, so the admin panel can list and count
      // super admins (adminSetSuperAdmin).
      ...(p.superAdmin ? { superAdmin: true } : {}),
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
      kind: 'team',
      ownerId: owner,
      createdBy: owner,
      timeZone: 'America/Chicago',
      settings,
      memberCount: members.length,
      playerCount: players.filter((p) => p.groupId === t.id && !p.pendingBy).length,
      lastMessageAt: null,
      lastMessagePreview: null,
      // The same limit createGroup gives every team (STORE-1).
      storageBytes: 0,
      storageQuotaBytes: 500 * 1024 * 1024,
      storageAlert: 'none',
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
      // The coach last read Thunder before Alex's message, so its chat
      // opens there: the mention, the game's card, and the dinner poll.
      lastReadAt: minutesAgo(groupId === 'thunder' && uid === 'coach' ? 270 : 90),
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
      status: p.pendingBy ? 'pending' : 'active',
      // Linked to its proposer once an admin approves it (PLAYER-4).
      ...(p.pendingBy ? { proposedBy: p.pendingBy, proposedRelation: 'self', decidedBy: null, decidedAt: null } : {}),
      createdBy: p.pendingBy ?? 'coach',
      createdAt: minutesAgo(60 * 24 * 20),
      updatedAt: minutesAgo(60 * 24 * 20),
    });
    const links: [string, 'self' | 'guardian'][] = [
      ...p.guardians.map((uid): [string, 'guardian'] => [uid, 'guardian']),
      ...(p.self ? [[p.self, 'self'] as [string, 'self']] : []),
    ];
    for (const [uid, relation] of links) {
      batch.set(db.doc(`playerGuardians/${p.id}_${uid}`), {
        playerId: p.id,
        groupId: p.groupId,
        uid,
        relation,
        addedBy: 'coach',
        via: relation === 'self' ? 'request' : 'admin',
        createdAt: minutesAgo(60 * 24 * 20),
      });
    }
  }
  // Details for coaches (PLAYER-12), sample values only: Emma's from her
  // guardian Maria, with the medical consent the app asks for, and Alex's
  // own. The coach sees both, and their ages on the rosters.
  const year = new Date(now).getFullYear();
  batch.set(db.doc('playerDetails/emma'), {
    groupId: 'cyclone',
    dateOfBirth: `${year - 9}-05-14`,
    emergencyContacts: [
      { name: 'Maria Rodriguez', phone: '555-0100', relationship: 'Mom' },
      { name: 'Luis Rodriguez', phone: '555-0101', relationship: 'Dad' },
    ],
    medicalNotes: 'Peanut allergy',
    medicalConsentAt: minutesAgo(60 * 24 * 10),
    medicalConsentBy: 'maria',
    notes: 'Wears glasses for games.',
    updatedBy: 'maria',
    updatedAt: minutesAgo(60 * 24 * 10),
  });
  batch.set(db.doc('playerDetails/alex-kim'), {
    groupId: 'thunder',
    dateOfBirth: `${year - 31}-02-20`,
    emergencyContacts: [{ name: 'Jamie Kim', phone: '555-0142', relationship: 'Partner' }],
    medicalNotes: null,
    notes: null,
    updatedBy: 'alex',
    updatedAt: minutesAgo(60 * 24 * 10),
  });
  // Luis claims Noah as a guardian, waiting for the coach (PLAYER-3).
  batch.set(db.doc('guardianRequests/noah_luis'), {
    playerId: 'noah',
    groupId: 'cyclone',
    uid: 'luis',
    relation: 'guardian',
    status: 'pending',
    decidedBy: null,
    decidedAt: null,
    createdAt: minutesAgo(60),
  });
  await batch.commit();

  // Upcoming events with a few RSVPs: per player on every team, and
  // members answering for themselves (coaches and others, SCHED-5). A few
  // past ones fill in each player's RSVP history (PLAYER-11). Thunder's
  // game has its card in the chat (CHAT-11).
  const events: { id: string; groupId: string; type: string; title: string; day: number; hour: number; opponent?: string; homeAway?: string; card?: true }[] = [
    { id: 'thunder-practice', groupId: 'thunder', type: 'practice', title: 'Practice', day: 2, hour: 18 },
    { id: 'thunder-game', groupId: 'thunder', type: 'game', title: 'vs. Eagles', day: 5, hour: 10, opponent: 'Eagles', homeAway: 'home', card: true },
    { id: 'thunder-practice-2', groupId: 'thunder', type: 'practice', title: 'Practice', day: 9, hour: 18 },
    { id: 'thunder-bbq', groupId: 'thunder', type: 'social', title: 'Season kickoff BBQ', day: 12, hour: 17 },
    { id: 'cyclone-practice', groupId: 'cyclone', type: 'practice', title: 'Practice', day: 1, hour: 17 },
    { id: 'cyclone-game', groupId: 'cyclone', type: 'game', title: 'vs. Comets', day: 4, hour: 9, opponent: 'Comets', homeAway: 'home' },
    { id: 'possums-game', groupId: 'possums', type: 'game', title: '@ Bulls', day: 3, hour: 19, opponent: 'Bulls', homeAway: 'away' },
    { id: 'thunder-past-practice', groupId: 'thunder', type: 'practice', title: 'Practice', day: -6, hour: 18 },
    { id: 'cyclone-past-practice', groupId: 'cyclone', type: 'practice', title: 'Practice', day: -12, hour: 17 },
    { id: 'cyclone-past-game', groupId: 'cyclone', type: 'game', title: 'vs. Comets', day: -5, hour: 10, opponent: 'Comets', homeAway: 'home' },
  ];
  const place = { name: 'Riverside Park, Field 3', address: '100 River Rd' };
  for (const e of events) {
    const startAt = daysFromNow(e.day, e.hour);
    await db.doc(`events/${e.id}`).set({
      groupId: e.groupId,
      type: e.type,
      title: e.title,
      description: '',
      location: place,
      allDay: false,
      startAt,
      endAt: Timestamp.fromMillis(startAt.toMillis() + 90 * 60_000),
      timeZone: 'America/Chicago',
      opponent: e.opponent ?? null,
      homeAway: e.homeAway ?? null,
      rsvpEnabled: true,
      reminderOffsets: [1440],
      rsvpCounts: { going: 0, maybe: 0, notGoing: 0 },
      staffCounts: { going: 0, maybe: 0, notGoing: 0 },
      // Sample history: no "new event" notice, and the seed writes the one
      // card it shows (the events trigger sees it's there).
      notifyTeam: false,
      postToChat: e.card === true,
      ...(e.card ? { messageId: e.id } : {}),
      createdBy: 'coach',
      createdAt: minutesAgo(60 * 24),
      updatedAt: minutesAgo(60 * 24),
      schemaVersion: 1,
    });
  }
  const rsvps: [string, 'member' | 'player', string, string, string][] = [
    ['thunder-practice', 'player', 'alex-kim', 'going', 'alex'],
    ['thunder-practice', 'player', 'sam-rivera', 'maybe', 'sam'],
    ['thunder-practice', 'member', 'coach', 'going', 'coach'],
    ['thunder-game', 'player', 'alex-kim', 'going', 'alex'],
    ['thunder-game', 'player', 'sam-rivera', 'going', 'sam'],
    ['thunder-game', 'player', 'casey-park', 'maybe', 'coach'],
    ['thunder-game', 'member', 'coach', 'going', 'coach'],
    ['cyclone-practice', 'player', 'emma', 'going', 'luis'],
    ['cyclone-practice', 'player', 'arjun', 'not_going', 'priya'],
    ['cyclone-practice', 'member', 'coach', 'going', 'coach'],
    ['possums-game', 'player', 'liam', 'going', 'maria'],
    ['possums-game', 'player', 'dee', 'going', 'tasha'],
    ['thunder-past-practice', 'player', 'alex-kim', 'going', 'alex'],
    ['cyclone-past-practice', 'player', 'emma', 'going', 'luis'],
    ['cyclone-past-practice', 'player', 'arjun', 'going', 'priya'],
    ['cyclone-past-game', 'player', 'emma', 'not_going', 'maria'],
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
  const countsOf = (answers: typeof rsvps) => ({
    going: answers.filter((r) => r[3] === 'going').length,
    maybe: answers.filter((r) => r[3] === 'maybe').length,
    notGoing: answers.filter((r) => r[3] === 'not_going').length,
  });
  for (const e of events) {
    const answers = rsvps.filter((r) => r[0] === e.id);
    await db.doc(`events/${e.id}`).update({
      rsvpCounts: countsOf(answers.filter((r) => r[1] === 'player')),
      staffCounts: countsOf(answers.filter((r) => r[1] === 'member')),
    });
  }

  // Polls (POLL-1): a poll message shares its poll's ID, the question its
  // text. Rally Possums' takes more than one answer.
  const polls: { id: string; groupId: string; by: string; question: string; options: string[]; votes: Record<string, number[]>; allowMultiple?: true; ago: number }[] = [
    {
      id: 'thunder-dinner', groupId: 'thunder', by: 'coach', question: 'Team dinner after the game?',
      options: ['Tacos', 'Pizza', 'Burgers'], votes: { alex: [0], sam: [0], maria: [0], coach: [1] }, ago: 150,
    },
    {
      id: 'possums-tournament', groupId: 'possums', by: 'priya', question: 'Which tournament weekend works for your family?',
      options: ['Nov 7–8', 'Nov 14–15', 'Dec 5–6'], votes: { priya: [0, 1], maria: [0], tasha: [1], ben: [0] }, allowMultiple: true, ago: 120,
    },
  ];
  for (const p of polls) {
    const counts: Record<string, number> = {};
    for (const ids of Object.values(p.votes)) for (const i of ids) counts[`${i}`] = (counts[`${i}`] ?? 0) + 1;
    await db.doc(`polls/${p.id}`).set({
      groupId: p.groupId,
      messageId: p.id,
      createdBy: p.by,
      question: p.question,
      options: p.options.map((text, i) => ({ id: `${i}`, text })),
      allowMultiple: p.allowMultiple ?? false,
      anonymous: false,
      closesAt: null,
      closedAt: null,
      voteCounts: counts,
      voterCount: Object.keys(p.votes).length,
      createdAt: minutesAgo(p.ago),
    });
    for (const [uid, ids] of Object.entries(p.votes)) {
      await db.doc(`pollVotes/${p.id}_${uid}`).set({
        pollId: p.id, groupId: p.groupId, uid, optionIds: ids.map((i) => `${i}`), updatedAt: minutesAgo(p.ago - 5),
      });
    }
  }

  // Messages, with the team preview the messages trigger would write (M3).
  // Thunder's first is the coach's announcement, pinned to the top; Alex
  // mentions the coach; the game's card and the dinner poll sit between
  // (CHAT-11, CHAT-14, CHAT-15). Cyclone's has a reply and a mention.
  type Line = { uid: string; text: string; ago: number; extra?: Record<string, unknown>; id?: string };
  const when = (e: (typeof events)[number]) =>
    new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/Chicago', weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit',
    }).format(daysFromNow(e.day, e.hour).toDate()).replace(/, (\d+:\d+)/, ' at $1');
  const game = events.find((e) => e.id === 'thunder-game')!;
  const chats: Record<string, Line[]> = {
    thunder: [
      { uid: 'coach', text: 'Field 3 is open tonight. See everyone at 6!', ago: 300, extra: { announcement: true, reactions: { alex: 'like', sam: 'love', maria: 'like' } } },
      { uid: 'alex', text: `@${nameOf('coach')} I can bring the extra bats.`, ago: 260, extra: { mentions: ['coach'] } },
      { uid: 'coach', id: game.id, text: `${game.title} · ${when(game)} · ${place.name}`, ago: 200, extra: { type: 'event', eventId: game.id, seriesId: null } },
      { uid: 'coach', id: 'thunder-dinner', text: 'Team dinner after the game?', ago: 150, extra: { type: 'poll', pollId: 'thunder-dinner' } },
      { uid: 'sam', text: 'Tacos, every time.', ago: 45, extra: { reactions: { alex: 'laugh' } } },
      { uid: 'sam', text: 'On my way!', ago: 10 },
    ],
    cyclone: [
      { uid: 'coach', text: 'Reminder: shin guards for everyone on Saturday.', ago: 600, extra: { reactions: { maria: 'like', luis: 'like', priya: 'love' } } },
      { uid: 'maria', text: 'Emma and Mia will be there. Can someone carpool from the school?', ago: 140 },
      {
        uid: 'priya', text: "We can take two! Arjun's leaving at 8:30.", ago: 120,
        extra: {
          replyToId: 'cyclone-seed-1',
          replyPreview: { authorName: nameOf('maria'), text: 'Emma and Mia will be there. Can someone carpool from the school?', type: 'text', deleted: false },
          reactions: { maria: 'love' },
        },
      },
      { uid: 'coach', text: `@${nameOf('priya')} thank you! Kickoff is at 9:30, warmups at 9.`, ago: 95, extra: { mentions: ['priya'] } },
      { uid: 'luis', text: "Emma's cleats are in my car. I'll bring them.", ago: 30, extra: { reactions: { maria: 'love' } } },
    ],
    possums: [
      { uid: 'priya', text: 'Great hustle at practice today, team.', ago: 300, extra: { reactions: { maria: 'love', tasha: 'like' } } },
      { uid: 'priya', id: 'possums-tournament', text: 'Which tournament weekend works for your family?', ago: 120, extra: { type: 'poll', pollId: 'possums-tournament' } },
      { uid: 'tasha', text: 'Either November weekend works for us!', ago: 60 },
      { uid: 'ben', text: "Owen's in for both. 🏀", ago: 20 },
    ],
  };
  for (const [groupId, list] of Object.entries(chats)) {
    for (const [i, line] of list.entries()) {
      const m = memberships.find((x) => x[0] === groupId && x[1] === line.uid)!;
      await db.doc(`messages/${line.id ?? `${groupId}-seed-${i}`}`).set({
        groupId,
        authorId: line.uid,
        authorName: nameOf(line.uid),
        authorPhotoPath: null,
        authorPlayerSummary: m[3] ?? null,
        type: 'text',
        text: line.text,
        attachments: [],
        reactions: {},
        ...line.extra,
        createdAt: minutesAgo(line.ago),
      });
    }
    const last = list[list.length - 1];
    await db.doc(`groups/${groupId}`).update({
      lastMessageAt: minutesAgo(last.ago),
      lastMessagePreview: { authorName: nameOf(last.uid), text: last.text, type: 'text' },
      ...(groupId === 'thunder' ? { pinnedMessageIds: ['thunder-seed-0'] } : {}),
    });
  }

  // Thunder's documents (DOC-1): the lineup and rules pinned, a link, and
  // more files. The rows show without the files themselves.
  const docs: { id: string; name: string; kind: 'file' | 'link'; by: string; days: number; pinned?: true; type?: string; size?: number; url?: string }[] = [
    { id: 'thunder-lineup', name: 'Saturday lineup.pdf', kind: 'file', by: 'coach', days: 1, pinned: true, type: 'application/pdf', size: 86_000 },
    { id: 'thunder-rules', name: 'League rules 2026.pdf', kind: 'file', by: 'coach', days: 10, pinned: true, type: 'application/pdf', size: 1_240_000 },
    { id: 'thunder-directions', name: 'Field directions', kind: 'link', by: 'alex', days: 5, url: 'https://maps.example.com/riverside-park' },
    { id: 'thunder-plan', name: 'Practice plan.docx', kind: 'file', by: 'alex', days: 2, type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', size: 46_000 },
    { id: 'thunder-waiver', name: 'Player waiver.pdf', kind: 'file', by: 'coach', days: 20, type: 'application/pdf', size: 220_000 },
  ];
  for (const d of docs) {
    await db.doc(`groupDocuments/${d.id}`).set({
      groupId: 'thunder',
      kind: d.kind,
      name: d.name,
      nameLower: d.name.toLowerCase(),
      description: '',
      pinned: d.pinned ?? false,
      ...(d.kind === 'file'
        ? { path: `groups/thunder/documents/${d.id}/${d.name}`, contentType: d.type, size: d.size }
        : { url: d.url }),
      uploadedBy: d.by,
      uploaderName: nameOf(d.by),
      notifyTeam: false,
      createdAt: minutesAgo(d.days * 60 * 24),
      updatedAt: minutesAgo(d.days * 60 * 24),
    });
  }

  // A saved play (BOARD-4): Thunder's bunt defense on the diamond, the
  // corners charging and second covering first, then where everyone ends
  // up. Positions match lib/features/plays/domain/board_layout.dart.
  const m = (id: string, x: number, y: number, s: string, l = '') => ({ k: 'm', id, x, y, s, ...(l ? { l } : {}) });
  const a = (id: string, t: string, pts: number[]) => ({ k: 'a', id, t, pts });
  await db.doc('plays/thunder-bunt').set({
    groupId: 'thunder',
    board: 'baseball',
    variant: 'full',
    title: 'Bunt defense',
    note: 'Corners crash on the pitch. Second covers first; short covers second.',
    steps: [
      {
        elements: [
          m('p', 0.5, 0.7713, 'team', 'P'), m('c', 0.5, 0.9255, 'team', 'C'),
          m('1b', 0.6474, 0.7196, 'team', '1B'), m('2b', 0.5777, 0.6412, 'team', '2B'),
          m('ss', 0.4223, 0.6412, 'team', 'SS'), m('3b', 0.3526, 0.7196, 'team', '3B'),
          m('lf', 0.2303, 0.3928, 'team', 'LF'), m('cf', 0.5, 0.2617, 'team', 'CF'),
          m('rf', 0.7697, 0.3928, 'team', 'RF'), m('b', 0.465, 0.9, 'opponent', 'B'),
          m('ball', 0.53, 0.7833, 'ball'),
          a('a1', 'run', [0.6474, 0.7196, 0.6, 0.81]), a('a3', 'run', [0.3526, 0.7196, 0.41, 0.81]),
          a('a2', 'run', [0.5777, 0.6412, 0.6354, 0.7646]), a('as', 'run', [0.4223, 0.6412, 0.5, 0.6292]),
        ],
      },
      {
        elements: [
          m('p', 0.5, 0.83, 'team', 'P'), m('c', 0.5, 0.9255, 'team', 'C'),
          m('1b', 0.6, 0.81, 'team', '1B'), m('2b', 0.6354, 0.7646, 'team', '2B'),
          m('ss', 0.5, 0.6292, 'team', 'SS'), m('3b', 0.41, 0.81, 'team', '3B'),
          m('lf', 0.2303, 0.3928, 'team', 'LF'), m('cf', 0.5, 0.2617, 'team', 'CF'),
          m('rf', 0.7697, 0.3928, 'team', 'RF'), m('b', 0.58, 0.85, 'opponent', 'B'),
          m('ball', 0.47, 0.86, 'ball'),
          a('t1', 'pass', [0.47, 0.86, 0.6354, 0.7646]),
        ],
      },
    ],
    createdBy: 'coach',
    createdAt: minutesAgo(60 * 24 * 2),
    updatedAt: minutesAgo(60 * 24),
  });

  await db.doc('config/app').set({
    allowUserGroupCreation: true,
    maxGroupsCreatedPerUserPerDay: 5,
    defaultStorageQuotaMb: 500,
    maxUploadMb: 10,
    maxImageMb: 10,
    supportEmail: 'support@getbattleplan.app',
  });

  console.log(`Seeded ${people.length} people, ${teams.length} teams, ${players.length} players.`);
  console.log('Sign in as coach@example.com (Thunder and Cyclone) or maria@example.com (all three teams); password "password".');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
