// Data-layer tests (SPEC §8.1): team documents.
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/documents/data/firestore_document_repository.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

const _g = GroupId('g1');
const _me = UserId('alex');

FirebaseException _fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseStorage storage;
  late FirestoreDocumentRepository repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    storage = MockFirebaseStorage();
    repo = FirestoreDocumentRepository(db, storage);
    await db.doc('groupMembers/g1_alex').set({
      'groupId': 'g1',
      'uid': 'alex',
      'displayName': 'Alex Kim',
    });
  });

  test(
    'uploads a file into its own folder, then writes the document (DOC-1)',
    () async {
      final id = repo.newDocumentId();
      final upload = repo.uploadFile(
        _g,
        id,
        fileName: 'Fall/roster.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'application/pdf',
      );
      final path = await upload.done;
      expect(path, 'groups/g1/documents/${id.value}/Fall_roster.pdf');
      await upload.cancel();
      await repo.createFile(
        _g,
        id,
        _me,
        name: 'Fall Roster',
        description: 'Updated',
        path: path,
        contentType: 'application/pdf',
        size: 3,
        notifyTeam: false,
      );
      final d = (await db.doc('groupDocuments/${id.value}').get()).data()!;
      expect(d['kind'], 'file');
      expect(d['nameLower'], 'fall roster');
      expect(d['uploaderName'], 'Alex Kim');
      expect(d['pinned'], isFalse);
      expect(await repo.fileUrl(path), contains('Fall_roster.pdf'));
      expect(await repo.fileBytes(path), [1, 2, 3]);
      expect(await repo.fileUrl('missing'), isNull);
    },
  );

  test('adds a link, edits, pins, and deletes', () async {
    final id = await repo.createLink(
      _g,
      _me,
      name: 'League site',
      url: Uri.parse('https://example.com'),
      description: '',
      notifyTeam: true,
    );
    final doc = (await repo.watchDocument(id).first)!;
    expect(doc.kind, DocumentKind.link);
    expect(doc.url, 'https://example.com');
    await repo.update(doc, name: 'League', description: 'Standings');
    await repo.setPinned(doc, pinned: true);
    final pinned = await repo.watchPinned(_g).first;
    expect(pinned.single.name, 'League');
    expect(pinned.single.description, 'Standings');
    await repo.delete(doc);
    expect(await repo.watchDocument(id).first, isNull);
  });

  test('lists by recent or by name, a page at a time', () async {
    for (final (i, name) in ['Charlie', 'alpha', 'Bravo'].indexed) {
      await db.doc('groupDocuments/d$i').set({
        'groupId': 'g1',
        'kind': 'file',
        'name': name,
        'nameLower': name.toLowerCase(),
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, i + 1)),
      });
    }
    final recent = await repo
        .watchFirstPage(_g, DocumentSort.recent, limit: 2)
        .first;
    expect(recent.documents.map((d) => d.name), ['Bravo', 'alpha']);
    final rest = await repo.loadMore(
      _g,
      DocumentSort.recent,
      recent.next!,
      limit: 2,
    );
    expect(rest.documents.map((d) => d.name), ['Charlie']);
    expect(rest.next, isNull);
    final byName = await repo.watchFirstPage(_g, DocumentSort.name).first;
    expect(byName.documents.map((d) => d.name), ['alpha', 'Bravo', 'Charlie']);
  });

  test('maps refusals to failures', () async {
    final doc = documentFromFirestore('d1', const {'groupId': 'g1'});
    for (final (code, type) in [
      ('permission-denied', isA<PermissionDenied>()),
      ('unavailable', isA<Offline>()),
      ('canceled', isA<UploadCanceled>()),
      ('aborted', isA<UnknownFailure>()),
    ]) {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreDocumentRepository(db, storage);
      final ref = db.doc('groupDocuments/d1');
      whenCalling(Invocation.method(#delete, null))
          .on(ref)
          .thenThrow(_fs(code));
      whenCalling(Invocation.method(#update, null))
          .on(ref)
          .thenThrow(_fs(code));
      await expectLater(repo.delete(doc), throwsA(type));
      await expectLater(repo.setPinned(doc, pinned: true), throwsA(type));
    }
    final failing = FakeFirebaseFirestore();
    whenCalling(Invocation.method(#get, null))
        .on(failing.doc('groupMembers/g1_alex'))
        .thenThrow(_fs('permission-denied'));
    await expectLater(
      FirestoreDocumentRepository(failing, storage).createLink(
        _g,
        _me,
        name: 'x',
        url: Uri.parse('https://x.y'),
        description: '',
        notifyTeam: false,
      ),
      throwsA(isA<PermissionDenied>()),
    );
  });

  test('makes file names safe as one Storage path segment', () {
    expect(storageFileName(r'a/b\c#[x]*?.pdf'), 'a_b_c__x___.pdf');
    expect(storageFileName('  '), 'file');
    expect(storageFileName('..'), 'file');
    final long = storageFileName('${'n' * 120}.docx');
    expect(long.length, 100);
    expect(long, endsWith('.docx'));
  });

  test('reads a sparse or pending document with defaults', () {
    final d = documentFromFirestore('d', const {}, pending: true);
    expect(d.kind, DocumentKind.file);
    expect(d.createdAt, isNotNull);
    expect(documentFromFirestore('d', const {}).createdAt, isNull);
  });
}
