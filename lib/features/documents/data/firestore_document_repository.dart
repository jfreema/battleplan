import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/bad_records.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/url_cache.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_repository.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Documents in Firestore and their files in Storage (ARCH §6.2, §6.11).
/// The file goes up first, into the document's own folder; then the
/// document is written under the rules. Functions notify the team
/// (`onDocumentCreated`) and delete a deleted document's file.
class FirestoreDocumentRepository implements DocumentRepository {
  new(this._db, this._storage, {BadRecords? badRecords})
    : _bad = badRecords ?? BadRecords();

  /// Leaves out a document that can't be read, and says so (#40).
  final BadRecords _bad;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _docs =>
      _db.collection(Collections.groupDocuments);

  /// The team's documents in [sort] order. Each order needs its index
  /// (groupId with createdAt descending, or with nameLower).
  Query<Map<String, dynamic>> _ordered(GroupId groupId, DocumentSort sort) {
    final team = _docs.where('groupId', isEqualTo: groupId.value);
    return switch (sort) {
      DocumentSort.recent => team.orderBy('createdAt', descending: true),
      DocumentSort.name => team.orderBy('nameLower'),
    };
  }

  // The cursor is the last record read, good or not, so a bad one at the
  // end of a page never stops Load more.
  DocumentPage _page(QuerySnapshot<Map<String, dynamic>> q, int limit) => (
    documents: [for (final d in q.docs) ?_readOrSkip(d)],
    next: q.docs.length < limit ? null : PageCursor(q.docs.last),
  );

  Document _read(DocumentSnapshot<Map<String, dynamic>> d) =>
      documentFromFirestore(
        d.id,
        d.data()!,
        pending: d.metadata.hasPendingWrites,
      );

  /// [d] in a list, or null, told, when it can't be read.
  Document? _readOrSkip(DocumentSnapshot<Map<String, dynamic>> d) =>
      _bad.read('document', d.id, () => _read(d));

  @override
  Stream<DocumentPage> watchFirstPage(
    GroupId groupId,
    DocumentSort sort, {
    int limit = Limits.queryLimitMax,
  }) => _ordered(
    groupId,
    sort,
  ).limit(limit).snapshots().map((q) => _page(q, limit));

  @override
  Future<DocumentPage> loadMore(
    GroupId groupId,
    DocumentSort sort,
    PageCursor cursor, {
    int limit = Limits.queryLimitMax,
  }) async {
    final last = cursor.handle as DocumentSnapshot<Object?>;
    try {
      final q = await _ordered(
        groupId,
        sort,
      ).startAfterDocument(last).limit(limit).get();
      return _page(q, limit);
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Stream<List<Document>> watchPinned(GroupId groupId) => _docs
      // Two equality filters need no composite index; a team pins a few.
      .where('groupId', isEqualTo: groupId.value)
      .where('pinned', isEqualTo: true)
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((q) => [for (final d in q.docs) ?_readOrSkip(d)]);

  @override
  Stream<Document?> watchDocument(DocumentId id) {
    final controller = StreamController<Document?>();
    final sub = _docs
        .doc(id.value)
        .snapshots()
        // Offline, a document that was never cached reads as missing; wait
        // for the server rather than call a live one deleted.
        .where((d) => d.exists || !d.metadata.isFromCache)
        .listen(
          (d) {
            if (!d.exists) return controller.add(null);
            // One that can't be read errors, told once, so its page says
            // so with Try again (#40).
            try {
              controller.add(_bad.readOne('document', d.id, () => _read(d)));
            } on Object catch (e, stack) {
              controller.addError(e, stack);
            }
          },
          // The rules can't check a missing document's team, so reading a
          // deleted one is refused: it's gone.
          onError: (Object e) =>
              e is FirebaseException && e.code == 'permission-denied'
              ? controller.add(null)
              : controller.addError(e),
        );
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  @override
  DocumentId newDocumentId() => DocumentId(_docs.doc().id);

  @override
  DocumentUpload uploadFile(
    GroupId groupId,
    DocumentId id, {
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) {
    final path =
        'groups/${groupId.value}/documents/${id.value}/${storageFileName(fileName)}';
    final task = _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: contentType));
    return _StorageUpload(task, path, bytes.length);
  }

  @override
  Future<void> createFile(
    GroupId groupId,
    DocumentId id,
    UserId uid, {
    required String name,
    required String description,
    required String path,
    required String contentType,
    required int size,
    required bool notifyTeam,
  }) => _create(groupId, _docs.doc(id.value), uid, {
    'kind': DocumentKind.file.value,
    'name': name,
    'description': description,
    'path': path,
    'contentType': contentType,
    'size': size,
    'notifyTeam': notifyTeam,
  });

  @override
  Future<DocumentId> createLink(
    GroupId groupId,
    UserId uid, {
    required String name,
    required Uri url,
    required String description,
    required bool notifyTeam,
  }) async {
    final ref = _docs.doc();
    await _create(groupId, ref, uid, {
      'kind': DocumentKind.link.value,
      'name': name,
      'description': description,
      'url': url.toString(),
      'notifyTeam': notifyTeam,
    });
    return DocumentId(ref.id);
  }

  Future<void> _create(
    GroupId groupId,
    DocumentReference<Map<String, dynamic>> ref,
    UserId uid,
    Map<String, Object?> fields,
  ) async {
    try {
      // The rules check uploaderName against the membership, like a
      // message's authorName.
      final member = await _db
          .collection(Collections.groupMembers)
          .doc(CompositeIds.groupMember(groupId, uid))
          .get();
      final name = fields['name']! as String;
      await ref.set({
        ...fields,
        'groupId': groupId.value,
        'nameLower': name.toLowerCase(),
        'pinned': false,
        'uploadedBy': uid.value,
        'uploaderName': member.data()?['displayName'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> update(
    Document doc, {
    required String name,
    required String description,
  }) => _update(doc, {
    'name': name,
    'nameLower': name.toLowerCase(),
    'description': description,
  });

  @override
  Future<void> setPinned(Document doc, {required bool pinned}) =>
      _update(doc, {'pinned': pinned});

  Future<void> _update(Document doc, Map<String, Object?> fields) async {
    try {
      await _docs.doc(doc.id.value).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> delete(Document doc) async {
    try {
      await _docs.doc(doc.id.value).delete();
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<String?> fileUrl(String path) => _urls.get(path, () async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException {
      return null;
    }
  });

  /// File links, kept for the run (ARCH §5.6).
  final _urls = UrlCache();

  @override
  Future<Uint8List?> fileBytes(String path) async {
    try {
      // getData's own cap is 10 MB, the largest file a team can upload.
      return await _storage.ref(path).getData();
    } on FirebaseException {
      return null;
    }
  }
}

AppFailure _failure(FirebaseException e) => switch (e.code) {
  'permission-denied' || 'unauthorized' => PermissionDenied(e.code),
  'unavailable' || 'retry-limit-exceeded' => Offline(e.code),
  'canceled' => UploadCanceled(e.code),
  _ => UnknownFailure(e.code),
};

/// A Storage upload behind [DocumentUpload].
class _StorageUpload implements DocumentUpload {
  new(this._task, this._path, this._size);

  final UploadTask _task;
  final String _path;
  final int _size;

  @override
  Stream<double> get progress => _task.snapshotEvents.map(
    (e) => _size == 0 ? 1 : (e.bytesTransferred / _size).clamp(0, 1),
  );

  @override
  Future<String> get done async {
    try {
      await _task;
      return _path;
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> cancel() async {
    await _task.cancel();
  }
}

/// Reads a `groupDocuments` document (ARCH §6.2). A local write has no
/// server time yet; [pending] estimates it so it sorts first.
Document documentFromFirestore(
  String id,
  Map<String, dynamic> x, {
  bool pending = false,
}) {
  final created = x['createdAt'];
  return Document(
    id: DocumentId(id),
    groupId: GroupId(x['groupId'] as String? ?? ''),
    kind: DocumentKind.tryParse(x['kind'] as String?) ?? DocumentKind.file,
    name: x['name'] as String? ?? '',
    description: x['description'] as String? ?? '',
    pinned: x['pinned'] == true,
    path: x['path'] as String?,
    contentType: x['contentType'] as String?,
    size: (x['size'] as num?)?.toInt(),
    url: x['url'] as String?,
    uploadedBy: x['uploadedBy'] as String? ?? '',
    uploaderName: x['uploaderName'] as String? ?? '',
    createdAt: created is Timestamp
        ? created.toDate()
        : (pending ? DateTime.now() : null),
    updatedAt: (x['updatedAt'] as Timestamp?)?.toDate(),
  );
}
