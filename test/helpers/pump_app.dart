import 'package:battleplan/app/app.dart';
import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/presentation/document_screen.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Pumps the whole app (router, theme, shell) on fake repositories.
Future<FakeLocalPrefs> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
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
  FakeSafetyRepository? safety,
  FakeMediaRepository? media,
  FakeDeviceRepository? devices,
  FakeNotificationRepository? notifications,
  FakeBrowserInfo browser = const FakeBrowserInfo(),
  FakeEventRepository? eventRepo,
  FakeRsvpRepository? rsvpRepo,
  FakeCalendarAdder? calendar,
  FakeDocumentRepository? documentRepo,
  FakeFileChooser? fileChooser,
  FakeSharer? sharer,
  FakeLinkOpener? linkOpener,
  Size size = const Size(400, 1600),
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
  final messages = (messageRepo ?? FakeMessageRepository())..polls = polls;
  final events = eventRepo ?? rsvpRepo?.events ?? FakeEventRepository();
  await tester.pumpWidget(
    ProviderScope(
      // A fresh app each call, so a test can pump twice (say, as an admin
      // and then as a member) without keeping the first one's providers.
      key: UniqueKey(),
      overrides: [
        appEnvProvider.overrideWithValue(
          const AppEnv(flavor: AppFlavor.dev, useEmulators: true),
        ),
        appVersionProvider.overrideWithValue('1.0.0'),
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
        groupRepositoryProvider.overrideWithValue(
          groupRepo ?? FakeGroupRepository(groups.cast()),
        ),
        memberRepositoryProvider.overrideWithValue(
          memberRepo ?? FakeMemberRepository(memberships.cast()),
        ),
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
        calendarAdderProvider.overrideWithValue(
          calendar ?? FakeCalendarAdder(),
        ),
        documentRepositoryProvider.overrideWithValue(
          documentRepo ?? FakeDocumentRepository(),
        ),
        fileChooserProvider.overrideWithValue(fileChooser ?? FakeFileChooser()),
        sharerProvider.overrideWithValue(sharer ?? FakeSharer()),
        linkOpenerProvider.overrideWithValue(linkOpener ?? FakeLinkOpener()),
        // PDFium doesn't run in tests; a stand-in names the file.
        pdfViewProvider.overrideWithValue(
          (bytes, name) => Text('PDF $name (${bytes.length} bytes)'),
        ),
      ],
      child: const BattleplanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return localPrefs;
}
