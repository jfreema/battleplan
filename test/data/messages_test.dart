// Data-layer tests (SPEC §8.1): the chat's messages.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/data/firestore_message_repository.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import '../helpers/fake_functions.dart';

const _g = GroupId('g1');
const _me = UserId('alex');

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late FakeFunctions functions;
  late MockFirebaseStorage storage;
  late FirestoreMessageRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    functions = FakeFunctions();
    storage = MockFirebaseStorage();
    repo = FirestoreMessageRepository(db, storage, functions);
    await db.doc('groupMembers/g1_alex').set({
      'groupId': 'g1',
      'uid': 'alex',
      'displayName': 'Alex Kim',
      'photoPath': null,
      'playerSummary': 'Emma #7',
    });
  });

  test(
    'sends text with the author snapshot and the rate-limit stamp (ARCH §6.3)',
    () async {
      final id = repo.newMessageId();
      await repo.sendText(_g, _me, 'Hi team', id: id, replyToId: 'm0');
      final m = (await db.doc('messages/$id').get()).data()!;
      expect(m['authorName'], 'Alex Kim');
      expect(m['authorPlayerSummary'], 'Emma #7');
      expect(m['type'], 'text');
      expect(m['replyToId'], 'm0');
      final member = (await db.doc('groupMembers/g1_alex').get()).data()!;
      expect(member['lastPostedMessageId'], id);
      expect(member['lastReadAt'], isNotNull);
    },
  );

  test('posts a poll and its message in one batch', () async {
    await repo.sendPoll(
      _g,
      _me,
      NewPoll(
        question: ' Pizza? ',
        options: const ['Yes', ' ', 'No'],
        closesAt: DateTime.utc(2026, 10, 30),
      ),
      id: 'p1',
    );
    final message = (await db.doc('messages/p1').get()).data()!;
    expect(message['type'], 'poll');
    expect(message['text'], 'Pizza?');
    expect(message['pollId'], 'p1');
    final poll = (await db.doc('polls/p1').get()).data()!;
    expect(poll['options'], [
      {'id': '0', 'text': 'Yes'},
      {'id': '1', 'text': 'No'},
    ]);
    expect(poll['closesAt'], isA<Timestamp>());
    await repo.sendPoll(
      _g,
      _me,
      const NewPoll(question: 'Q', options: ['a', 'b']),
      id: 'p2',
    );
    expect((await db.doc('polls/p2').get()).data()!['closesAt'], isNull);
  });

  test('posts uploaded photos as an image message', () async {
    await repo.sendPhotos(_g, _me, (
      messageId: 'm9',
      attachments: const [
        Attachment(
          path: 'groups/g1/messages/m9/0.jpg',
          width: 4,
          height: 3,
          size: 10,
        ),
      ],
    ), caption: 'Team photo');
    final m = (await db.doc('messages/m9').get()).data()!;
    expect(m['type'], 'image');
    expect((m['attachments'] as List).single, containsPair('width', 4));
  });

  test(
    'reads pages newest first, with replies, photos, and reactions',
    () async {
      for (var i = 0; i < 4; i++) {
        await db.doc('messages/m$i').set({
          'groupId': 'g1',
          'authorId': 'sam',
          'authorName': 'Sam',
          'type': i == 3 ? 'image' : 'text',
          'text': 'Message $i',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1, 12, i)),
          if (i == 3) ...{
            'replyToId': 'm1',
            'replyPreview': {
              'authorName': 'Sam',
              'text': 'Message 1',
              'type': 'text',
              'deleted': false,
            },
            'attachments': [
              {
                'path': 'groups/g1/messages/m3/0.jpg',
                'width': 4,
                'height': 3,
                'size': 9,
              },
              {'nope': true},
            ],
            'reactions': {'alex': 'love', 'sam': 'unknown'},
            'editedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 1, 13)),
          },
          if (i == 0) ...{
            'deletedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 2)),
            'deletedReason': 'author',
          },
        });
      }
      await db.doc('messages/other').set({
        'groupId': 'g2',
        'text': 'x',
        'createdAt': Timestamp.now(),
      });

      final page = await repo.watchNewest(_g, limit: 2).first;
      expect(page.messages.map((m) => m.id), ['m3', 'm2']);
      final m3 = page.messages.first;
      expect(m3.type, MessageType.image);
      expect(m3.replyPreview!.text, 'Message 1');
      expect(m3.attachments.single.contentType, 'image/jpeg');
      expect(m3.reactions, {'alex': Reaction.love});
      expect(m3.editedAt, isNotNull);
      expect(page.next, isNotNull);

      final older = await repo.loadOlder(_g, page.next!, limit: 2);
      expect(older.messages.map((m) => m.id), ['m1', 'm0']);
      expect(older.messages.last.deletedAt, isNotNull);
      expect(older.messages.last.deletedReason, 'author');

      expect(await repo.countUnread(_g, DateTime.utc(2026, 10, 1, 12, 1)), 2);
    },
  );

  test('edits, reacts, and deletes', () async {
    await db.doc('messages/m1').set({
      'groupId': 'g1',
      'text': 'Helo',
      'reactions': <String, String>{},
    });
    await repo.editText('m1', 'Hello');
    await repo.setReaction('m1', _me, Reaction.fire);
    var m = (await db.doc('messages/m1').get()).data()!;
    expect(m['text'], 'Hello');
    expect(m['editedAt'], isNotNull);
    expect((m['reactions'] as Map)['alex'], 'fire');
    await repo.setReaction('m1', _me, null);
    m = (await db.doc('messages/m1').get()).data()!;
    expect((m['reactions'] as Map).containsKey('alex'), isFalse);

    await repo.deleteMessage('m1');
    expect(functions.lastData('deleteMessage'), {'messageId': 'm1'});
    for (final (code, type) in [
      ('permission-denied', isA<PermissionDenied>()),
      ('unavailable', isA<Offline>()),
      ('internal', isA<UnknownFailure>()),
    ]) {
      functions.fail('deleteMessage', code);
      await expectLater(repo.deleteMessage('m1'), throwsA(type));
    }
  });

  test('maps write refusals to failures', () async {
    for (final (code, type) in [
      ('permission-denied', isA<PermissionDenied>()),
      ('aborted', isA<UnknownFailure>()),
    ]) {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreMessageRepository(db, storage, functions);
      final doc = db.doc('messages/m1');
      whenCalling(Invocation.method(#update, null))
          .on(doc)
          .thenThrow(_fs(code));
      await expectLater(repo.editText('m1', 'x'), throwsA(type));
      await expectLater(
        repo.setReaction('m1', _me, Reaction.like),
        throwsA(type),
      );
    }
    for (final (code, type) in [
      ('permission-denied', isA<PermissionDenied>()),
      ('unavailable', isA<Offline>()),
      ('aborted', isA<UnknownFailure>()),
    ]) {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreMessageRepository(db, storage, functions);
      whenCalling(Invocation.method(#get, null))
          .on(db.doc('groupMembers/g1_alex'))
          .thenThrow(_fs(code));
      await expectLater(repo.sendText(_g, _me, 'Hi'), throwsA(type));
    }
  });

  test('reads attachment URLs and bytes, or null when missing', () async {
    await storage
        .ref('groups/g1/messages/m1/0.jpg')
        .putData(
          Uint8List.fromList([1, 2]),
          SettableMetadata(contentType: 'image/jpeg'),
        );
    expect(
      await repo.attachmentUrl('groups/g1/messages/m1/0.jpg'),
      contains('m1'),
    );
    expect(await repo.attachmentBytes('groups/g1/messages/m1/0.jpg'), [1, 2]);
    expect(await repo.attachmentUrl('missing.jpg'), isNull);
  });
}
