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
import { createHash } from 'node:crypto';

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

// The sample people are common American names and TV characters (they're
// on the website's screenshots too).
const people: Person[] = [
  { uid: 'coach', name: 'Andy Bernard', email: 'coach@example.com' },
  { uid: 'jim', name: 'Jim Halpert', email: 'jim@example.com' },
  { uid: 'andy', name: 'Andy Dwyer', email: 'andy@example.com' },
  { uid: 'claire', name: 'Claire Dunphy', email: 'claire@example.com' },
  { uid: 'phil', name: 'Phil Dunphy', email: 'phil@example.com' },
  { uid: 'rachel', name: 'Rachel Green', email: 'rachel@example.com' },
  { uid: 'monica', name: 'Monica Geller', email: 'monica@example.com' },
  { uid: 'chandler', name: 'Chandler Bing', email: 'chandler@example.com' },
  { uid: 'admin', name: 'Platform Admin', email: 'admin@example.com', superAdmin: true },
];

const settings = {
  membersCanCreateEvents: false,
  membersCanCreatePolls: true,
  membersCanUploadDocs: true,
  membersCanInvite: true,
  allowMaybe: true,
  membersCanSeePeople: true,
  filterLanguage: true,
  defaultReminderOffsets: [1440],
};

// One team type (TEAM-1): every team has players.
// Each team's color and its chat bubbles' (CHAT-18): navy and orange,
// Carolina blue and gray, purple and gold.
const teams = [
  { id: 'thunder', name: 'Thunder', sport: 'softball', color: '#1E3A5F', bubbleColor: '#C2410C' },
  { id: 'cyclone', name: 'Cyclone', sport: 'soccer', color: '#7BAFD4', bubbleColor: '#334155' },
  { id: 'possums', name: 'Rally Possums', sport: 'basketball', color: '#7C3AED', bubbleColor: '#D4A017' },
] as const;

// [team, uid, role, playerSummary?]. Coach, Claire, and Rachel are on more
// than one team.
const memberships: [string, string, string, string?][] = [
  ['thunder', 'coach', 'owner'],
  ['thunder', 'jim', 'admin', '#3'],
  ['thunder', 'andy', 'member', '#12'],
  ['thunder', 'claire', 'member'],
  ['cyclone', 'coach', 'owner'],
  ['cyclone', 'claire', 'member', 'Luke #7, Alex #9'],
  ['cyclone', 'phil', 'member', 'Luke #7'],
  ['cyclone', 'rachel', 'member', 'Emma #11'],
  ['possums', 'rachel', 'owner'],
  ['possums', 'claire', 'member', 'Haley #23'],
  ['possums', 'monica', 'member', 'Erica #4'],
  ['possums', 'chandler', 'member', 'Jack #12'],
];

// A parent with players on two teams and two on one (for "All my
// players", PLAYER-11), two guardians for one player, a
// player whose guardian hasn't joined yet, adults who are players
// themselves ('self'), an unclaimed player, and a pending player Claire
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
  /** The song played as they come up to bat (PLAYER-2). */
  walkUpSong?: string;
}[] = [
  { id: 'luke-dunphy', groupId: 'cyclone', name: 'Luke Dunphy', number: '7', position: 'Forward', guardians: ['claire', 'phil'] },
  { id: 'alex-dunphy', groupId: 'cyclone', name: 'Alex Dunphy', number: '9', position: 'Midfield', guardians: ['claire'] },
  { id: 'emma-green', groupId: 'cyclone', name: 'Emma Green', number: '11', position: 'Keeper', guardians: ['rachel'] },
  { id: 'noah-bennett', groupId: 'cyclone', name: 'Noah Bennett', number: '4', position: 'Defense', guardians: [] },
  { id: 'haley-dunphy', groupId: 'possums', name: 'Haley Dunphy', number: '23', position: 'Guard', guardians: ['claire'] },
  { id: 'erica-bing', groupId: 'possums', name: 'Erica Bing', number: '4', position: 'Forward', guardians: ['monica'] },
  { id: 'jack-bing', groupId: 'possums', name: 'Jack Bing', number: '12', position: 'Center', guardians: ['chandler'] },
  { id: 'jim-halpert', groupId: 'thunder', name: 'Jim Halpert', number: '3', position: 'Pitcher', guardians: [], self: 'jim', walkUpSong: 'Thunderstruck, AC/DC' },
  { id: 'andy-dwyer', groupId: 'thunder', name: 'Andy Dwyer', number: '12', position: 'Shortstop', guardians: [], self: 'andy', walkUpSong: 'Eye of the Tiger, Survivor' },
  { id: 'pam-beesly', groupId: 'thunder', name: 'Pam Beesly', number: '5', position: 'Outfield', guardians: [], walkUpSong: 'Walking on Sunshine, Katrina and the Waves' },
  { id: 'claire-dunphy', groupId: 'thunder', name: 'Claire Dunphy', number: null, position: null, guardians: [], pendingBy: 'claire' },
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
      chatTheme: { bubbleColor: t.bubbleColor, background: 'plain', backgroundPath: null },
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
      storageQuotaBytes: 200 * 1024 * 1024,
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
      title: role === 'owner' ? 'Coach' : groupId === 'cyclone' && uid === 'phil' ? 'Assistant coach' : null,
      // A parent who coaches too (TEAM-3); owners coach unless set.
      ...(groupId === 'cyclone' && uid === 'phil' ? { coach: true } : {}),
      displayName: nameOf(uid),
      photoPath: null,
      playerSummary: playerSummary ?? null,
      notificationLevel: 'all',
      mutedUntil: null,
      // The coach last read Thunder before Jim's message, so its chat
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
      ...(p.walkUpSong ? { walkUpSong: p.walkUpSong } : {}),
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
  // Details for coaches (PLAYER-12), sample values only: Luke's from his
  // guardian Claire, with the medical consent the app asks for, and Jim's
  // own. The coach sees both, and their ages on the rosters.
  const year = new Date(now).getFullYear();
  batch.set(db.doc('playerDetails/luke-dunphy'), {
    groupId: 'cyclone',
    dateOfBirth: `${year - 9}-05-14`,
    emergencyContacts: [
      { name: 'Claire Dunphy', phone: '555-0100', relationship: 'Mom' },
      { name: 'Phil Dunphy', phone: '555-0101', relationship: 'Dad' },
    ],
    medicalNotes: 'Peanut allergy',
    medicalConsentAt: minutesAgo(60 * 24 * 10),
    medicalConsentBy: 'claire',
    notes: 'Wears glasses for games.',
    updatedBy: 'claire',
    updatedAt: minutesAgo(60 * 24 * 10),
  });
  batch.set(db.doc('playerDetails/jim-halpert'), {
    groupId: 'thunder',
    dateOfBirth: `${year - 31}-02-20`,
    emergencyContacts: [{ name: 'Pam Beesly', phone: '555-0142', relationship: 'Partner' }],
    medicalNotes: null,
    notes: null,
    updatedBy: 'jim',
    updatedAt: minutesAgo(60 * 24 * 10),
  });
  // Phil claims Noah as a guardian, waiting for the coach (PLAYER-3).
  batch.set(db.doc('guardianRequests/noah-bennett_phil'), {
    playerId: 'noah-bennett',
    groupId: 'cyclone',
    uid: 'phil',
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
    ['thunder-practice', 'player', 'jim-halpert', 'going', 'jim'],
    ['thunder-practice', 'player', 'andy-dwyer', 'maybe', 'andy'],
    ['thunder-practice', 'member', 'coach', 'going', 'coach'],
    ['thunder-game', 'player', 'jim-halpert', 'going', 'jim'],
    ['thunder-game', 'player', 'andy-dwyer', 'going', 'andy'],
    ['thunder-game', 'player', 'pam-beesly', 'maybe', 'coach'],
    ['thunder-game', 'member', 'coach', 'going', 'coach'],
    ['cyclone-practice', 'player', 'luke-dunphy', 'going', 'phil'],
    ['cyclone-practice', 'player', 'emma-green', 'not_going', 'rachel'],
    ['cyclone-practice', 'member', 'coach', 'going', 'coach'],
    ['possums-game', 'player', 'haley-dunphy', 'going', 'claire'],
    ['possums-game', 'player', 'erica-bing', 'going', 'monica'],
    ['thunder-past-practice', 'player', 'jim-halpert', 'going', 'jim'],
    ['cyclone-past-practice', 'player', 'luke-dunphy', 'going', 'phil'],
    ['cyclone-past-practice', 'player', 'emma-green', 'going', 'rachel'],
    ['cyclone-past-game', 'player', 'luke-dunphy', 'not_going', 'claire'],
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
      options: ['Tacos', 'Pizza', 'Burgers'], votes: { jim: [0], andy: [0], claire: [0], coach: [1] }, ago: 150,
    },
    {
      id: 'possums-tournament', groupId: 'possums', by: 'rachel', question: 'Which tournament weekend works for your family?',
      options: ['Nov 7–8', 'Nov 14–15', 'Dec 5–6'], votes: { rachel: [0, 1], claire: [0], monica: [1], chandler: [0] }, allowMultiple: true, ago: 120,
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
  // Thunder's first is the coach's announcement, pinned to the top; Jim
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
      { uid: 'coach', text: 'Field 3 is open tonight. See everyone at 6!', ago: 300, extra: { announcement: true, reactions: { jim: 'like', andy: 'love', claire: 'like' } } },
      { uid: 'jim', text: `@${nameOf('coach')} I can bring the extra bats.`, ago: 260, extra: { mentions: ['coach'] } },
      { uid: 'coach', id: game.id, text: `${game.title} · ${when(game)} · ${place.name}`, ago: 200, extra: { type: 'event', eventId: game.id, seriesId: null } },
      { uid: 'coach', id: 'thunder-dinner', text: 'Team dinner after the game?', ago: 150, extra: { type: 'poll', pollId: 'thunder-dinner' } },
      { uid: 'andy', text: 'Tacos, every time.', ago: 45, extra: { reactions: { jim: 'laugh' } } },
      { uid: 'andy', text: 'On my way!', ago: 10 },
    ],
    cyclone: [
      { uid: 'coach', text: 'Reminder: shin guards for everyone on Saturday.', ago: 600, extra: { reactions: { claire: 'like', phil: 'like', rachel: 'love' } } },
      { uid: 'claire', text: 'Luke and Alex will be there. Can someone carpool from the school?', ago: 140 },
      {
        uid: 'rachel', text: "We can take two! Emma's leaving at 8:30.", ago: 120,
        extra: {
          replyToId: 'cyclone-seed-1',
          replyPreview: { authorName: nameOf('claire'), text: 'Luke and Alex will be there. Can someone carpool from the school?', type: 'text', deleted: false },
          reactions: { claire: 'love' },
        },
      },
      { uid: 'coach', text: `@${nameOf('rachel')} thank you! Kickoff is at 9:30, warmups at 9.`, ago: 95, extra: { mentions: ['rachel'] } },
      { uid: 'phil', text: "Luke's cleats are in my car. I'll bring them.", ago: 30, extra: { reactions: { claire: 'love' } } },
    ],
    possums: [
      { uid: 'rachel', text: 'Great hustle at practice today, team.', ago: 300, extra: { reactions: { claire: 'love', monica: 'like' } } },
      { uid: 'rachel', id: 'possums-tournament', text: 'Which tournament weekend works for your family?', ago: 120, extra: { type: 'poll', pollId: 'possums-tournament' } },
      { uid: 'monica', text: 'Either weekend works for us!', ago: 60 },
      { uid: 'chandler', text: "Jack's in for both. 🏀", ago: 20 },
      { uid: 'rachel', text: "Nov 7–8 it is! I'll send the bracket.", ago: 8 },
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

  // A direct conversation (CHAT-19): Claire asks the coach about Alex, and
  // both have read it, so Messages has one to show and nothing is unread.
  // Its ID is the one openDirectChat makes for the pair (teams/direct.ts).
  const dmPeople = ['claire', 'coach'];
  const dm = `dm${createHash('sha256').update(dmPeople.join('\n')).digest('hex').slice(0, 32)}`;
  const dmLines = [
    { uid: 'claire', text: "Is Alex OK to play Saturday? She's been nursing a sore ankle.", ago: 400 },
    { uid: 'coach', text: "Let's see how she feels at warmups. We'll keep her minutes light.", ago: 380 },
    { uid: 'claire', text: 'Sounds good, thank you!', ago: 376 },
  ];
  const dmLast = dmLines[dmLines.length - 1];
  await db.doc(`groups/${dm}`).set({
    kind: 'direct',
    uids: dmPeople,
    people: Object.fromEntries(dmPeople.map((uid) => [uid, { name: nameOf(uid), photoPath: null }])),
    name: '',
    nameLower: '',
    description: '',
    photoPath: null,
    color: null,
    sport: 'other',
    ownerId: null,
    createdBy: 'claire',
    timeZone: 'UTC',
    settings: {
      membersCanCreateEvents: false,
      membersCanCreatePolls: false,
      membersCanUploadDocs: false,
      membersCanInvite: false,
      allowMaybe: false,
      membersCanSeePeople: true,
      filterLanguage: true,
      defaultReminderOffsets: [],
    },
    memberCount: 2,
    playerCount: 0,
    lastMessageAt: minutesAgo(dmLast.ago),
    lastMessagePreview: { authorName: nameOf(dmLast.uid), text: dmLast.text, type: 'text', authorId: dmLast.uid },
    storageBytes: 0,
    storageQuotaBytes: 50 * 1024 * 1024,
    storageQuotaCustom: true,
    storageAlert: 'none',
    archivedAt: null,
    suspendedAt: null,
    status: 'active',
    createdAt: minutesAgo(400),
    updatedAt: minutesAgo(376),
    schemaVersion: 1,
  });
  for (const uid of dmPeople) {
    await db.doc(`groupMembers/${dm}_${uid}`).set({
      groupId: dm,
      uid,
      otherUid: dmPeople.find((u) => u !== uid),
      role: 'participant',
      title: null,
      displayName: nameOf(uid),
      photoPath: null,
      playerSummary: null,
      notificationLevel: 'all',
      mutedUntil: null,
      lastMessageAt: minutesAgo(dmLast.ago),
      lastReadAt: minutesAgo(dmLast.ago - 1),
      lastPostedAt: null,
      joinedAt: minutesAgo(400),
      addedBy: 'claire',
    });
  }
  for (const [i, line] of dmLines.entries()) {
    await db.doc(`messages/dm-seed-${i}`).set({
      groupId: dm,
      authorId: line.uid,
      authorName: nameOf(line.uid),
      authorPhotoPath: null,
      authorPlayerSummary: null,
      type: 'text',
      text: line.text,
      attachments: [],
      reactions: {},
      createdAt: minutesAgo(line.ago),
    });
  }

  // Thunder's documents (DOC-1): the lineup and rules pinned, a link, and
  // more files. The rows show without the files themselves.
  const docs: { id: string; name: string; kind: 'file' | 'link'; by: string; days: number; pinned?: true; type?: string; size?: number; url?: string }[] = [
    { id: 'thunder-lineup', name: 'Saturday lineup.pdf', kind: 'file', by: 'coach', days: 1, pinned: true, type: 'application/pdf', size: 86_000 },
    { id: 'thunder-rules', name: 'League rules 2026.pdf', kind: 'file', by: 'coach', days: 10, pinned: true, type: 'application/pdf', size: 1_240_000 },
    { id: 'thunder-directions', name: 'Field directions', kind: 'link', by: 'jim', days: 5, url: 'https://maps.example.com/riverside-park' },
    { id: 'thunder-plan', name: 'Practice plan.docx', kind: 'file', by: 'jim', days: 2, type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', size: 46_000 },
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

  // Saved plays (BOARD-4), one on each of the coach's teams for the landing
  // page's two whiteboard screenshots; a team's whiteboard draws any board.
  // Cyclone's relay home from right-center, as the owner drew it: a ball in
  // the right-center gap with a runner on second. Step 1, everyone heads for
  // their spot; step 2, the throws: RF to 2B, the relay, to 1B, the cutoff
  // on the line to the plate, who lets it go home or cuts it and throws to
  // second for the batter. Spots are feet from home along a direction (0°
  // is dead center, negative toward left), as BaseballField.fromHome
  // measures them in lib/features/plays/domain/board_layout.dart.
  const m = (id: string, x: number, y: number, s: string, l = '') => ({ k: 'm', id, x, y, s, ...(l ? { l } : {}) });
  const a = (id: string, t: string, pts: number[]) => ({ k: 'a', id, t, pts });
  const fh = (feet: number, degrees: number): [number, number] => {
    const r = (degrees * Math.PI) / 180;
    return [0.5 + (feet / 470) * Math.sin(r), 0.9 - (feet / 470) * Math.cos(r)];
  };
  const on = (id: string, spot: [number, number], s: string, l = '') => m(id, ...spot, s, l);
  const line = (...spots: [number, number][]) => spots.flat();
  // From one spot to another, stopping short of each player by about a
  // marker's width, so a throw runs from glove to glove.
  const throwLine = (from: [number, number], to: [number, number], shortOfTo = 0.035) => {
    const [dx, dy] = [to[0] - from[0], to[1] - from[1]];
    const length = Math.hypot(dx, dy);
    const [ux, uy] = [dx / length, dy / length];
    return line([from[0] + ux * 0.035, from[1] + uy * 0.035], [to[0] - ux * shortOfTo, to[1] - uy * shortOfTo]);
  };
  // Where the fielders stand at the pitch, as the whiteboard's defense puts them.
  const start: Record<string, [number, number]> = {
    P: [0.5, 0.7713], C: [0.5, 0.9255], '1B': [0.6474, 0.7196], '2B': [0.5777, 0.6412],
    SS: [0.4223, 0.6412], '3B': [0.3526, 0.7196], LF: [0.2303, 0.3928], CF: [0.5, 0.2617], RF: [0.7697, 0.3928],
  };
  // Where they are when the throw comes in: RF at the ball with CF beside
  // him, 2B out as the relay, 1B on the line from the relay to the plate,
  // SS covering second, LF backing up third, P backing up home.
  const relay: Record<string, [number, number]> = {
    P: fh(-36, -9), C: fh(5, -64), '1B': fh(86, 20.5), '2B': fh(216, 20.5),
    SS: fh(111, -11), '3B': fh(99, -41), LF: fh(122, -66), CF: fh(331, 15), RF: fh(341, 19),
  };
  const second = fh(90 * Math.SQRT2, 0);
  const batter: [number, number] = [0.465, 0.9];
  const fielders = (spots: Record<string, [number, number]>) =>
    Object.entries(spots).map(([l, spot]) => on(l.toLowerCase(), spot, 'team', l));
  await db.doc('plays/cyclone-relay-home').set({
    groupId: 'cyclone',
    board: 'baseball',
    variant: 'full',
    title: 'Relay home from right-center',
    note: 'Ball in the right-center gap, runner on second. RF gets it with CF backing him up; 2B goes out as the relay. 1B is the cutoff: let it go home, or cut it and throw to second if the batter tries for it. SS covers second, 3B covers third with LF behind him, and P backs up home.',
    steps: [
      {
        elements: [
          ...fielders(start),
          on('r', second, 'opponent', 'R'), on('b', batter, 'opponent', 'B'),
          on('ball', fh(356, 18), 'ball'),
          a('hit', 'pass', line(fh(8, 14), fh(340, 18))),
          ...['RF', 'CF', '2B', '1B', 'LF'].map((l) => a(`to-${l}`, 'run', line(start[l], relay[l]))),
          // Around the batter and the catcher to back up the plate.
          a('to-P', 'run', line(start.P, [0.55, 0.9], relay.P)),
          a('r-run', 'run', line(second, fh(90, -45), fh(59, -45))),
          a('b-run', 'run', line(batter, fh(90, 45), fh(126, 11))),
        ],
      },
      {
        elements: [
          ...fielders(relay),
          on('r', fh(59, -45), 'opponent', 'R'), on('b', fh(126, 11), 'opponent', 'B'),
          on('ball', fh(356, 18), 'ball'),
          a('relay', 'pass', throwLine(relay.RF, relay['2B'])),
          a('cutoff', 'pass', throwLine(relay['2B'], relay['1B'])),
          a('home', 'pass', throwLine(relay['1B'], relay.C)),
          a('second', 'pass', throwLine(relay['1B'], second, 0.012)),
        ],
      },
    ],
    createdBy: 'coach',
    createdAt: minutesAgo(60 * 24 * 2),
    updatedAt: minutesAgo(60 * 24),
  });

  // Thunder's pick and roll on the half court: the center
  // screens for the point guard at the top, then rolls to the rim for the
  // pass. Spots are in feet on the half court, 50 wide and 47 deep, the
  // basket at the top (BasketballCourt in board_layout.dart).
  const ft = (x: number, y: number): [number, number] => [x / 50, y / 47];
  const at = (id: string, x: number, y: number, s: string, l = '') => m(id, ...ft(x, y), s, l);
  const path = (...spots: [number, number][]) => spots.flatMap(([x, y]) => ft(x, y));
  await db.doc('plays/thunder-pick-and-roll').set({
    groupId: 'thunder',
    board: 'basketball',
    variant: 'half',
    title: 'Pick and roll',
    note: 'C sets the screen up top, then rolls to the rim. PG reads the switch: pull up, or hit C on the roll.',
    steps: [
      {
        elements: [
          at('pg', 25, 31, 'team', 'PG'), at('sg', 43, 19, 'team', 'SG'), at('sf', 7, 19, 'team', 'SF'),
          at('pf', 41, 6, 'team', 'PF'), at('c', 16, 11, 'team', 'C'),
          at('d1', 25, 26.5, 'opponent', '1'), at('d2', 39.5, 16.5, 'opponent', '2'), at('d3', 10.5, 16.5, 'opponent', '3'),
          at('d4', 37, 7.5, 'opponent', '4'), at('d5', 19.5, 10, 'opponent', '5'),
          at('ball', 27.2, 32.5, 'ball'),
          a('screen', 'block', path([16, 11], [22, 19], [28.5, 25.5])),
          a('drive', 'run', path([25, 31], [31, 30], [36, 24])),
        ],
      },
      {
        elements: [
          at('pg', 36, 24, 'team', 'PG'), at('sg', 43, 19, 'team', 'SG'), at('sf', 7, 19, 'team', 'SF'),
          at('pf', 41, 6, 'team', 'PF'), at('c', 28.5, 25.5, 'team', 'C'),
          at('d1', 31, 27.5, 'opponent', '1'), at('d2', 39.5, 16.5, 'opponent', '2'), at('d3', 10.5, 16.5, 'opponent', '3'),
          at('d4', 37, 7.5, 'opponent', '4'), at('d5', 32.5, 21, 'opponent', '5'),
          at('ball', 37.5, 25.3, 'ball'),
          a('roll', 'run', path([28.5, 25.5], [26, 18], [25, 11])),
          a('feed', 'pass', path([37.5, 25.3], [26.2, 12.2])),
        ],
      },
    ],
    createdBy: 'coach',
    createdAt: minutesAgo(60 * 24 * 3),
    updatedAt: minutesAgo(60 * 24 * 2),
  });

  await db.doc('config/app').set({
    allowUserGroupCreation: true,
    maxGroupsCreatedPerUserPerDay: 5,
    defaultStorageQuotaMb: 200,
    maxUploadMb: 10,
    maxImageMb: 10,
    supportEmail: 'support@getbattleplan.app',
  });

  console.log(`Seeded ${people.length} people, ${teams.length} teams, ${players.length} players.`);
  console.log('Sign in as coach@example.com (Thunder and Cyclone) or claire@example.com (all three teams); password "password".');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
