import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.freezed.dart';
part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
DocumentRepository documentRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// One document, live (DOC-4). Null once it's deleted.
@riverpod
Stream<Document?> document(Ref ref, DocumentId id) =>
    ref.watch(documentRepositoryProvider).watchDocument(id);

/// A download URL for a stored file: image thumbnails, and opening other
/// files in the phone's default app (DOC-4).
@riverpod
Future<String?> documentFileUrl(Ref ref, String path) =>
    ref.watch(documentRepositoryProvider).fileUrl(path);

/// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
/// Kept while the viewer is open.
@riverpod
Future<Uint8List?> documentFileBytes(Ref ref, String path) =>
    ref.watch(documentRepositoryProvider).fileBytes(path);

/// The Documents tab's sort and filter (DOC-1), kept while the app runs.
@freezed
abstract class DocumentsView with _$DocumentsView {
  const factory({
    @Default(DocumentSort.recent) DocumentSort sort,
    @Default('') String filter,
  }) = _DocumentsView;
}

@Riverpod(keepAlive: true)
class DocumentsViewOptions extends _$DocumentsViewOptions {
  @override
  DocumentsView build() => const DocumentsView();

  void setSort(DocumentSort sort) => state = state.copyWith(sort: sort);

  void setFilter(String filter) => state = state.copyWith(filter: filter);
}

/// The Documents tab's list (DOC-1).
@freezed
abstract class DocumentListState with _$DocumentListState {
  const factory({
    /// Pinned first, then in the chosen order, not yet filtered.
    @Default(<Document>[]) List<Document> documents,
    @Default(true) bool loading,
    @Default(false) bool loadingMore,

    /// True once there's nothing more to load.
    @Default(false) bool reachedEnd,
    @Default(false) bool failed,
  }) = _DocumentListState;
}

/// A team's documents in [sort] order: the first 100 live, then pages of
/// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
/// on their own so they list first even when they're older.
@riverpod
class TeamDocuments extends _$TeamDocuments {
  final Map<String, Document> _known = {};
  Map<String, Document> _pinned = {};
  Set<String> _liveIds = {};
  PageCursor? _liveCursor;
  PageCursor? _moreCursor;
  bool _loadedMore = false;

  /// Until the first page arrives the list is still loading.
  bool _arrived = false;

  @override
  DocumentListState build(GroupId groupId, DocumentSort sort) {
    final repo = ref.watch(documentRepositoryProvider);
    final sub = repo.watchFirstPage(groupId, sort).listen(
      (page) {
        final ids = {for (final d in page.documents) d.id.value};
        final gone = _liveIds.difference(ids);
        _liveIds = ids;
        _arrived = true;
        for (final d in page.documents) {
          _known[d.id.value] = d;
        }
        _liveCursor = page.next;
        if (_loadedMore) {
          // A deleted document leaves the live page, but so does one pushed
          // past its end by new ones; ask which.
          if (gone.isNotEmpty) unawaited(_recheck(gone));
        } else {
          gone.forEach(_known.remove);
        }
        _publish(
          reachedEnd: _loadedMore ? _moreCursor == null : page.next == null,
        );
      },
      onError: (Object _) =>
          state = state.copyWith(loading: false, failed: true),
    );
    final pinnedSub = repo.watchPinned(groupId).listen((docs) {
      // One unpinned and older than the loaded pages leaves until its
      // page loads.
      _pinned = {for (final d in docs) d.id.value: d};
      _publish();
    }, onError: (Object _) {});
    ref.onDispose(() {
      unawaited(sub.cancel());
      unawaited(pinnedSub.cancel());
    });
    return const DocumentListState();
  }

  /// Keeps documents that left the live page only if they still exist.
  Future<void> _recheck(Set<String> ids) async {
    final repo = ref.read(documentRepositoryProvider);
    for (final id in ids) {
      Document? now;
      try {
        now = await repo.watchDocument(DocumentId(id)).first;
      } on Object {
        continue;
      }
      if (!ref.mounted) return;
      if (_liveIds.contains(id)) continue;
      if (now == null) {
        _known.remove(id);
      } else {
        _known[id] = now;
      }
    }
    _publish();
  }

  void _publish({bool? loadingMore, bool? reachedEnd}) {
    // The pinned listener has the latest pinned state; the pages have
    // the rest. A document unpinned keeps its page's copy, unpinned.
    final all = <String, Document>{
      for (final e in _known.entries)
        e.key: e.value.pinned && !_pinned.containsKey(e.key)
            ? e.value.copyWith(pinned: false)
            : e.value,
      ..._pinned,
    };
    state = state.copyWith(
      documents: arrangeDocuments(all.values, sort: sort),
      loading: !_arrived,
      failed: false,
      loadingMore: loadingMore ?? state.loadingMore,
      reachedEnd: reachedEnd ?? state.reachedEnd,
    );
  }

  /// Loads the next 100.
  Future<void> loadMore() async {
    if (state.loadingMore || state.reachedEnd || state.loading) return;
    final cursor = _loadedMore ? _moreCursor : _liveCursor;
    if (cursor == null) {
      state = state.copyWith(reachedEnd: true);
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(documentRepositoryProvider)
          .loadMore(groupId, sort, cursor);
      for (final d in page.documents) {
        _known.putIfAbsent(d.id.value, () => d);
      }
      _loadedMore = true;
      _moreCursor = page.next;
      _publish(loadingMore: false, reachedEnd: page.next == null);
    } on Object {
      state = state.copyWith(loadingMore: false);
      rethrow;
    }
  }
}
