// The App Review demo team (SPEC §10): what a reviewer sees after signing in
// with the demo account. Plain data, so it's tested without Firebase
// (demo-data.test.ts); demo.ts writes it. Every ID starts with "demo-", so
// running it again replaces the same documents and never touches real ones.
// Dates are JS Dates; Firestore stores them as timestamps.

export const DEMO_UID_FALLBACK = 'demo-appreview';
export const DEMO_TEAM = 'demo-thunder';
export const DEMO_YOUTH_TEAM = 'demo-lightning';

/** One Firestore document to write. */
export interface DemoDoc {
  path: string;
  data: Record<string, unknown>;
}

/**
 * Sample teammates: profiles and memberships only, no sign-in accounts.
 * Common American names and TV characters, as in the emulator seed. The
 * IDs stay as they were, so running it again renames the same people
 * instead of leaving the old ones on the teams.
 */
export const DEMO_PEOPLE = [
  { uid: 'demo-jordan', name: 'Jim Halpert' },
  { uid: 'demo-sam', name: 'Andy Dwyer' },
  { uid: 'demo-maria', name: 'Claire Dunphy' },
  { uid: 'demo-priya', name: 'Rachel Green' },
] as const;

const SETTINGS = {
  membersCanCreateEvents: false,
  membersCanCreatePolls: true,
  membersCanUploadDocs: true,
  membersCanInvite: true,
  allowMaybe: true,
  defaultReminderOffsets: [1440],
};

const NOTIFICATION_PREFS = {
  messages: true,
  replies: true,
  mentions: true,
  polls: true,
  eventsNew: true,
  eventsChanged: true,
  reminders: true,
  documents: true,
};

/**
 * The demo account owns an adult team (so admin screens show, with a
 * player and a pending player to approve) and is a guardian on a youth
 * team (so a parent's per-player RSVPs show). One team type: both teams
 * have players (TEAM-1).
 */
export function demoDocs(demo: { uid: string; email: string }, now: Date): DemoDoc[] {
  const ago = (minutes: number) => new Date(now.getTime() - minutes * 60_000);
  const inDays = (days: number, hour: number) => {
    const d = new Date(now);
    d.setDate(d.getDate() + days);
    d.setHours(hour, 0, 0, 0);
    return d;
  };
  const month = ago(60 * 24 * 30);
  const docs: DemoDoc[] = [];
  const add = (path: string, data: Record<string, unknown>) => docs.push({ path, data });

  const profile = (uid: string, name: string, email: string | null) => ({
    displayName: name,
    displayNameLower: name.toLowerCase(),
    email,
    emailLower: email?.toLowerCase() ?? null,
    photoPath: null,
    status: 'active',
    signInMethods: email ? ['password'] : [],
    themeMode: 'system',
    notificationPrefs: NOTIFICATION_PREFS,
    acceptedTermsAt: month,
    adultConfirmedAt: month,
    lastActiveAt: ago(5),
    createdAt: month,
    updatedAt: month,
    schemaVersion: 1,
  });
  add(`users/${demo.uid}`, profile(demo.uid, 'App Review', demo.email));
  for (const p of DEMO_PEOPLE) add(`users/${p.uid}`, profile(p.uid, p.name, null));

  const nameOf = (uid: string) =>
    uid === demo.uid ? 'App Review' : DEMO_PEOPLE.find((p) => p.uid === uid)!.name;

  // [team, uid, role, title, playerSummary]
  const memberships: [string, string, string, string | null, string | null][] = [
    [DEMO_TEAM, demo.uid, 'owner', 'Coach', null],
    [DEMO_TEAM, 'demo-jordan', 'admin', 'Assistant coach', null],
    [DEMO_TEAM, 'demo-sam', 'member', null, '#12'],
    [DEMO_TEAM, 'demo-maria', 'member', null, null],
    [DEMO_YOUTH_TEAM, 'demo-priya', 'owner', 'Coach', null],
    [DEMO_YOUTH_TEAM, demo.uid, 'member', null, 'Riley #9'],
    [DEMO_YOUTH_TEAM, 'demo-maria', 'member', null, 'Luke #7'],
  ];
  // Andy is a player on Thunder ('self'); Pam isn't claimed yet; Claire
  // asked to join Thunder's roster, waiting for the demo account to approve.
  const players: {
    id: string;
    groupId: string;
    name: string;
    number: string;
    position: string;
    link: { uid: string; relation: 'self' | 'guardian' } | null;
    pendingBy?: string;
  }[] = [
    { id: 'demo-riley', groupId: DEMO_YOUTH_TEAM, name: 'Riley Review', number: '9', position: 'Midfield', link: { uid: demo.uid, relation: 'guardian' } },
    { id: 'demo-emma', groupId: DEMO_YOUTH_TEAM, name: 'Luke Dunphy', number: '7', position: 'Forward', link: { uid: 'demo-maria', relation: 'guardian' } },
    { id: 'demo-sam-rivera', groupId: DEMO_TEAM, name: 'Andy Dwyer', number: '12', position: 'Shortstop', link: { uid: 'demo-sam', relation: 'self' } },
    { id: 'demo-casey', groupId: DEMO_TEAM, name: 'Pam Beesly', number: '5', position: 'Outfield', link: null },
    { id: 'demo-maria-rodriguez', groupId: DEMO_TEAM, name: 'Claire Dunphy', number: '', position: '', link: null, pendingBy: 'demo-maria' },
  ];
  const chats: Record<string, [string, string, number][]> = {
    [DEMO_TEAM]: [
      [demo.uid, 'Welcome to Battleplan! Practice is Tuesday at 6.', 300],
      ['demo-jordan', 'Field 3 is reserved. I will bring the extra bats.', 240],
      ['demo-sam', 'On my way!', 30],
    ],
    [DEMO_YOUTH_TEAM]: [
      ['demo-priya', 'Reminder: shin guards for everyone on Saturday.', 600],
      ['demo-maria', 'Luke will be there. Can someone carpool?', 120],
    ],
  };

  const teams = [
    { id: DEMO_TEAM, name: 'Thunder', sport: 'softball', color: '#1E3A5F' },
    { id: DEMO_YOUTH_TEAM, name: 'Cyclone', sport: 'soccer', color: '#7BAFD4' },
  ];
  for (const t of teams) {
    const members = memberships.filter((m) => m[0] === t.id);
    const owner = members.find((m) => m[2] === 'owner')![1];
    const last = chats[t.id][chats[t.id].length - 1];
    add(`groups/${t.id}`, {
      name: t.name,
      nameLower: t.name.toLowerCase(),
      description: 'A sample team for App Review.',
      photoPath: null,
      color: t.color,
      sport: t.sport,
      kind: 'team',
      ownerId: owner,
      createdBy: owner,
      timeZone: 'America/Chicago',
      settings: SETTINGS,
      memberCount: members.length,
      playerCount: players.filter((p) => p.groupId === t.id && !p.pendingBy).length,
      lastMessageAt: ago(last[2]),
      lastMessagePreview: { authorName: nameOf(last[0]), text: last[1], type: 'text' },
      storageBytes: 0,
      storageQuotaBytes: 200 * 1024 * 1024,
      storageAlert: 'none',
      createdAt: month,
      updatedAt: month,
      schemaVersion: 1,
    });
  }
  for (const [groupId, uid, role, title, playerSummary] of memberships) {
    add(`groupMembers/${groupId}_${uid}`, {
      groupId,
      uid,
      role,
      title,
      displayName: nameOf(uid),
      photoPath: null,
      playerSummary,
      notificationLevel: 'all',
      mutedUntil: null,
      lastReadAt: ago(90),
      lastPostedAt: null,
      joinedAt: month,
      addedBy: 'demo-seed',
    });
  }
  for (const p of players) {
    const owner = memberships.find((m) => m[0] === p.groupId && m[2] === 'owner')![1];
    add(`players/${p.id}`, {
      groupId: p.groupId,
      displayName: p.name,
      displayNameLower: p.name.toLowerCase(),
      jerseyNumber: p.number || null,
      position: p.position || null,
      status: p.pendingBy ? 'pending' : 'active',
      // A pending player is linked to its proposer on approval (PLAYER-4).
      ...(p.pendingBy
        ? { proposedBy: p.pendingBy, proposedRelation: 'self', decidedBy: null, decidedAt: null }
        : {}),
      createdBy: p.pendingBy ?? owner,
      createdAt: month,
      updatedAt: month,
    });
    if (p.link) {
      add(`playerGuardians/${p.id}_${p.link.uid}`, {
        playerId: p.id,
        groupId: p.groupId,
        uid: p.link.uid,
        relation: p.link.relation,
        addedBy: owner,
        via: p.link.relation === 'self' ? 'request' : 'admin',
        createdAt: month,
      });
    }
  }
  // Details for coaches (PLAYER-12), sample values only: the demo account
  // sees its child's as a guardian, and its own player's age as Thunder's
  // owner. No medical notes: the app keeps no health data.
  const year = now.getFullYear();
  add('playerDetails/demo-riley', {
    groupId: DEMO_YOUTH_TEAM,
    dateOfBirth: `${year - 10}-04-12`,
    emergencyContacts: [{ name: 'App Review', phone: '555-0100', relationship: 'Parent' }],
    notes: 'Wears glasses for games.',
    updatedBy: demo.uid,
    updatedAt: month,
  });
  add('playerDetails/demo-sam-rivera', {
    groupId: DEMO_TEAM,
    dateOfBirth: `${year - 27}-08-03`,
    emergencyContacts: [{ name: 'April Ludgate', phone: '555-0142', relationship: 'Partner' }],
    notes: null,
    updatedBy: 'demo-sam',
    updatedAt: month,
  });

  for (const [groupId, list] of Object.entries(chats)) {
    for (const [i, [uid, text, minutes]] of list.entries()) {
      const m = memberships.find((x) => x[0] === groupId && x[1] === uid)!;
      add(`messages/${groupId}-${i}`, {
        groupId,
        authorId: uid,
        authorName: nameOf(uid),
        authorPhotoPath: null,
        authorPlayerSummary: m[4],
        type: 'text',
        text,
        attachments: [],
        reactions: i === 0 ? { 'demo-sam': 'like' } : {},
        createdAt: ago(minutes),
      });
    }
  }

  const events = [
    { id: 'demo-thunder-practice', groupId: DEMO_TEAM, type: 'practice', title: 'Practice', day: 2, hour: 18 },
    { id: 'demo-thunder-game', groupId: DEMO_TEAM, type: 'game', title: 'vs. Eagles', day: 5, hour: 10, opponent: 'Eagles', homeAway: 'home' },
    { id: 'demo-lightning-practice', groupId: DEMO_YOUTH_TEAM, type: 'practice', title: 'Practice', day: 1, hour: 17 },
  ];
  // [event, type, participant, status, respondedBy]. Players count in
  // rsvpCounts, members answering for themselves in staffCounts (SCHED-5).
  const rsvps: [string, string, string, string, string][] = [
    ['demo-thunder-practice', 'member', 'demo-jordan', 'going', 'demo-jordan'],
    ['demo-thunder-practice', 'player', 'demo-sam-rivera', 'maybe', 'demo-sam'],
    ['demo-lightning-practice', 'player', 'demo-emma', 'going', 'demo-maria'],
    ['demo-lightning-practice', 'member', 'demo-priya', 'going', 'demo-priya'],
  ];
  const countsOf = (answers: typeof rsvps) => ({
    going: answers.filter((r) => r[3] === 'going').length,
    maybe: answers.filter((r) => r[3] === 'maybe').length,
    notGoing: answers.filter((r) => r[3] === 'not_going').length,
  });
  for (const e of events) {
    const startAt = inDays(e.day, e.hour);
    const answers = rsvps.filter((r) => r[0] === e.id);
    add(`events/${e.id}`, {
      groupId: e.groupId,
      type: e.type,
      title: e.title,
      description: '',
      location: { name: 'Riverside Park, Field 3', address: '100 River Rd' },
      allDay: false,
      startAt,
      endAt: new Date(startAt.getTime() + 90 * 60_000),
      timeZone: 'America/Chicago',
      opponent: e.opponent ?? null,
      homeAway: e.homeAway ?? null,
      rsvpEnabled: true,
      reminderOffsets: [1440],
      rsvpCounts: countsOf(answers.filter((r) => r[1] === 'player')),
      staffCounts: countsOf(answers.filter((r) => r[1] === 'member')),
      notifyTeam: false,
      postToChat: false,
      seriesId: null,
      canceledAt: null,
      canceledBy: null,
      createdBy: e.groupId === DEMO_TEAM ? demo.uid : 'demo-priya',
      createdAt: ago(60 * 24),
      updatedAt: ago(60 * 24),
      schemaVersion: 1,
    });
  }
  for (const [eventId, participantType, participantId, status, respondedBy] of rsvps) {
    const e = events.find((x) => x.id === eventId)!;
    add(`rsvps/${eventId}_${participantId}`, {
      eventId,
      groupId: e.groupId,
      participantType,
      participantId,
      participantName: participantType === 'player'
        ? players.find((p) => p.id === participantId)!.name
        : nameOf(participantId),
      eventStartAt: inDays(e.day, e.hour),
      status,
      note: '',
      guests: 0,
      respondedBy,
      updatedAt: ago(60),
    });
  }

  add(`groupDocuments/demo-thunder-rules`, {
    groupId: DEMO_TEAM,
    kind: 'link',
    name: 'League rules',
    nameLower: 'league rules',
    description: 'Rules and standings on the league site.',
    url: 'https://getbattleplan.app/',
    pinned: true,
    uploadedBy: demo.uid,
    uploaderName: 'App Review',
    notifyTeam: false,
    createdAt: ago(60 * 24 * 3),
    updatedAt: ago(60 * 24 * 3),
  });
  return docs;
}
