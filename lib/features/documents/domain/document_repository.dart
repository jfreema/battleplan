import 'dart:typed_data';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/documents/domain/document.dart';

/// A page of documents and where the next one starts (ARCH §5.3).
typedef DocumentPage = ({List<Document> documents, PageCursor? next});

/// A file upload under way (DOC-2): its progress from 0 to 1, Cancel, and
/// the Storage path once it's done. A canceled upload completes [done]
/// with an UploadCanceled failure.
abstract interface class DocumentUpload {
  Stream<double> get progress;

  Future<String> get done;

  Future<void> cancel();
}

/// Owns `groupDocuments` and the team's document files in Storage (ARCH
/// §5.2). Documents are written directly under the rules; Functions
/// notify the team and delete a deleted document's file.
abstract interface class DocumentRepository {
  /// The team's first [limit] documents in [sort] order, live (DOC-1).
  Stream<DocumentPage> watchFirstPage(
    GroupId groupId,
    DocumentSort sort, {
    int limit,
  });

  /// The next page after [cursor], one-shot, in the same order.
  Future<DocumentPage> loadMore(
    GroupId groupId,
    DocumentSort sort,
    PageCursor cursor, {
    int limit,
  });

  /// The team's pinned documents, live, so they list first even when they
  /// are older than the first page.
  Stream<List<Document>> watchPinned(GroupId groupId);

  /// One document, live; null once it's deleted.
  Stream<Document?> watchDocument(DocumentId id);

  /// A new document ID, so the file can go in its folder first.
  DocumentId newDocumentId();

  /// Starts uploading a file to `groups/{g}/documents/{id}/{fileName}`.
  /// Storage rules refuse it when storage is full, it's too big, or the
  /// person may not upload.
  DocumentUpload uploadFile(
    GroupId groupId,
    DocumentId id, {
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  /// Writes the document for an uploaded file (DOC-2). The uploader's name
  /// is read from their membership, as the rules require.
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
  });

  /// Writes a link (DOC-3).
  Future<DocumentId> createLink(
    GroupId groupId,
    UserId uid, {
    required String name,
    required Uri url,
    required String description,
    required bool notifyTeam,
  });

  /// Renames it and sets its description (DOC-5).
  Future<void> update(
    Document doc, {
    required String name,
    required String description,
  });

  /// Pins or unpins it (admins, DOC-5).
  Future<void> setPinned(Document doc, {required bool pinned});

  /// Deletes it; Functions delete its file (DOC-5).
  Future<void> delete(Document doc);

  /// A download URL for a stored file, or null.
  Future<String?> fileUrl(String path);

  /// A stored file's bytes (at most 10 MB), or null.
  Future<Uint8List?> fileBytes(String path);
}
