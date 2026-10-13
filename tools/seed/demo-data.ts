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

/** Sample teammates: profiles and memberships only, no sign-in accounts. */
export const DEMO_PEOPLE = [
  { uid: 'demo-jordan', name: 'Jordan Lee' },
  { uid: 'demo-sam', name: 'Sam Rivera' },
  { uid: 'demo-maria', name: 'Maria Rodriguez' },
  { uid: 'demo-priya', name: 'Priya Shah' },
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
 * The demo account owns an adult team (so admin screens show) and is a
 * guardian on a youth team (so per-player RSVPs show).
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
    [DEMO_TEAM, 'demo-sam', 'member', null, null],
    [DEMO_TEAM, 'demo-maria', 'member', null, null],
    [DEMO_YOUTH_TEAM, 'demo-priya', 'owner', 'Coach', null],
    [DEMO_YOUTH_TEAM, demo.uid, 'member', null, 'Riley #9'],
    [DEMO_YOUTH_TEAM, 'demo-maria', 'member', null, 'Emma #7'],
  ];
  const players = [
    { id: 'demo-riley', groupId: DEMO_YOUTH_TEAM, name: 'Riley Review', number: '9', position: 'Midfield', guardian: demo.uid },
    { id: 'demo-emma', groupId: DEMO_YOUTH_TEAM, name: 'Emma Rodriguez', number: '7', position: 'Forward', guardian: 'demo-maria' },
  ];
  const chats: Record<string, [string, string, number][]> = {
    [DEMO_TEAM]: [
      [demo.uid, 'Welcome to Battleplan! Practice is Tuesday at 6.', 300],
      ['demo-jordan', 'Field 3 is reserved. I will bring the extra bats.', 240],
      ['demo-sam', 'On my way!', 30],
    ],
    [DEMO_YOUTH_TEAM]: [
      ['demo-priya', 'Reminder: shin guards for everyone on Saturday.', 600],
      ['demo-maria', 'Emma will be there. Can someone carpool?', 120],
    ],
  };

  const teams = [
    { id: DEMO_TEAM, name: 'Riverside Thunder', sport: 'softball', teamType: 'adult', color: '#2F5BEA' },
    { id: DEMO_YOUTH_TEAM, name: 'Lightning U10', sport: 'soccer', teamType: 'youth', color: '#0F8A5F' },
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
      teamType: t.teamType,
      ownerId: owner,
      createdBy: owner,
      timeZone: 'America/Chicago',
      settings: SETTINGS,
      memberCount: members.length,
      playerCount: players.filter((p) => p.groupId === t.id).length,
      lastMessageAt: ago(last[2]),
      lastMessagePreview: { authorName: nameOf(last[0]), text: last[1], type: 'text' },
      storageBytes: 0,
      storageQuotaBytes: 500 * 1024 * 1024,
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
    add(`players/${p.id}`, {
      groupId: p.groupId,
      displayName: p.name,
      displayNameLower: p.name.toLowerCase(),
      jerseyNumber: p.number,
      position: p.position,
      createdBy: 'demo-priya',
      createdAt: month,
      updatedAt: month,
    });
    add(`playerGuardians/${p.id}_${p.guardian}`, {
      playerId: p.id,
      groupId: p.groupId,
      uid: p.guardian,
      addedBy: 'demo-priya',
      via: 'admin',
      createdAt: month,
    });
  }
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
    { id: 'demo-thunder-practice', groupId: DEMO_TEAM, type: 'practice', title: 'Practice', day: 2, hour: 18, rsvpFor: 'members' },
    { id: 'demo-thunder-game', groupId: DEMO_TEAM, type: 'game', title: 'vs. Eagles', day: 5, hour: 10, rsvpFor: 'members', opponent: 'Eagles', homeAway: 'home' },
    { id: 'demo-lightning-practice', groupId: DEMO_YOUTH_TEAM, type: 'practice', title: 'Practice', day: 1, hour: 17, rsvpFor: 'players' },
  ];
  // [event, type, participant, status, respondedBy]
  const rsvps: [string, string, string, string, string][] = [
    ['demo-thunder-practice', 'member', 'demo-jordan', 'going', 'demo-jordan'],
    ['demo-thunder-practice', 'member', 'demo-sam', 'maybe', 'demo-sam'],
    ['demo-lightning-practice', 'player', 'demo-emma', 'going', 'demo-maria'],
  ];
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
      rsvpFor: e.rsvpFor,
      reminderOffsets: [1440],
      rsvpCounts: {
        going: answers.filter((r) => r[3] === 'going').length,
        maybe: answers.filter((r) => r[3] === 'maybe').length,
        notGoing: answers.filter((r) => r[3] === 'not_going').length,
      },
      staffCounts: { going: 0, maybe: 0, notGoing: 0 },
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
