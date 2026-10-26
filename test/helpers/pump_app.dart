import 'package:battleplan/app/app.dart';
import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/presentation/document_screen.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/imports/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

/// Pumps the whole app (router, theme, shell) on fake repositories.
Future<FakeLocalPrefs> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  // Against the emulators unless a test says otherwise; dev and prod
  // builds offer only Google and Apple on the sign-in screen (AUTH-1).
  AppEnv env = const AppEnv(flavor: AppFlavor.dev, useEmulators: true),
  Map<String, dynamic> groups = const {},
  List<dynamic> memberships = const [],
  FakeLocalPrefs? prefs,
  FakeUserRepository? users,
  FakePushRepository? push,
  FakeGroupRepository? groupRepo,
  FakeMemberRepository? memberRepo,
  FakeInviteRepository? invites,
  FakePlayerRepository? playerRepo,
  FakeMessageRepository? messageRepo,
  FakePollRepository? pollRepo,
  FakePhotoPicker? photoPicker,
  FakePhotoDrops? photoDrops,
  FakeSafetyRepository? safety,
  FakeMediaRepository? media,
  FakeDeviceRepository? devices,
  FakeNotificationRepository? notifications,
  FakeBrowserInfo browser = const FakeBrowserInfo(),
  FakeEventRepository? eventRepo,
  FakeRsvpRepository? rsvpRepo,
  FakeAssignmentRepository? assignmentRepo,
  FakeCalendarLinkRepository? calendarLinks,
  FakeCalendarAdder? calendar,
  FakeDocumentRepository? documentRepo,
  FakeFileChooser? fileChooser,
  FakeSharer? sharer,
  FakeLinkOpener? linkOpener,
  FakeAdminRepository? admin,
  FakeImportRepository? importRepo,
  FakePlayRepository? playRepo,
  AppBuild build = const AppBuild(version: '1.0.0', number: '1', commit: ''),
  Size size = const Size(400, 1600),
  List<Override> overrides = const [],
}) async {
  // A tall phone-sized screen, so long settings lists fit without scrolling.
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final localPrefs = prefs ?? FakeLocalPrefs();
  // Posting a poll goes through the message repository, which puts it where
  // the poll repository reads it, as one batch does on the server.
  final polls = pollRepo ?? FakePollRepository();
  // Pinning a message lands on its team, as pinMessage writes it (CHAT-15).
  final teams = groupRepo ?? FakeGroupRepository(groups.cast());
  // Opening a conversation adds both people's memberships (CHAT-19).
  final members = memberRepo ?? FakeMemberRepository(memberships.cast());
  teams
    ..members ??= members
    ..me ??= () => auth.currentUser?.uid;
  final messages = (messageRepo ?? FakeMessageRepository())
    ..polls = polls
    ..groups ??= teams;
  final events = eventRepo ?? rsvpRepo?.events ?? FakeEventRepository();
  await tester.pumpWidget(
    ProviderScope(
      // A fresh app each call, so a test can pump twice (say, as an admin
      // and then as a member) without keeping the first one's providers.
      key: UniqueKey(),
      overrides: [
        appEnvProvider.overrideWithValue(env),
        appVersionProvider.overrideWithValue('1.0.0'),
        appBuildProvider.overrideWithValue(build),
        playRepositoryProvider.overrideWithValue(
          playRepo ?? FakePlayRepository(),
        ),
        importRepositoryProvider.overrideWithValue(
          importRepo ?? FakeImportRepository(),
        ),
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
        groupRepositoryProvider.overrideWithValue(teams),
        memberRepositoryProvider.overrideWithValue(members),
        localPrefsRepositoryProvider.overrideWithValue(localPrefs),
        playerRepositoryProvider.overrideWithValue(
          playerRepo ?? FakePlayerRepository(),
        ),
        mediaRepositoryProvider.overrideWithValue(
          media ?? FakeMediaRepository(),
        ),
        safetyRepositoryProvider.overrideWithValue(
          safety ?? FakeSafetyRepository(),
        ),
        photoPickerProvider.overrideWithValue(photoPicker ?? FakePhotoPicker()),
        if (photoDrops != null)
          photoDropsProvider.overrideWithValue(photoDrops),
        messageRepositoryProvider.overrideWithValue(messages),
        pollRepositoryProvider.overrideWithValue(polls),
        inviteRepositoryProvider.overrideWithValue(
          invites ?? FakeInviteRepository(),
        ),
        pushRepositoryProvider.overrideWithValue(push ?? FakePushRepository()),
        deviceRepositoryProvider.overrideWithValue(
          devices ?? FakeDeviceRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          notifications ?? FakeNotificationRepository(),
        ),
        deviceAppVersionProvider.overrideWithValue('1.0.0'),
        browserInfoProvider.overrideWithValue(browser),
        eventRepositoryProvider.overrideWithValue(events),
        rsvpRepositoryProvider.overrideWithValue(
          rsvpRepo ?? FakeRsvpRepository(events),
        ),
        assignmentRepositoryProvider.overrideWithValue(
          assignmentRepo ?? FakeAssignmentRepository(),
        ),
        calendarAdderProvider.overrideWithValue(
          calendar ?? FakeCalendarAdder(),
        ),
        calendarLinkRepositoryProvider.overrideWithValue(
          calendarLinks ?? FakeCalendarLinkRepository(),
        ),
        documentRepositoryProvider.overrideWithValue(
          documentRepo ?? FakeDocumentRepository(),
        ),
        fileChooserProvider.overrideWithValue(fileChooser ?? FakeFileChooser()),
        sharerProvider.overrideWithValue(sharer ?? FakeSharer()),
        linkOpenerProvider.overrideWithValue(linkOpener ?? FakeLinkOpener()),
        adminRepositoryProvider.overrideWithValue(
          admin ?? FakeAdminRepository(),
        ),
        // PDFium doesn't run in tests; a stand-in names the file.
        pdfViewProvider.overrideWithValue(
          (bytes, name) => Text('PDF $name (${bytes.length} bytes)'),
        ),
        ...overrides,
      ],
      child: const BattleplanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return localPrefs;
}

/// Opens email sign-in at `/emaillogin` (AUTH-2), which the sign-in screen
/// doesn't link to.
Future<void> openEmailSignIn(WidgetTester tester, {String query = ''}) async {
  GoRouter.of(tester.element(find.byType(Navigator).first))
      .go('/emaillogin$query');
  await tester.pumpAndSettle();
}
