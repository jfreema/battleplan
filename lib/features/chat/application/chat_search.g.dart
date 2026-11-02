// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A chat's search (CHAT-20), a page at a time, leaving out system lines and
/// messages from people I blocked (SAFE-2). Kept while the app runs, so
/// coming back to search from a result finds it as it was left.

@ProviderFor(ChatSearch)
final chatSearchProvider = ChatSearchFamily._();

/// A chat's search (CHAT-20), a page at a time, leaving out system lines and
/// messages from people I blocked (SAFE-2). Kept while the app runs, so
/// coming back to search from a result finds it as it was left.
final class ChatSearchProvider
    extends $NotifierProvider<ChatSearch, ChatSearchState> {
  /// A chat's search (CHAT-20), a page at a time, leaving out system lines and
  /// messages from people I blocked (SAFE-2). Kept while the app runs, so
  /// coming back to search from a result finds it as it was left.
  ChatSearchProvider._({
    required ChatSearchFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'chatSearchProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatSearchHash();

  @override
  String toString() {
    return r'chatSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatSearch create() => ChatSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatSearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSearchHash() => r'8db43c22a6ded2597e631e84846131164cc34c00';

/// A chat's search (CHAT-20), a page at a time, leaving out system lines and
/// messages from people I blocked (SAFE-2). Kept while the app runs, so
/// coming back to search from a result finds it as it was left.

final class ChatSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatSearch,
          ChatSearchState,
          ChatSearchState,
          ChatSearchState,
          GroupId
        > {
  ChatSearchFamily._()
    : super(
        retry: null,
        name: r'chatSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// A chat's search (CHAT-20), a page at a time, leaving out system lines and
  /// messages from people I blocked (SAFE-2). Kept while the app runs, so
  /// coming back to search from a result finds it as it was left.

  ChatSearchProvider call(GroupId groupId) =>
      ChatSearchProvider._(argument: groupId, from: this);

  @override
  String toString() => r'chatSearchProvider';
}

/// A chat's search (CHAT-20), a page at a time, leaving out system lines and
/// messages from people I blocked (SAFE-2). Kept while the app runs, so
/// coming back to search from a result finds it as it was left.

abstract class _$ChatSearch extends $Notifier<ChatSearchState> {
  late final _$args = ref.$arg as GroupId;
  GroupId get groupId => _$args;

  ChatSearchState build(GroupId groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChatSearchState, ChatSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatSearchState, ChatSearchState>,
              ChatSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
