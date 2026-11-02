import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/search_words.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_search.freezed.dart';
part 'chat_search.g.dart';

/// A chat's search (CHAT-20): what was searched, and the messages found.
@freezed
abstract class ChatSearchState with _$ChatSearchState {
  const factory({
    /// What was searched for, as typed.
    @Default('') String query,

    /// Its words, as messages keep theirs (searchWords): empty when it has
    /// none worth searching for, only short or everyday ones.
    @Default(<String>[]) List<String> terms,

    /// The messages found so far, newest first.
    @Default(<Message>[]) List<Message> results,
    @Default(false) bool loading,
    @Default(false) bool loadingMore,

    /// True once there are no more to find.
    @Default(false) bool reachedEnd,
    @Default(false) bool failed,

    /// The results came from the offline cache: only the messages on this
    /// device were searched.
    @Default(false) bool fromCache,
  }) = _ChatSearchState;

  const new _();

  /// Something was searched for, with words to find.
  bool get searched => terms.isNotEmpty;
}

/// A chat's search (CHAT-20), a page at a time, leaving out system lines and
/// messages from people I blocked (SAFE-2). Kept while the app runs, so
/// coming back to search from a result finds it as it was left.
@Riverpod(keepAlive: true)
class ChatSearch extends _$ChatSearch {
  PageCursor? _next;

  /// Counts searches, so one that answers after a newer one began is
  /// ignored.
  int _run = 0;

  /// The pages one call reads at most while finding nothing: the server
  /// finds the longest word, and the others are checked here.
  static const pagesPerLoad = 5;

  @override
  ChatSearchState build(GroupId groupId) => const ChatSearchState();

  /// Searches for [query]'s words.
  Future<void> search(String query) async {
    final run = ++_run;
    final terms = searchWords(query);
    _next = null;
    state = ChatSearchState(
      query: query.trim(),
      terms: terms,
      loading: terms.isNotEmpty,
    );
    if (terms.isNotEmpty) await _load(run);
  }

  /// The next page of results, unless one is loading or there are no more.
  Future<void> loadMore() async {
    if (!state.searched ||
        state.loading ||
        state.loadingMore ||
        state.reachedEnd) {
      return;
    }
    state = state.copyWith(loadingMore: true, failed: false);
    await _load(_run);
  }

  /// Back to nothing searched.
  void clear() {
    _run++;
    _next = null;
    state = const ChatSearchState();
  }

  Future<void> _load(int run) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      final blocked = ref.read(blockedIdsProvider);
      final found = <Message>[];
      var next = _next;
      var end = false;
      var fromCache = false;
      for (var i = 0; i < pagesPerLoad && found.isEmpty && !end; i++) {
        final page = await repository.searchMessages(
          groupId,
          state.terms,
          after: next,
        );
        if (!ref.mounted || run != _run) return;
        next = page.next;
        end = page.next == null;
        fromCache = fromCache || page.fromCache;
        found.addAll(
          page.messages.where(
            (m) => !m.isSystem && !blocked.contains(m.authorId),
          ),
        );
      }
      _next = next;
      state = state.copyWith(
        results: [...state.results, ...found],
        loading: false,
        loadingMore: false,
        reachedEnd: end,
        fromCache: state.fromCache || fromCache,
      );
    } on Object {
      if (!ref.mounted || run != _run) return;
      state = state.copyWith(loading: false, loadingMore: false, failed: true);
    }
  }
}
