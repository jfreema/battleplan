// Photos: a preview and caption before sending (owner's go 2026-11-16,
// "do #22, then #26"; SPEC CHAT-3): picked, taken, pasted, or dropped
// photos wait in a tray above the message box, uploading meanwhile, each
// with an X, until Send posts them with the box's text as the caption.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/presentation/photo_tray.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final photo = (bytes: tinyPng, contentType: 'image/png');

  /// The coach in Thunder's chat, with [picker] and [drops].
  Future<FakeMessageRepository> open(
    WidgetTester tester, {
    FakePhotoPicker? picker,
    FakePhotoDrops? drops,
    FakeMessageRepository? repo,
    Size size = const Size(400, 900),
  }) async {
    final messages = repo ?? FakeMessageRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      messageRepo: messages,
      photoPicker: picker ?? FakePhotoPicker([photo, photo]),
      size: size,
      overrides: [
        if (drops != null) photoDropsProvider.overrideWithValue(drops),
      ],
    );
    return messages;
  }

  Future<void> pick(
    WidgetTester tester, {
    String item = 'Photo library',
  }) async {
    await tester.tap(find.byTooltip('Add photos or a poll'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('picked photos wait above the box, uploading, and nothing goes '
      'to the team until Send', (tester) async {
    final repo = await open(tester);
    await pick(tester);
    expect(find.byType(PhotoTrayStrip), findsOneWidget);
    expect(find.byTooltip('Remove photo 1'), findsOneWidget);
    expect(find.byTooltip('Remove photo 2'), findsOneWidget);
    expect(repo.photoBatches, isEmpty);
    // Already uploading, into one message's folder.
    expect(repo.preUploads, [
      'groups/a/messages/tray0/0.jpg',
      'groups/a/messages/tray0/1.jpg',
    ]);
    // The box's text is their caption, and Send works without one.
    expect(find.text('Add a caption…'), findsOneWidget);
    final sendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, AppIcons.send).first,
    );
    expect(sendButton.onPressed, isNotNull);
    await send(tester);
    expect(repo.photoBatches, [2]);
    expect(find.byType(PhotoTrayStrip), findsNothing);
    expect(find.text('Message Thunder…'), findsOneWidget);
  });

  testWidgets('an X takes a photo out; the caption goes with the rest', (
    tester,
  ) async {
    final repo = await open(tester);
    await pick(tester);
    await tester.tap(find.byTooltip('Remove photo 1'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove photo 2'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Game day!');
    await tester.pump();
    await send(tester);
    expect(repo.photoBatches, [1]);
    expect(find.text('Game day!'), findsOneWidget);

    // Taking the last one out leaves the box as it was.
    await pick(tester);
    await tester.tap(find.byTooltip('Remove photo 2'));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove photo 1'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoTrayStrip), findsNothing);
    expect(repo.photoBatches, [1]);
  });

  testWidgets('the camera and pasted or dropped photos wait there too', (
    tester,
  ) async {
    final drops = FakePhotoDrops();
    final repo = await open(
      tester,
      picker: FakePhotoPicker()..cameraPhoto = photo,
      drops: drops,
    );
    await pick(tester, item: 'Camera');
    expect(find.byTooltip('Remove photo 1'), findsOneWidget);
    drops.drop([photo, photo]);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove photo 3'), findsOneWidget);
    expect(repo.photoBatches, isEmpty);
    await send(tester);
    expect(repo.photoBatches, [3]);
  });

  int trayCount(WidgetTester tester) =>
      tester.widget<PhotoTrayStrip>(find.byType(PhotoTrayStrip)).photos.length;

  Future<void> toTrayEnd(WidgetTester tester) async {
    await tester.drag(find.byType(PhotoTrayStrip), const Offset(-1200, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('a message holds 10: the picker offers no more, and the add '
      'tile goes', (tester) async {
    await open(tester, picker: FakePhotoPicker(List.filled(12, photo)));
    await pick(tester);
    expect(trayCount(tester), 10);
    await toTrayEnd(tester);
    expect(find.byTooltip('Remove photo 10'), findsOneWidget);
    expect(find.byTooltip('Add more photos'), findsNothing);
  });

  testWidgets('the tray adds more from its own tile, up to 10; dropped '
      'photos past 10 say so', (tester) async {
    final drops = FakePhotoDrops();
    await open(
      tester,
      picker: FakePhotoPicker(List.filled(8, photo)),
      drops: drops,
    );
    await pick(tester);
    await toTrayEnd(tester);
    await tester.tap(find.byTooltip('Add more photos'));
    await tester.pumpAndSettle();
    expect(trayCount(tester), 10);
    drops.drop([photo]);
    await tester.pumpAndSettle();
    expect(find.text('A message holds up to 10 photos.'), findsOneWidget);
    expect(trayCount(tester), 10);
  });

  testWidgets('a ring shows while a photo uploads; Send posts once it is up', (
    tester,
  ) async {
    final repo = FakeMessageRepository()..holdUploads = Completer<void>();
    await open(tester, repo: repo, picker: FakePhotoPicker([photo]));
    await pick(tester);
    expect(
      find.descendant(
        of: find.byType(PhotoTrayStrip),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(repo.photoBatches, isEmpty);
    repo.releaseUploads();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(repo.photoBatches, [1]);
  });

  testWidgets('a photo whose upload failed is marked, and goes again on Send', (
    tester,
  ) async {
    final repo = FakeMessageRepository()..failUploads = 1;
    await open(tester, repo: repo, picker: FakePhotoPicker([photo]));
    await pick(tester);
    expect(find.bySemanticsLabel(RegExp('Not uploaded yet')), findsOneWidget);
    await send(tester);
    expect(repo.photoBatches, [1]);
    // Into the same message, under a new name.
    expect(repo.preUploads, ['groups/a/messages/tray0/0r.jpg']);
  });

  testWidgets('reads well: each photo named, 48 px targets, and 200% text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, size: const Size(390, 844));
    await pick(tester);
    expect(find.bySemanticsLabel('Photo 1 of 2'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
