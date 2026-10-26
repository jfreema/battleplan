// The Photos gallery (SPEC DOC-7): every photo shared in the team's chat,
// opened from the Documents tab.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

void main() {
  final start = DateTime.utc(2026, 10, 1, 9);

  /// Photo message [i], [i] minutes after [start], with [photos] photos.
  Message photos(
    int i, {
    String author = 'sam',
    String name = 'Sam Rivera',
    int photos = 1,
    DateTime? deletedAt,
  }) => Message(
    id: 'm$i',
    groupId: const GroupId('a'),
    authorId: author,
    authorName: name,
    type: MessageType.image,
    createdAt: start.add(Duration(minutes: i)),
    deletedAt: deletedAt,
    attachments: [
      for (var k = 0; k < photos; k++)
        Attachment(path: 'groups/a/messages/m$i/$k.jpg'),
    ],
  );

  Future<void> openPhotos(
    WidgetTester tester,
    List<Message> messages, {
    FakeSafetyRepository? safety,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [
        testMembership('a', 'coach', name: 'Coach Lee'),
        testMembership('a', 'sam', name: 'Sam Rivera'),
      ],
      messageRepo: FakeMessageRepository(messages),
      safety: safety,
    );
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Every photo shared in the chat'), findsOneWidget);
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
  }

  testWidgets('every photo from the chat, newest first; a tap opens it full '
      'screen', (tester) async {
    await openPhotos(tester, [
      photos(3, photos: 2),
      Message(
        id: 't',
        groupId: const GroupId('a'),
        authorId: 'sam',
        authorName: 'Sam Rivera',
        type: MessageType.text,
        text: 'No photo here',
        createdAt: start.add(const Duration(minutes: 2)),
      ),
      photos(1, author: 'coach', name: 'Coach Lee'),
    ]);
    final shown = tester.widgetList<StoredPhoto>(find.byType(StoredPhoto));
    expect(
      [for (final p in shown) p.attachment.path],
      [
        'groups/a/messages/m3/0.jpg',
        'groups/a/messages/m3/1.jpg',
        'groups/a/messages/m1/0.jpg',
      ],
    );
    expect(find.bySemanticsLabel('Photo from Coach Lee'), findsOneWidget);
    await tester.tap(find.byType(StoredPhoto).last);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
    // It swipes through all three.
    expect(find.text('3 of 3'), findsOneWidget);
  });

  testWidgets('with none yet, it says where they come from', (tester) async {
    await openPhotos(tester, const []);
    expect(
      find.text('Photos shared in the chat will show up here.'),
      findsOneWidget,
    );
  });

  testWidgets('leaves out deleted messages and people I blocked (SAFE-2)', (
    tester,
  ) async {
    final safety = FakeSafetyRepository()
      ..blocks.add(const BlockedPerson(uid: UserId('sam'), name: 'Sam'));
    await openPhotos(tester, [
      photos(3),
      photos(2, author: 'coach', name: 'Coach Lee', deletedAt: start),
      photos(1, author: 'coach', name: 'Coach Lee'),
    ], safety: safety);
    final shown = tester.widgetList<StoredPhoto>(find.byType(StoredPhoto));
    expect(
      [for (final p in shown) p.attachment.path],
      ['groups/a/messages/m1/0.jpg'],
    );
  });

  testWidgets('more load as the grid nears its end', (tester) async {
    await openPhotos(tester, [for (var i = 40; i >= 1; i--) photos(i)]);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Photo from Sam Rivera').last,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
    // All 40, with nothing left to load.
    expect(delegate.childCount, 40);
  });
}
