// The main screens on fake data, for the golden and accessibility tests
// (ARCH §9, SPEC §7.6). Dates are fixed rather than relative to today, so
// the screens draw the same every day: the chat is in 2025 (always shown
// with its year), the schedule in 2030 (still upcoming).
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/teams_screen.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';
import 'pump_app.dart';

/// A phone: iPhone 14/15 in logical pixels.
const phoneSize = Size(390, 844);

const coach = AuthUser(
  uid: 'coach',
  email: 'coach@example.com',
  displayName: 'Coach Lee',
  emailVerified: true,
);

/// Alex, a parent: Mia's guardian, and in the guardian scene Ava's too.
const alex = AuthUser(
  uid: 'alex',
  email: 'alex@example.com',
  displayName: 'Alex Kim',
  emailVerified: true,
);

/// Sam, a parent: Leo's guardian.
const sam = AuthUser(
  uid: 'sam',
  email: 'sam@example.com',
  displayName: 'Sam Rivera',
  emailVerified: true,
);

const boss = AuthUser(
  uid: 'boss',
  email: 'boss@example.com',
  displayName: 'Bea Boss',
  emailVerified: true,
  isSuperAdmin: true,
);

const _team = GroupId('a');
const _zone = 'America/Chicago';

Group get sceneTeam => testGroup('a', 'Thunder U14').copyWith(
  color: 0xFF2F5BEA,
  memberCount: 14,
  storageQuotaBytes: 500 * bytesPerMb,
);

/// The scene's icon colors (SET-8): Alex and Sam picked theirs; the coach
/// and Jo show the hashed ones.
const Map<String, AvatarColor> sceneAvatarColors = {
  'alex': AvatarColor.tangerine,
  'sam': AvatarColor.mint,
};

List<Membership> get sceneMembers => [
  testMembership('a', 'coach', role: MemberRole.owner, name: 'Coach Lee'),
  testMembership(
    'a',
    'alex',
    name: 'Alex Kim',
  ).copyWith(avatarColor: sceneAvatarColors['alex']),
  testMembership(
    'a',
    'sam',
    name: 'Sam Rivera',
  ).copyWith(avatarColor: sceneAvatarColors['sam']),
  testMembership('a', 'jo', name: 'Jo Park'),
];

/// Local wall-clock times, so they read the same in any time zone.
DateTime _chatAt(int day, int hour, int minute) =>
    DateTime(2025, 3, day, hour, minute);

/// An event on a fixed date in the team's zone.
Event sceneEvent(
  String id, {
  required int day,
  int hour = 18,
  String title = 'Practice',
  EventType type = EventType.practice,
  RsvpCounts counts = const RsvpCounts(),
  String place = 'Riverside Park',
}) {
  final start = ZonedTime.instantOf(
    _zone,
    DateTime.utc(2030, 10, day),
    hour * 60,
  );
  return Event(
    id: EventId(id),
    groupId: _team,
    type: type,
    title: title,
    startAt: start,
    endAt: start.add(const Duration(minutes: 90)),
    timeZone: _zone,
    createdBy: 'coach',
    location: EventLocation(name: place, address: '100 River Rd'),
    rsvpCounts: counts,
    reminderOffsets: const [1440],
  );
}

List<Event> get sceneEvents => [
  sceneEvent(
    'e1',
    day: 14,
    title: 'vs. Eagles',
    type: EventType.game,
    counts: const RsvpCounts(going: 2, maybe: 1, notGoing: 1),
  ),
  sceneEvent('e2', day: 15, counts: const RsvpCounts(going: 3, maybe: 1)),
  sceneEvent(
    'e3',
    day: 15,
    hour: 20,
    title: 'Team dinner',
    type: EventType.social,
    place: "Rosa's Pizza",
  ),
  sceneEvent('e4', day: 18, title: 'Parents meeting', type: EventType.meeting),
];

/// The scene's dues (DUES-1, DUES-2): the uniform fee, Noah's paid in one
/// payment, Mia's marked paid before payments were recorded, Leo's $20 of
/// $45, and Ava's owed; and a tournament fee with a note for everyone who
/// owes it, Mia's paid, Ava's $10 of $30, and Leo's owed. And how to pay.
FakeDuesRepository sceneDues() {
  final repo = FakeDuesRepository()
    ..payments = const DuesPayments(
      venmo: '@thunder-u14',
      appleCash: '(555) 010-0144',
      note: "Put your player's name in the note.",
      updatedBy: 'coach',
    )
    ..dues.addAll(const [
      Due(
        id: 'd0',
        groupId: _team,
        title: 'Uniform fee',
        amountCents: 4500,
        dueOn: '2030-10-31',
      ),
      Due(
        id: 'd1',
        groupId: _team,
        title: 'Tournament fee',
        amountCents: 3000,
        dueOn: '2030-10-20',
        note: 'Fall classic entry.',
      ),
    ]);
  DuePayment pay(int cents, {String note = ''}) => DuePayment(
    id: 'pay-$cents-${note.length}',
    amountCents: cents,
    paidOn: '2026-11-02',
    by: 'coach',
    note: note,
  );
  final labels = {for (final p in scenePlayers) p.id.value: p.label};
  for (final (dueId, title, amount, dueOn, note, shares) in [
    (
      'd0',
      'Uniform fee',
      4500,
      '2030-10-31',
      '',
      [
        ('noah', DueStatus.paid, [pay(4500)]),
        // Marked paid before payments were recorded.
        ('mia', DueStatus.paid, null),
        ('leo', DueStatus.owed, [pay(2000, note: 'Venmo')]),
        ('ava', DueStatus.owed, null),
      ],
    ),
    (
      'd1',
      'Tournament fee',
      3000,
      '2030-10-20',
      'Fall classic entry.',
      [
        ('mia', DueStatus.paid, [pay(3000)]),
        ('leo', DueStatus.owed, null),
        ('ava', DueStatus.owed, [pay(1000, note: 'Cash')]),
      ],
    ),
  ]) {
    for (final (id, status, payments) in shares) {
      repo.charges.add(
        DueCharge(
          id: '${dueId}_$id',
          groupId: _team,
          dueId: dueId,
          title: title,
          amountCents: amount,
          dueOn: dueOn,
          note: note,
          participantType: ParticipantType.player,
          participantId: id,
          participantName: labels[id]!,
          status: status,
          payments: payments ?? const [],
          recordedCents: payments?.fold<int>(0, (a, p) => a + p.amountCents),
        ),
      );
    }
  }
  return repo;
}

/// What the parents see (DUES-2): the same dues; each family sees only
/// their own player's.
FakeDuesRepository sceneFamilyDues() => sceneDues();

/// The team's players (made up), each with one of the members as their
/// guardian; the coach answers for Noah.
List<Player> get scenePlayers => const [
  Player(
    id: PlayerId('noah'),
    groupId: _team,
    displayName: 'Noah Lee',
    jerseyNumber: '4',
  ),
  Player(
    id: PlayerId('mia'),
    groupId: _team,
    displayName: 'Mia Kim',
    jerseyNumber: '7',
  ),
  Player(
    id: PlayerId('leo'),
    groupId: _team,
    displayName: 'Leo Rivera',
    jerseyNumber: '9',
  ),
  Player(
    id: PlayerId('ava'),
    groupId: _team,
    displayName: 'Ava Park',
    jerseyNumber: '12',
  ),
];

List<GuardianLink> get sceneLinks => const [
  GuardianLink(
    playerId: PlayerId('noah'),
    groupId: _team,
    uid: UserId('coach'),
  ),
  GuardianLink(playerId: PlayerId('mia'), groupId: _team, uid: UserId('alex')),
  GuardianLink(playerId: PlayerId('leo'), groupId: _team, uid: UserId('sam')),
  GuardianLink(playerId: PlayerId('ava'), groupId: _team, uid: UserId('jo')),
];

/// A player's answer on the game: on a team, only players have answers
/// (PLAYER-6).
Rsvp _rsvp(String id, String name, RsvpStatus status, {String note = ''}) =>
    Rsvp(
      eventId: const EventId('e1'),
      groupId: _team,
      participantType: ParticipantType.player,
      participantId: id,
      participantName: name,
      status: status,
      note: note,
    );

Message _msg(
  String id,
  String author,
  String name,
  DateTime at, {
  String text = '',
  MessageType type = MessageType.text,
  List<Attachment> attachments = const [],
  Map<String, Reaction> reactions = const {},
  String? pollId,
  String? eventId,
  ReplyPreview? replyTo,
  String? replyToId,
}) => Message(
  id: id,
  groupId: _team,
  authorId: author,
  authorName: name,
  authorAvatarColor: sceneAvatarColors[author],
  type: type,
  text: text,
  attachments: attachments,
  reactions: reactions,
  pollId: pollId,
  eventId: eventId,
  replyToId: replyToId,
  replyPreview: replyTo,
  createdAt: at,
);

/// Newest first, as the repository returns them.
List<Message> get sceneMessages => [
  _msg(
    'm7',
    'coach',
    'Coach Lee',
    _chatAt(8, 9, 41),
    text: 'See everyone Monday!',
    // A reply of mine, its quote in my bubble (CHAT-13).
    replyToId: 'm3',
    replyTo: const ReplyPreview(
      authorName: 'Sam Rivera',
      text: 'Running 5 minutes late, save me a cone',
    ),
  ),
  _msg(
    'm6',
    'coach',
    'Coach Lee',
    _chatAt(8, 9, 40),
    type: MessageType.event,
    text: 'vs. Eagles',
    eventId: 'e1',
  ),
  _msg(
    'm5',
    'alex',
    'Alex Kim',
    _chatAt(8, 9, 12),
    text: 'Great hustle today',
    // Someone else's reply, its quote on the page.
    replyToId: 'm2',
    replyTo: const ReplyPreview(
      authorName: 'Coach Lee',
      text: 'Team dinner after the game?',
      type: MessageType.poll,
    ),
    reactions: const {
      'coach': Reaction.like,
      'sam': Reaction.like,
      'jo': Reaction.fire,
    },
  ),
  _msg(
    'm4',
    'alex',
    'Alex Kim',
    _chatAt(8, 9, 11),
    attachments: const [
      Attachment(path: 'groups/a/messages/m4/0.jpg', width: 800, height: 600),
      Attachment(path: 'groups/a/messages/m4/1.jpg', width: 800, height: 600),
      Attachment(path: 'groups/a/messages/m4/2.jpg', width: 800, height: 600),
    ],
  ),
  _msg(
    'm3',
    'sam',
    'Sam Rivera',
    _chatAt(8, 9, 5),
    text: 'Running 5 minutes late, save me a cone',
  ),
  _msg(
    'm2',
    'coach',
    'Coach Lee',
    _chatAt(7, 18, 0),
    type: MessageType.poll,
    text: 'Team dinner after the game?',
    pollId: 'm2',
  ),
  _msg(
    'm1',
    'system',
    '',
    _chatAt(7, 17, 0),
    type: MessageType.system,
    text: 'Jo Park joined',
  ),
];

Poll get scenePoll => const Poll(
  id: PollId('m2'),
  groupId: _team,
  createdBy: 'coach',
  question: 'Team dinner after the game?',
  options: [
    PollOption(id: '0', text: 'Pizza'),
    PollOption(id: '1', text: 'Tacos'),
    PollOption(id: '2', text: 'Home, thanks'),
  ],
  voteCounts: {'0': 5, '1': 3, '2': 1},
  voterCount: 9,
);

List<Document> get sceneDocuments => [
  Document(
    id: const DocumentId('d1'),
    groupId: _team,
    kind: DocumentKind.file,
    name: 'Fall schedule.pdf',
    uploadedBy: 'coach',
    uploaderName: 'Coach Lee',
    pinned: true,
    path: 'groups/a/docs/d1/Fall schedule.pdf',
    contentType: 'application/pdf',
    size: 245 * 1024,
    createdAt: DateTime(2025, 2, 3, 10),
  ),
  Document(
    id: const DocumentId('d2'),
    groupId: _team,
    kind: DocumentKind.link,
    name: 'League rules',
    uploadedBy: 'sam',
    uploaderName: 'Sam Rivera',
    url: 'https://example.com/rules',
    createdAt: DateTime(2025, 2, 5, 12),
  ),
  Document(
    id: const DocumentId('d3'),
    groupId: _team,
    kind: DocumentKind.file,
    name: 'Medical form.docx',
    uploadedBy: 'alex',
    uploaderName: 'Alex Kim',
    path: 'groups/a/docs/d3/Medical form.docx',
    contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    size: 38 * 1024,
    createdAt: DateTime(2025, 1, 20, 9),
  ),
];

FakeLocalPrefs _prefs({required TeamScheme scheme}) => FakeLocalPrefs()
  ..defaultSchemeValue = scheme
  // The notification pre-prompt is its own screen, not these.
  ..pushPrePromptShown = true;

/// The sign-in screen, signed out, as people see it in prod: Google only
/// until Apple is on (AUTH-1).
Future<void> pumpSignIn(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpApp(
    tester,
    auth: FakeAuthRepository(),
    env: const AppEnv(flavor: AppFlavor.prod, useEmulators: false),
    prefs: _prefs(scheme: scheme),
    size: phoneSize,
  );
}

/// The team's app on fake data, opened on the chat.
Future<void> pumpTeam(
  WidgetTester tester, {
  required TeamScheme scheme,
  AuthUser user = coach,
  Size size = phoneSize,
  FakeMessageRepository? messages,
  FakeAssignmentRepository? assignments,
  FakeDuesRepository? dues,
  List<GuardianLink>? links,
  FakeNotificationRepository? notifications,
}) async {
  final events = FakeEventRepository(sceneEvents);
  final rsvps = FakeRsvpRepository(events)
    ..rsvps.addAll([
      _rsvp('noah', 'Noah Lee', RsvpStatus.going),
      _rsvp('mia', 'Mia Kim', RsvpStatus.going, note: 'Bringing snacks'),
      _rsvp('leo', 'Leo Rivera', RsvpStatus.maybe),
      _rsvp('ava', 'Ava Park', RsvpStatus.notGoing),
    ]);
  final polls = FakePollRepository()
    ..put(scenePoll)
    ..votes['m2'] = {
      'coach': {'0'},
    };
  await pumpApp(
    tester,
    auth: FakeAuthRepository(user: user),
    prefs: _prefs(scheme: scheme),
    groups: {'a': sceneTeam},
    // My pick on the scene team is the same scheme (SET-2).
    memberships: [
      for (final m in sceneMembers)
        if (m.uid.value == user.uid) m.copyWith(colorScheme: scheme) else m,
      if (!sceneMembers.any((m) => m.uid.value == user.uid))
        testMembership('a', user.uid).copyWith(colorScheme: scheme),
    ],
    // The account's default wins over this device's once the profile loads.
    users: FakeUserRepository()..colorScheme = scheme,
    messageRepo: messages ?? FakeMessageRepository(sceneMessages),
    pollRepo: polls,
    eventRepo: events,
    rsvpRepo: rsvps,
    playerRepo: FakePlayerRepository(scenePlayers)
      ..links.addAll(links ?? sceneLinks),
    assignmentRepo: assignments,
    duesRepo: dues ?? sceneDues(),
    notifications: notifications,
    documentRepo: FakeDocumentRepository(sceneDocuments),
    admin: FakeAdminRepository(
      totalsValue: const AdminTotals(
        users: 1284,
        teams: 96,
        newTeams: 7,
        activeTeams: 61,
        messages: 18420,
        storageBytes: 18 * 1024 * bytesPerMb,
        openReports: 3,
      ),
    ),
    size: size,
  );
}

Future<void> goTo(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}

/// On Teams, scrolls down to its rows under Your schedule (SCHED-2): See
/// all, Join, Create, and the default color scheme, which the cards push
/// below a phone's fold, so a test that looks only at what's on screen
/// still sees them.
Future<void> scrollToTeamsRows(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Default color scheme'),
    200,
    // Teams' own list: a wide screen's rail scrolls too.
    scrollable: find
        .descendant(
          of: find.byType(TeamsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Pushes [path] over what's showing, as the app opens a pushed screen,
/// so its bar has the back row ("‹ Team settings", SPEC §5.4.1). [goTo]
/// alone leaves nothing to go back to, so no back row.
Future<void> pushTo(WidgetTester tester, String path) async {
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path),
  );
  await tester.pumpAndSettle();
}

/// A team screen opened from Team settings, as its row there opens it.
Future<void> pumpFromTeamSettings(
  WidgetTester tester, {
  required TeamScheme scheme,
  required String path,
}) async {
  await pumpTeam(tester, scheme: scheme);
  await goTo(tester, '/g/a/info');
  await pushTo(tester, path);
}

/// The Team tab (SPEC §5.3): the team's card with Invite and Dues, then
/// the roster.
Future<void> pumpTeamTab(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpTeam(tester, scheme: scheme);
  await openTeamTab(tester);
}

/// A team screen opened from the Team tab, as the card's Invite and Dues
/// open theirs.
Future<void> pumpFromTeamTab(
  WidgetTester tester, {
  required TeamScheme scheme,
  required String path,
}) async {
  await pumpTeamTab(tester, scheme: scheme);
  await pushTo(tester, path);
}

Future<void> pumpChat(WidgetTester tester, {required TeamScheme scheme}) =>
    pumpTeam(tester, scheme: scheme);

Future<void> pumpSchedule(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpTeam(tester, scheme: scheme);
  await tester.tap(find.text('Schedule'));
  await tester.pumpAndSettle();
}

Future<void> pumpEventDetails(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpSchedule(tester, scheme: scheme);
  await tester.tap(find.text('vs. Eagles').first);
  await tester.pumpAndSettle();
}

/// A basic group's schedule (TEAM-14): Thunder Parents, 9 members who
/// each answer for themselves, in the person's scheme.
Future<void> pumpGroupSchedule(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  const p = GroupId('p');
  final events = FakeEventRepository([
    sceneEvent(
      'g1',
      day: 16,
      hour: 19,
      title: 'Snack schedule meeting',
      type: EventType.meeting,
      place: 'Library',
    ).copyWith(groupId: p, staffCounts: const RsvpCounts(going: 4, maybe: 1)),
    sceneEvent(
      'g2',
      day: 19,
      title: 'Fall party',
      type: EventType.social,
      place: "Rosa's Pizza",
    ).copyWith(groupId: p, staffCounts: const RsvpCounts(going: 6)),
  ]);
  await pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    prefs: _prefs(scheme: scheme),
    groups: {
      'a': sceneTeam,
      'p': testGroup(
        'p',
        'Thunder Parents',
      ).copyWith(kind: GroupKind.group, color: 0xFF0F8A5F, memberCount: 9),
    },
    memberships: [
      for (final m in sceneMembers)
        if (m.uid.value == coach.uid) m.copyWith(colorScheme: scheme) else m,
      testMembership(
        'p',
        coach.uid,
        role: MemberRole.owner,
        name: 'Coach Lee',
      ).copyWith(colorScheme: scheme),
      testMembership('p', 'sam', name: 'Sam Rivera'),
    ],
    users: FakeUserRepository()..colorScheme = scheme,
    eventRepo: events,
    rsvpRepo: FakeRsvpRepository(events),
    size: phoneSize,
  );
  await goTo(tester, '/g/p/schedule');
}

Future<void> pumpDocuments(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpTeam(tester, scheme: scheme);
  await tester.tap(find.text('Documents'));
  await tester.pumpAndSettle();
}

Future<void> pumpAdminDashboard(
  WidgetTester tester, {
  required TeamScheme scheme,
}) async {
  await pumpTeam(tester, scheme: scheme, user: boss);
  await goTo(tester, '/admin');
}

/// The main screens by name, for tests that go through them all.
final Map<
  String,
  Future<void> Function(WidgetTester, {required TeamScheme scheme})
>
mainScreens = {
  'sign_in': pumpSignIn,
  'chat': pumpChat,
  'schedule': pumpSchedule,
  'event_details': pumpEventDetails,
  'documents': pumpDocuments,
  'admin_dashboard': pumpAdminDashboard,
};

/// A wide screen: a laptop browser window, for the rail layout (SPEC §5.5).
const wideSize = Size(1280, 800);

/// Every key screen with a golden in every color scheme (SPEC §7.4): the main
/// screens, and welcome, Teams (and its rows under Your schedule), Your
/// schedule, Profile, Team settings, the team switcher, the Team tab,
/// settings, invite, both Color scheme screens, a group's schedule, Dues (an
/// admin's, a due, Who owes what, and a member's and a guardian's own), Your
/// icon, and the wide rail layout.
final Map<
  String,
  Future<void> Function(WidgetTester, {required TeamScheme scheme})
>
goldenScreens = {
  ...mainScreens,
  'welcome': (tester, {required scheme}) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    prefs: _prefs(scheme: scheme),
    users: FakeUserRepository()..colorScheme = scheme,
    size: phoneSize,
  ),
  // The top (SPEC §5.1), and a team's settings (§5.2).
  'teams': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/teams');
  },
  // Teams scrolled to its rows, which Your schedule's cards (SCHED-2) push
  // below the fold: See all, Join, Create, and the default color scheme.
  'teams_rows': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/teams');
    await scrollToTeamsRows(tester);
  },
  // Your schedule's page, from See all on Teams (SCHED-2).
  'your_schedule': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/teams');
    await pushTo(tester, '/teams/schedule');
  },
  'profile': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/profile');
  },
  // From the chat's gear, with the chevron alone.
  'team_settings': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await pushTo(tester, '/g/a/info');
  },
  'team_switcher': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await tester.tap(find.bySemanticsLabel(RegExp('Switch team: Thunder U14')));
    await tester.pumpAndSettle();
  },
  'team_tab': pumpTeamTab,
  // From Profile.
  'settings': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/profile');
    await pushTo(tester, '/settings');
  },
  'invite': (tester, {required scheme}) =>
      pumpFromTeamTab(tester, scheme: scheme, path: '/g/a/invite'),
  'chat_wide': (tester, {required scheme}) =>
      pumpTeam(tester, scheme: scheme, size: wideSize),
  // Color scheme: how I see a team, and my default (SET-2).
  'color_scheme': (tester, {required scheme}) =>
      pumpFromTeamSettings(tester, scheme: scheme, path: '/g/a/scheme'),
  'color_scheme_default': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/teams/scheme');
  },
  'group_schedule': pumpGroupSchedule,
  'dues': (tester, {required scheme}) =>
      pumpFromTeamTab(tester, scheme: scheme, path: '/g/a/dues'),
  // One due's breakdown (DUES-2): who owes most first, each with what
  // they've paid and what's left.
  'dues_due': (tester, {required scheme}) async {
    await pumpFromTeamTab(tester, scheme: scheme, path: '/g/a/dues');
    await pushTo(tester, '/g/a/dues/d0');
  },
  // Who owes what (DUES-5): everyone across every due, by person.
  'dues_people': (tester, {required scheme}) async {
    await pumpFromTeamTab(tester, scheme: scheme, path: '/g/a/dues');
    await pushTo(tester, '/g/a/dues/people');
  },
  // What a parent sees (DUES-2, DUES-3): Leo's dues, and how to pay.
  'dues_member': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme, user: sam, dues: sceneFamilyDues());
    await goTo(tester, '/g/a/dues');
  },
  // A guardian of two players: each share says whose it is.
  'dues_guardian': (tester, {required scheme}) async {
    await pumpTeam(
      tester,
      scheme: scheme,
      user: alex,
      dues: sceneFamilyDues(),
      links: [
        ...sceneLinks,
        const GuardianLink(
          playerId: PlayerId('ava'),
          groupId: _team,
          uid: UserId('alex'),
        ),
      ],
    );
    await goTo(tester, '/g/a/dues');
  },
  'your_icon': (tester, {required scheme}) async {
    await pumpTeam(tester, scheme: scheme);
    await goTo(tester, '/profile/icon');
  },
};
