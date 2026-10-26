// The main screens on fake data, for the golden and accessibility tests
// (ARCH §9, SPEC §7.6). Dates are fixed rather than relative to today, so
// the screens draw the same every day: the chat is in 2025 (always shown
// with its year), the schedule in 2030 (still upcoming).
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
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

List<Membership> get sceneMembers => [
  testMembership('a', 'coach', role: MemberRole.owner, name: 'Coach Lee'),
  testMembership('a', 'alex', name: 'Alex Kim'),
  testMembership('a', 'sam', name: 'Sam Rivera'),
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
  sceneEvent('e2', day: 15, counts: const RsvpCounts(going: 9, maybe: 2)),
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

Rsvp _rsvp(String uid, String name, RsvpStatus status, {String note = ''}) =>
    Rsvp(
      eventId: const EventId('e1'),
      groupId: _team,
      participantType: ParticipantType.member,
      participantId: uid,
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
}) => Message(
  id: id,
  groupId: _team,
  authorId: author,
  authorName: name,
  type: type,
  text: text,
  attachments: attachments,
  reactions: reactions,
  pollId: pollId,
  eventId: eventId,
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

FakeLocalPrefs _prefs({required ThemePreference theme}) => FakeLocalPrefs()
  ..themePreference = theme
  // The notification pre-prompt is its own screen, not these.
  ..pushPrePromptShown = true;

/// The sign-in screen, signed out, as people see it in prod: Google only
/// until Apple is on (AUTH-1).
Future<void> pumpSignIn(
  WidgetTester tester, {
  required ThemePreference theme,
}) async {
  await pumpApp(
    tester,
    auth: FakeAuthRepository(),
    env: const AppEnv(flavor: AppFlavor.prod, useEmulators: false),
    prefs: _prefs(theme: theme),
    size: phoneSize,
  );
}

/// The team's app on fake data, opened on the chat.
Future<void> pumpTeam(
  WidgetTester tester, {
  required ThemePreference theme,
  AuthUser user = coach,
  Size size = phoneSize,
  FakeMessageRepository? messages,
  int? teamColor,
}) async {
  final events = FakeEventRepository(sceneEvents);
  final rsvps = FakeRsvpRepository(events)
    ..rsvps.addAll([
      _rsvp('coach', 'Coach Lee', RsvpStatus.going),
      _rsvp('alex', 'Alex Kim', RsvpStatus.going, note: 'Bringing snacks'),
      _rsvp('sam', 'Sam Rivera', RsvpStatus.maybe),
      _rsvp('jo', 'Jo Park', RsvpStatus.notGoing),
    ]);
  final polls = FakePollRepository()
    ..put(scenePoll)
    ..votes['m2'] = {
      'coach': {'0'},
    };
  await pumpApp(
    tester,
    auth: FakeAuthRepository(user: user),
    prefs: _prefs(theme: theme),
    groups: {
      'a': teamColor == null ? sceneTeam : sceneTeam.copyWith(color: teamColor),
    },
    memberships: [
      ...sceneMembers,
      if (user.uid != 'coach') testMembership('a', user.uid),
    ],
    // The account's theme wins over this device's once the profile loads.
    users: FakeUserRepository()..themeMode = theme,
    messageRepo: messages ?? FakeMessageRepository(sceneMessages),
    pollRepo: polls,
    eventRepo: events,
    rsvpRepo: rsvps,
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

Future<void> pumpChat(WidgetTester tester, {required ThemePreference theme}) =>
    pumpTeam(tester, theme: theme);

Future<void> pumpSchedule(
  WidgetTester tester, {
  required ThemePreference theme,
}) async {
  await pumpTeam(tester, theme: theme);
  await tester.tap(find.text('Schedule'));
  await tester.pumpAndSettle();
}

Future<void> pumpEventDetails(
  WidgetTester tester, {
  required ThemePreference theme,
}) async {
  await pumpSchedule(tester, theme: theme);
  await tester.tap(find.text('vs. Eagles').first);
  await tester.pumpAndSettle();
}

Future<void> pumpDocuments(
  WidgetTester tester, {
  required ThemePreference theme,
}) async {
  await pumpTeam(tester, theme: theme);
  await tester.tap(find.text('Documents'));
  await tester.pumpAndSettle();
}

Future<void> pumpAdminDashboard(
  WidgetTester tester, {
  required ThemePreference theme,
}) async {
  await pumpTeam(tester, theme: theme, user: boss);
  await goTo(tester, '/admin');
}

/// The main screens by name, for tests that go through them all.
final Map<
  String,
  Future<void> Function(WidgetTester, {required ThemePreference theme})
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

/// Every key screen with a golden in both themes (SPEC §7.4): the main
/// screens, and welcome, the team switcher, roster, settings, invite, and
/// the wide rail layout.
final Map<
  String,
  Future<void> Function(WidgetTester, {required ThemePreference theme})
>
goldenScreens = {
  ...mainScreens,
  'welcome': (tester, {required theme}) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    prefs: _prefs(theme: theme),
    users: FakeUserRepository()..themeMode = theme,
    size: phoneSize,
  ),
  'team_switcher': (tester, {required theme}) async {
    await pumpTeam(tester, theme: theme);
    await tester.tap(find.bySemanticsLabel('Switch team: Thunder U14'));
    await tester.pumpAndSettle();
  },
  'roster': (tester, {required theme}) async {
    await pumpTeam(tester, theme: theme);
    await goTo(tester, '/g/a/roster');
  },
  'settings': (tester, {required theme}) async {
    await pumpTeam(tester, theme: theme);
    await goTo(tester, '/settings');
  },
  'invite': (tester, {required theme}) async {
    await pumpTeam(tester, theme: theme);
    await goTo(tester, '/g/a/invite');
  },
  'chat_wide': (tester, {required theme}) =>
      pumpTeam(tester, theme: theme, size: wideSize),
  // A gray team color (Gray) tints the team gray (TEAM-1).
  'chat_gray': (tester, {required theme}) =>
      pumpTeam(tester, theme: theme, teamColor: 0xFF334155),
  // A warm team color (Orange): a warm charcoal in Dark, not brown, with
  // orange heading shadows.
  'chat_orange': (tester, {required theme}) =>
      pumpTeam(tester, theme: theme, teamColor: 0xFFC2410C),
  // Black: gray in Dark and Light, a black page with lifted shadows in Candy.
  'chat_black': (tester, {required theme}) =>
      pumpTeam(tester, theme: theme, teamColor: 0xFF111111),
};
