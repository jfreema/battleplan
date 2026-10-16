// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'direct_chats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Messages (CHAT-19): my conversations with messages, newest first, each
/// with its conversation, which names the other person and holds the
/// newest message. Conversations with people I blocked are left out: what
/// they send never reaches me (SAFE-2).

@ProviderFor(myDirectChats)
final myDirectChatsProvider = MyDirectChatsProvider._();

/// Messages (CHAT-19): my conversations with messages, newest first, each
/// with its conversation, which names the other person and holds the
/// newest message. Conversations with people I blocked are left out: what
/// they send never reaches me (SAFE-2).

final class MyDirectChatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DirectChat>>,
          AsyncValue<List<DirectChat>>,
          AsyncValue<List<DirectChat>>
        >
    with $Provider<AsyncValue<List<DirectChat>>> {
  /// Messages (CHAT-19): my conversations with messages, newest first, each
  /// with its conversation, which names the other person and holds the
  /// newest message. Conversations with people I blocked are left out: what
  /// they send never reaches me (SAFE-2).
  MyDirectChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myDirectChatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myDirectChatsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<DirectChat>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<DirectChat>> create(Ref ref) {
    return myDirectChats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<DirectChat>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<DirectChat>>>(value),
    );
  }
}

String _$myDirectChatsHash() => r'aba32ce0e906d1d3657975c1de66ec97d1d7f03e';

/// How many conversations have unread messages, for the Messages button
/// (CHAT-19): muted ones and people I blocked don't count. From my
/// memberships alone, so the header reads no conversations.

@ProviderFor(directUnreadCount)
final directUnreadCountProvider = DirectUnreadCountProvider._();

/// How many conversations have unread messages, for the Messages button
/// (CHAT-19): muted ones and people I blocked don't count. From my
/// memberships alone, so the header reads no conversations.

final class DirectUnreadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many conversations have unread messages, for the Messages button
  /// (CHAT-19): muted ones and people I blocked don't count. From my
  /// memberships alone, so the header reads no conversations.
  DirectUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directUnreadCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directUnreadCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return directUnreadCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$directUnreadCountHash() => r'a13ba04822fd3b4fdb401a5bc85cdd5861863362';

/// Everyone New message offers (CHAT-19), by name: the people on my teams
/// that the roster shows me (TEAM-3: on a team that keeps its people to its
/// admins, only its coaches, unless I'm one of the admins), who have
/// joined, other than me and people I blocked. Read from the rosters, which
/// the session keeps.

@ProviderFor(messageablePeople)
final messageablePeopleProvider = MessageablePeopleProvider._();

/// Everyone New message offers (CHAT-19), by name: the people on my teams
/// that the roster shows me (TEAM-3: on a team that keeps its people to its
/// admins, only its coaches, unless I'm one of the admins), who have
/// joined, other than me and people I blocked. Read from the rosters, which
/// the session keeps.

final class MessageablePeopleProvider
    extends
        $FunctionalProvider<
          List<MessageablePerson>,
          List<MessageablePerson>,
          List<MessageablePerson>
        >
    with $Provider<List<MessageablePerson>> {
  /// Everyone New message offers (CHAT-19), by name: the people on my teams
  /// that the roster shows me (TEAM-3: on a team that keeps its people to its
  /// admins, only its coaches, unless I'm one of the admins), who have
  /// joined, other than me and people I blocked. Read from the rosters, which
  /// the session keeps.
  MessageablePeopleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageablePeopleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageablePeopleHash();

  @$internal
  @override
  $ProviderElement<List<MessageablePerson>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MessageablePerson> create(Ref ref) {
    return messageablePeople(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MessageablePerson> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MessageablePerson>>(value),
    );
  }
}

String _$messageablePeopleHash() => r'f749a8ad8b9f9585f40c06511e0db3f4c81be7bf';
