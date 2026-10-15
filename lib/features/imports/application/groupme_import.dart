import 'dart:async';

import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/imports/domain/groupme_export.dart';

/// The steps of a GroupMe import, in the order they run.
enum GroupMeStep { events, documents, messages }

/// How far an import has got: `done` of `total` in `step`.
typedef GroupMeProgress = ({GroupMeStep step, int done, int total});

/// What a GroupMe import did (IMPORT-5), kind by kind.
final class GroupMeTotals {
  int eventsAdded = 0;
  int documentsAdded = 0;
  int documentsAlready = 0;
  int messagesAdded = 0;
  int messagesAlready = 0;

  /// Photos and files that didn't come along: too big, or no room.
  int photosLeftOut = 0;
  int documentsLeftOut = 0;

  /// True when it was stopped partway; what's done stays.
  bool canceled = false;

  /// True when the team's storage filled up partway (STORE-4).
  bool storageFull = false;
}

/// Messages per call. Each batch is checked first, so photos go up only for
/// messages that aren't already here (functions MESSAGES_PER_CALL is 500).
const groupMeMessageBatch = 250;

/// Documents per call (functions DOCUMENTS_PER_CALL).
const groupMeDocumentBatch = 50;

/// Runs a GroupMe import into a team (IMPORT-9): its events in one call,
/// then its files as documents, then its messages oldest first, in
/// batches. Photos and files are uploaded first, each to its item's own
/// folder, then the batch is written. Stopping between batches keeps what's
/// done; running again adds only what's new.
class GroupMeImporter {
  new(this._repo, this._groupId, this._export);

  final ImportRepository _repo;
  final GroupId _groupId;
  final GroupMeExport _export;
  bool _stop = false;

  static const ImportSource _source = ImportSource.groupme;

  /// Stops after the batch under way.
  void cancel() => _stop = true;

  Future<GroupMeTotals> run(
    GroupMeGroup group, {
    required bool messages,
    required bool photos,
    required bool documents,
    required bool events,
    required bool includePast,
    void Function(GroupMeProgress progress)? onProgress,
  }) async {
    final totals = GroupMeTotals();
    if (events && group.events.isNotEmpty && !_stop) {
      onProgress?.call((step: GroupMeStep.events, done: 0, total: 1));
      final r = await _repo.importEvents(
        _groupId,
        source: _source,
        includePast: includePast,
        dryRun: false,
        events: group.events,
      );
      totals.eventsAdded = r.added;
      onProgress?.call((step: GroupMeStep.events, done: 1, total: 1));
    }
    if (documents && group.files.isNotEmpty && !_stop) {
      await _documents(group, totals, onProgress);
    }
    if (messages && group.messages.isNotEmpty && !_stop) {
      await _messages(group, totals, onProgress, photos: photos);
    }
    totals.canceled = _stop;
    return totals;
  }

  Future<void> _documents(
    GroupMeGroup group,
    GroupMeTotals totals,
    void Function(GroupMeProgress progress)? onProgress,
  ) async {
    final files = group.files;
    var done = 0;
    for (var i = 0; i < files.length && !_stop; i += groupMeDocumentBatch) {
      final part = files.sublist(
        i,
        (i + groupMeDocumentBatch).clamp(0, files.length),
      );
      final docs = [for (final f in part) _document(f)];
      final check = await _repo.importDocuments(
        _groupId,
        source: _source,
        documents: docs,
        check: true,
      );
      final ready = <ChatImportDocument>[];
      for (final (j, f) in part.indexed) {
        if (check.existing.contains(f.id)) continue;
        if (totals.storageFull) {
          totals.documentsLeftOut++;
          continue;
        }
        final bytes = _export.bytesOf(f.entry);
        if (bytes == null) {
          totals.documentsLeftOut++;
          continue;
        }
        try {
          await _repo.upload(docs[j].path, bytes, f.contentType);
          ready.add(docs[j]);
        } on StorageFull {
          totals
            ..storageFull = true
            ..documentsLeftOut += 1;
        }
      }
      if (ready.isNotEmpty) {
        final r = await _repo.importDocuments(
          _groupId,
          source: _source,
          documents: ready,
        );
        totals
          ..documentsAdded += r.added
          ..documentsLeftOut += r.missing;
      }
      totals.documentsAlready += check.existing.length;
      done += part.length;
      onProgress?.call((
        step: GroupMeStep.documents,
        done: done,
        total: files.length,
      ));
    }
  }

  ChatImportDocument _document(GroupMeFile f) {
    final id = importedItemId(_groupId, _source, ImportItemKind.document, f.id);
    return ChatImportDocument(
      sourceId: f.id,
      name: f.name,
      path: 'groups/${_groupId.value}/documents/$id/${storageFileName(f.name)}',
      sharedByName: f.sharedByName,
      sharedAt: f.sharedAt,
    );
  }

  Future<void> _messages(
    GroupMeGroup group,
    GroupMeTotals totals,
    void Function(GroupMeProgress progress)? onProgress, {
    required bool photos,
  }) async {
    final all = group.messages;
    var done = 0;
    onProgress?.call((step: GroupMeStep.messages, done: 0, total: all.length));
    for (var i = 0; i < all.length && !_stop; i += groupMeMessageBatch) {
      final part = all.sublist(
        i,
        (i + groupMeMessageBatch).clamp(0, all.length),
      );
      final plain = [for (final m in part) _message(m, const [])];
      final check = await _repo.importMessages(
        _groupId,
        source: _source,
        messages: plain,
        check: true,
      );
      final batch = <ChatImportMessage>[];
      for (final (j, m) in part.indexed) {
        if (check.existing.contains(m.id)) continue;
        if (!photos || m.photos.isEmpty) {
          if (m.text.trim().isNotEmpty) batch.add(plain[j]);
          continue;
        }
        final uploaded = await _photos(m, totals);
        // A photo-only message whose photos all stayed behind has nothing
        // left to show.
        if (m.text.trim().isEmpty && uploaded.isEmpty) continue;
        batch.add(_message(m, uploaded));
      }
      if (batch.isNotEmpty) {
        final r = await _repo.importMessages(
          _groupId,
          source: _source,
          messages: batch,
        );
        totals
          ..messagesAdded += r.added
          ..photosLeftOut += r.missing;
      }
      totals.messagesAlready += check.existing.length;
      done += part.length;
      onProgress?.call((
        step: GroupMeStep.messages,
        done: done,
        total: all.length,
      ));
    }
  }

  /// Uploads [m]'s photos to its folder; the ones that went up.
  Future<List<ChatImportPhoto>> _photos(
    GroupMeMessage m,
    GroupMeTotals totals,
  ) async {
    final id = importedItemId(_groupId, _source, ImportItemKind.message, m.id);
    final out = <ChatImportPhoto>[];
    for (final (n, p) in m.photos.indexed) {
      final bytes = totals.storageFull ? null : _export.bytesOf(p.entry);
      if (bytes == null) {
        totals.photosLeftOut++;
        continue;
      }
      final path = 'groups/${_groupId.value}/messages/$id/$n.${p.extension}';
      try {
        await _repo.upload(path, bytes, p.contentType);
        final size = await _repo.imageSize(bytes);
        out.add(
          ChatImportPhoto(path: path, width: size.width, height: size.height),
        );
      } on StorageFull {
        totals
          ..storageFull = true
          ..photosLeftOut += 1;
      }
    }
    return out;
  }

  ChatImportMessage _message(GroupMeMessage m, List<ChatImportPhoto> photos) =>
      ChatImportMessage(
        sourceId: m.id,
        authorSourceId: m.authorId,
        authorName: m.authorName,
        text: m.text,
        createdAt: m.createdAt,
        replyToSourceId: m.replyToId,
        photos: photos,
      );
}
