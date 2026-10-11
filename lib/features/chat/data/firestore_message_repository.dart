import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Messages in the flat `messages` collection, queried by groupId and
/// createdAt (ARCH §6.2).
class FirestoreMessageRepository implements MessageRepository {
  new(this._db);

  final FirebaseFirestore _db;

  Query<Map<String, dynamic>> _chat(GroupId groupId) => _db
      .collection(Collections.messages)
      .where('groupId', isEqualTo: groupId.value)
      .orderBy('createdAt', descending: true);

  @override
  Stream<MessagePage> watchNewest(GroupId groupId, {int limit = 50}) =>
      _chat(groupId)
          .limit(limit)
          .snapshots(includeMetadataChanges: true)
          .map((q) => _page(q, groupId, limit));

  @override
  Future<MessagePage> loadOlder(
    GroupId groupId,
    PageCursor before, {
    int limit = 50,
  }) async {
    final q = await _chat(groupId)
        .startAfterDocument(before.handle as DocumentSnapshot<Object?>)
        .limit(limit)
        .get();
    return _page(q, groupId, limit);
  }

  MessagePage _page(
    QuerySnapshot<Map<String, dynamic>> q,
    GroupId groupId,
    int limit,
  ) => MessagePage(
    messages: [for (final d in q.docs) _message(d, groupId)],
    next: q.docs.length < limit ? null : PageCursor(q.docs.last),
  );

  Message _message(DocumentSnapshot<Map<String, dynamic>> d, GroupId groupId) {
    final x = d.data()!;
    final created = x['createdAt'];
    final deleted = x['deletedAt'];
    return Message(
      id: d.id,
      groupId: groupId,
      authorId: x['authorId'] as String? ?? '',
      authorName: x['authorName'] as String? ?? '',
      authorPhotoPath: x['authorPhotoPath'] as String?,
      authorPlayerSummary: x['authorPlayerSummary'] as String?,
      type: MessageType.tryParse(x['type'] as String?) ?? MessageType.text,
      text: x['text'] as String? ?? '',
      replyToId: x['replyToId'] as String?,
      reactions: {
        for (final e in ((x['reactions'] as Map?) ?? const {}).entries)
          e.key as String: ?Reaction.tryParse(e.value as String?),
      },
      deletedAt: deleted is Timestamp ? deleted.toDate() : null,
      // A local write has no server time yet; estimate it so it sorts last.
      createdAt: created is Timestamp
          ? created.toDate()
          : (d.metadata.hasPendingWrites ? DateTime.now() : null),
      pending: d.metadata.hasPendingWrites,
    );
  }

  @override
  Future<void> sendText(GroupId groupId, UserId uid, String text) async {
    final memberRef = _db
        .collection(Collections.groupMembers)
        .doc(CompositeIds.groupMember(groupId, uid));
    final ref = _db.collection(Collections.messages).doc();
    try {
      // The author snapshot must equal the membership doc (rules check it).
      // The roster listener keeps it cached, so this works offline too.
      final member = await memberRef.get();
      final m = member.data() ?? const <String, dynamic>{};
      final batch = _db.batch()
        ..set(ref, {
          'groupId': groupId.value,
          'authorId': uid.value,
          'authorName': m['displayName'],
          'authorPhotoPath': m['photoPath'],
          'authorPlayerSummary': m['playerSummary'],
          'type': MessageType.text.value,
          'text': text,
          'attachments': const <Object>[],
          'createdAt': FieldValue.serverTimestamp(),
        })
        // The message rate limit (ARCH §6.3): the same batch stamps the
        // sender's lastPostedAt and names this message. Sending also marks
        // the chat read (CHAT-9).
        ..update(memberRef, {
          'lastPostedAt': FieldValue.serverTimestamp(),
          'lastPostedMessageId': ref.id,
          'lastReadAt': FieldValue.serverTimestamp(),
        });
      // The message shows at once from the local write; this completes when
      // the server has it, so the caller can space the next send from then.
      await batch.commit();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }
}
