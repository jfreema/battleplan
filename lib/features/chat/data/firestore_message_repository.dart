import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Messages in the flat `messages` collection, queried by groupId and
/// createdAt (ARCH §6.2).
class FirestoreMessageRepository implements MessageRepository {
  new(this._db, this._storage, this._functions);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

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
      pollId: x['pollId'] as String?,
      replyPreview: switch (x['replyPreview']) {
        final Map<String, dynamic> p => ReplyPreview(
          authorName: p['authorName'] as String? ?? '',
          text: p['text'] as String? ?? '',
          type: MessageType.tryParse(p['type'] as String?) ?? MessageType.text,
          deleted: p['deleted'] == true,
        ),
        _ => null,
      },
      attachments: [
        for (final a in (x['attachments'] as List?) ?? const [])
          if (a is Map && a['path'] is String)
            Attachment(
              path: a['path'] as String,
              contentType: a['contentType'] as String? ?? 'image/jpeg',
              width: (a['width'] as num?)?.toInt() ?? 0,
              height: (a['height'] as num?)?.toInt() ?? 0,
              size: (a['size'] as num?)?.toInt() ?? 0,
            ),
      ],
      reactions: {
        for (final e in ((x['reactions'] as Map?) ?? const {}).entries)
          e.key as String: ?Reaction.tryParse(e.value as String?),
      },
      deletedAt: deleted is Timestamp ? deleted.toDate() : null,
      deletedReason: x['deletedReason'] as String?,
      editedAt: (x['editedAt'] as Timestamp?)?.toDate(),
      // A local write has no server time yet; estimate it so it sorts last.
      createdAt: created is Timestamp
          ? created.toDate()
          : (d.metadata.hasPendingWrites ? DateTime.now() : null),
      pending: d.metadata.hasPendingWrites,
    );
  }

  @override
  String newMessageId() => _db.collection(Collections.messages).doc().id;

  @override
  Future<void> sendText(
    GroupId groupId,
    UserId uid,
    String text, {
    String? id,
    String? replyToId,
  }) => _post(
    groupId,
    uid,
    _db.collection(Collections.messages).doc(id),
    type: MessageType.text,
    text: text,
    replyToId: replyToId,
  );

  @override
  Future<UploadedPhotos> uploadPhotos(
    GroupId groupId,
    List<NewPhoto> photos, {
    void Function(double progress)? onProgress,
  }) async {
    final id = _db.collection(Collections.messages).doc().id;
    final total = photos.fold<int>(0, (n, p) => n + p.bytes.length);
    final sent = List<int>.filled(photos.length, 0);
    void report() => onProgress?.call(
      total == 0 ? 1 : sent.fold<int>(0, (a, b) => a + b) / total,
    );
    try {
      // Storage rules check membership, image type, size, and the quota.
      final attachments = await Future.wait([
        for (final (i, photo) in photos.indexed)
          () async {
            final path = 'groups/${groupId.value}/messages/$id/$i.jpg';
            final task = _storage
                .ref(path)
                .putData(
                  photo.bytes,
                  SettableMetadata(contentType: photo.contentType),
                );
            final progress = task.snapshotEvents.listen((e) {
              sent[i] = e.bytesTransferred;
              report();
            });
            await task;
            await progress.cancel();
            sent[i] = photo.bytes.length;
            report();
            final size = await _dimensions(photo.bytes);
            return Attachment(
              path: path,
              contentType: photo.contentType,
              width: size.width,
              height: size.height,
              size: photo.bytes.length,
            );
          }(),
      ]);
      return (messageId: id, attachments: attachments);
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' || 'permission-denied' => PermissionDenied(e.code),
        'retry-limit-exceeded' || 'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> sendPhotos(
    GroupId groupId,
    UserId uid,
    UploadedPhotos photos, {
    String caption = '',
    String? replyToId,
  }) => _post(
    groupId,
    uid,
    _db.collection(Collections.messages).doc(photos.messageId),
    type: MessageType.image,
    text: caption,
    replyToId: replyToId,
    attachments: [
      for (final a in photos.attachments)
        {
          'path': a.path,
          'contentType': a.contentType,
          'width': a.width,
          'height': a.height,
          'size': a.size,
        },
    ],
  );

  @override
  Future<void> sendPoll(GroupId groupId, UserId uid, NewPoll poll) {
    final ref = _db.collection(Collections.messages).doc();
    final p = poll.tidy;
    return _post(
      groupId,
      uid,
      ref,
      type: MessageType.poll,
      // The message's text is the question, so previews, quotes, and the
      // notification read it (the rules check they match).
      text: p.question,
      pollId: ref.id,
      // The poll is written in the same batch (ARCH §6.3).
      also: (batch) =>
          batch.set(_db.collection(Collections.polls).doc(ref.id), {
            'groupId': groupId.value,
            'messageId': ref.id,
            'createdBy': uid.value,
            'question': p.question,
            'options': [
              for (final (i, text) in p.options.indexed)
                {'id': '$i', 'text': text},
            ],
            'allowMultiple': p.allowMultiple,
            'anonymous': p.anonymous,
            'closesAt': p.closesAt == null
                ? null
                : Timestamp.fromDate(p.closesAt!),
            'closedAt': null,
            'voteCounts': <String, int>{},
            'voterCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          }),
    );
  }

  /// A photo's pixel size, read from its bytes.
  static Future<({int width, int height})> _dimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (width: frame.image.width, height: frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return size;
    } on Object {
      return (width: 0, height: 0);
    }
  }

  /// Writes a message and the sender's membership update in one batch.
  Future<void> _post(
    GroupId groupId,
    UserId uid,
    DocumentReference<Map<String, dynamic>> ref, {
    required MessageType type,
    required String text,
    List<Map<String, Object?>> attachments = const [],
    String? replyToId,
    String? pollId,
    void Function(WriteBatch batch)? also,
  }) async {
    final memberRef = _db
        .collection(Collections.groupMembers)
        .doc(CompositeIds.groupMember(groupId, uid));
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
          'type': type.value,
          'text': text,
          'attachments': attachments,
          'replyToId': ?replyToId,
          'pollId': ?pollId,
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
      also?.call(batch);
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

  @override
  Future<String?> attachmentUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<Uint8List?> attachmentBytes(String path) async {
    try {
      return await _storage.ref(path).getData(15 * 1024 * 1024);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<int> countUnread(
    GroupId groupId,
    DateTime since, {
    int cap = 100,
  }) async {
    final q = await _db
        .collection(Collections.messages)
        .where('groupId', isEqualTo: groupId.value)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .limit(cap)
        .count()
        .get();
    return q.count ?? 0;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _functions.httpsCallable('deleteMessage').call<Object?>({
        'messageId': messageId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }

  @override
  Future<void> editText(String messageId, String text) async {
    try {
      // Rules allow it for the author only (CHAT-15).
      await _db.collection(Collections.messages).doc(messageId).update({
        'text': text,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<void> setReaction(
    String messageId,
    UserId uid,
    Reaction? reaction,
  ) async {
    try {
      // Rules let a member change only their own key (CHAT-6, D6).
      await _db.collection(Collections.messages).doc(messageId).update({
        'reactions.${uid.value}': reaction?.value ?? FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }
}
