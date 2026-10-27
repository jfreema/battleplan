import 'dart:async';
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
    fromCache: q.metadata.isFromCache,
  );

  @override
  Future<MessagePage> loadNewer(
    GroupId groupId, {
    DateTime? after,
    PageCursor? cursor,
    int limit = 50,
  }) async {
    // Oldest first from the read marker (the groupId + createdAt ascending
    // index), then turned newest first like every other page.
    var q = _db
        .collection(Collections.messages)
        .where('groupId', isEqualTo: groupId.value)
        .orderBy('createdAt');
    if (cursor != null) {
      q = q.startAfterDocument(cursor.handle as DocumentSnapshot<Object?>);
    } else if (after != null) {
      q = q.where('createdAt', isGreaterThan: Timestamp.fromDate(after));
    }
    final s = await q.limit(limit).get();
    return MessagePage(
      messages: [for (final d in s.docs.reversed) _message(d, groupId)],
      next: s.docs.length < limit ? null : PageCursor(s.docs.last),
      // The descending query continues older from the oldest of them.
      older: s.docs.isEmpty ? null : PageCursor(s.docs.first),
      fromCache: s.metadata.isFromCache,
    );
  }

  @override
  Future<MessagePage> photoMessages(
    GroupId groupId, {
    PageCursor? before,
    int limit = 30,
  }) async {
    // The groupId + type + createdAt descending index.
    var q = _db
        .collection(Collections.messages)
        .where('groupId', isEqualTo: groupId.value)
        .where('type', isEqualTo: MessageType.image.value)
        .orderBy('createdAt', descending: true);
    if (before != null) {
      q = q.startAfterDocument(before.handle as DocumentSnapshot<Object?>);
    }
    return _page(await q.limit(limit).get(), groupId, limit);
  }

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
      eventId: x['eventId'] as String?,
      seriesId: x['seriesId'] as String?,
      reminder: x['reminder'] == true,
      replyPreview: switch (x['replyPreview']) {
        final Map<String, dynamic> p => ReplyPreview(
          authorName: p['authorName'] as String? ?? '',
          text: p['text'] as String? ?? '',
          type: MessageType.tryParse(p['type'] as String?) ?? MessageType.text,
          deleted: p['deleted'] == true,
        ),
        _ => null,
      },
      mentions: [
        for (final uid in (x['mentions'] as List?) ?? const [])
          if (uid is String) uid,
      ],
      mentionsEveryone: x['mentionsEveryone'] == true,
      announcement: x['announcement'] == true,
      playId: x['playId'] as String?,
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
      importedFrom: switch (x['imported']) {
        {'source': final String source} => source,
        _ => null,
      },
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
    List<String> mentions = const [],
    bool mentionsEveryone = false,
    bool announcement = false,
  }) => _post(
    groupId,
    uid,
    _db.collection(Collections.messages).doc(id),
    type: MessageType.text,
    text: text,
    replyToId: replyToId,
    extra: {
      // Only when set, as the rules allow them (CHAT-14, CHAT-15).
      if (mentions.isNotEmpty)
        'mentions': mentions.take(Limits.mentionsMax).toList(),
      if (mentionsEveryone) 'mentionsEveryone': true,
      if (announcement) 'announcement': true,
    },
  );

  @override
  Stream<Message?> watchMessage(GroupId groupId, String messageId) => _db
      .collection(Collections.messages)
      .doc(messageId)
      .snapshots()
      .map(
        (d) => d.exists && d.data()?['groupId'] == groupId.value
            ? _message(d, groupId)
            : null,
      )
      // A message I can no longer read (I left, the team was suspended)
      // reads as gone.
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) => error is FirebaseException
              ? sink.add(null)
              : sink.addError(error, stack),
        ),
      );

  @override
  Future<void> setPinned(String messageId, {required bool pinned}) async {
    try {
      await _functions.httpsCallable('pinMessage').call<Object?>({
        'messageId': messageId,
        'pinned': pinned,
      });
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch ((e.code, message)) {
        ('failed-precondition', final m?) => InvalidInput(m),
        ('permission-denied', _) => PermissionDenied(message),
        ('not-found', _) => NotFound(message),
        ('unavailable' || 'deadline-exceeded', _) => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
      };
    }
  }

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
    String? playId,
  }) => _post(
    groupId,
    uid,
    _db.collection(Collections.messages).doc(photos.messageId),
    type: MessageType.image,
    text: caption,
    replyToId: replyToId,
    extra: {'playId': ?playId},
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
  Future<void> sendPoll(
    GroupId groupId,
    UserId uid,
    NewPoll poll, {
    String? id,
  }) {
    final ref = _db.collection(Collections.messages).doc(id);
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
    Map<String, Object> extra = const {},
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
          ...extra,
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
    Set<String> skipAuthors = const {},
  }) async {
    final after = _db
        .collection(Collections.messages)
        .where('groupId', isEqualTo: groupId.value)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since));
    // People's messages only: system lines like "Sam joined" don't count.
    final counted = after.where('type', whereIn: countedTypes);
    var count = (await counted.limit(cap).count().get()).count ?? 0;
    // Nor do messages from people I blocked (CHAT-12), which are collapsed.
    // Rarely anyone, so usually no second read. `in` takes up to 30.
    final skip = skipAuthors.take(30).toList();
    if (count > 0 && skip.isNotEmpty) {
      // All of theirs, not just those among the first [cap]: a count
      // aggregation costs one read per 1,000 messages.
      final blocked =
          (await after.where('authorId', whereIn: skip).count().get()).count ??
          0;
      if (blocked > 0 && count >= cap) {
        // The first count stopped at the cap, so it holds an unknown share
        // of the blocked messages. Count again with room for all of them.
        count = (await counted.limit(cap + blocked).count().get()).count ?? 0;
      }
      count -= blocked;
    }
    return count.clamp(0, cap);
  }

  /// The message types an unread count includes (CHAT-9).
  static final List<String> countedTypes = [
    for (final t in MessageType.values)
      if (t != MessageType.system) t.value,
  ];

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _functions.httpsCallable('deleteMessage').call<Object?>({
        'messageId': messageId,
      });
    } on FirebaseFunctionsException catch (e) {
      final message = serverMessage(e.message);
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(message),
        'unavailable' || 'deadline-exceeded' => Offline(message),
        _ => UnknownFailure('${e.code}: $message'),
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
