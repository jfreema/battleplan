// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(messageRepository)
final messageRepositoryProvider = MessageRepositoryProvider._();

/// Overridden in app/providers.dart.

final class MessageRepositoryProvider
    extends
        $FunctionalProvider<
          MessageRepository,
          MessageRepository,
          MessageRepository
        >
    with $Provider<MessageRepository> {
  /// Overridden in app/providers.dart.
  MessageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageRepository create(Ref ref) {
    return messageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRepository>(value),
    );
  }
}

String _$messageRepositoryHash() => r'e8ec38e76707df4993060a741746e031e4e6be42';

/// Where the send queue is kept on the device (CHAT-4). In memory unless
/// app/providers.dart wires the stored one.

@ProviderFor(chatQueueStore)
final chatQueueStoreProvider = ChatQueueStoreProvider._();

/// Where the send queue is kept on the device (CHAT-4). In memory unless
/// app/providers.dart wires the stored one.

final class ChatQueueStoreProvider
    extends $FunctionalProvider<ChatQueueStore, ChatQueueStore, ChatQueueStore>
    with $Provider<ChatQueueStore> {
  /// Where the send queue is kept on the device (CHAT-4). In memory unless
  /// app/providers.dart wires the stored one.
  ChatQueueStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatQueueStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatQueueStoreHash();

  @$internal
  @override
  $ProviderElement<ChatQueueStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatQueueStore create(Ref ref) {
    return chatQueueStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatQueueStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatQueueStore>(value),
    );
  }
}

String _$chatQueueStoreHash() => r'51e07b24d2eaf254bea5b403006d8f3e266cd263';

/// A team's unread message count for the switcher and the Chat tab, up to
/// 100 (CHAT-9). It only queries when the team's last message is newer
/// than the person's read marker, so a read team costs nothing.

@ProviderFor(unreadCount)
final unreadCountProvider = UnreadCountFamily._();

/// A team's unread message count for the switcher and the Chat tab, up to
/// 100 (CHAT-9). It only queries when the team's last message is newer
/// than the person's read marker, so a read team costs nothing.

final class UnreadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// A team's unread message count for the switcher and the Chat tab, up to
  /// 100 (CHAT-9). It only queries when the team's last message is newer
  /// than the person's read marker, so a read team costs nothing.
  UnreadCountProvider._({
    required UnreadCountFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'unreadCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unreadCountHash();

  @override
  String toString() {
    return r'unreadCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as GroupId;
    return unreadCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadCountHash() => r'126fba42fdffa16acf229832582ba1e894de69dd';

/// A team's unread message count for the switcher and the Chat tab, up to
/// 100 (CHAT-9). It only queries when the team's last message is newer
/// than the person's read marker, so a read team costs nothing.

final class UnreadCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, GroupId> {
  UnreadCountFamily._()
    : super(
        retry: null,
        name: r'unreadCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's unread message count for the switcher and the Chat tab, up to
  /// 100 (CHAT-9). It only queries when the team's last message is newer
  /// than the person's read marker, so a read team costs nothing.

  UnreadCountProvider call(GroupId groupId) =>
      UnreadCountProvider._(argument: groupId, from: this);

  @override
  String toString() => r'unreadCountProvider';
}

/// A URL to show a message photo.

@ProviderFor(attachmentUrl)
final attachmentUrlProvider = AttachmentUrlFamily._();

/// A URL to show a message photo.

final class AttachmentUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A URL to show a message photo.
  AttachmentUrlProvider._({
    required AttachmentUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attachmentUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attachmentUrlHash();

  @override
  String toString() {
    return r'attachmentUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return attachmentUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attachmentUrlHash() => r'4ae834260c1b0b8fa8f959ee8c02a8dbefe24bd7';

/// A URL to show a message photo.

final class AttachmentUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  AttachmentUrlFamily._()
    : super(
        retry: null,
        name: r'attachmentUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A URL to show a message photo.

  AttachmentUrlProvider call(String path) =>
      AttachmentUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'attachmentUrlProvider';
}

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.

@ProviderFor(ChatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.
final class ChatMessagesProvider
    extends $NotifierProvider<ChatMessages, ChatState> {
  /// One team's chat: the live newest page plus any older pages loaded by
  /// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
  /// of the live page as new ones arrive are kept, so no gap opens between
  /// the live page and the older ones.
  ChatMessagesProvider._({
    required ChatMessagesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'chatMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatMessages create() => ChatMessages();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'4d16fc113a8049235d27a2e84f8e3fc962f776e3';

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.

final class ChatMessagesFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatMessages,
          ChatState,
          ChatState,
          ChatState,
          GroupId
        > {
  ChatMessagesFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One team's chat: the live newest page plus any older pages loaded by
  /// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
  /// of the live page as new ones arrive are kept, so no gap opens between
  /// the live page and the older ones.

  ChatMessagesProvider call(GroupId groupId) =>
      ChatMessagesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

/// One team's chat: the live newest page plus any older pages loaded by
/// scrolling up, merged by message ID (ARCH §5.3). Messages that slide out
/// of the live page as new ones arrive are kept, so no gap opens between
/// the live page and the older ones.

abstract class _$ChatMessages extends $Notifier<ChatState> {
  late final _$args = ref.$arg as GroupId;
  GroupId get groupId => _$args;

  ChatState build(GroupId groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// A pinned message, live, for the bar at the top of the chat (CHAT-15).

@ProviderFor(pinnedMessage)
final pinnedMessageProvider = PinnedMessageFamily._();

/// A pinned message, live, for the bar at the top of the chat (CHAT-15).

final class PinnedMessageProvider
    extends
        $FunctionalProvider<AsyncValue<Message?>, Message?, Stream<Message?>>
    with $FutureModifier<Message?>, $StreamProvider<Message?> {
  /// A pinned message, live, for the bar at the top of the chat (CHAT-15).
  PinnedMessageProvider._({
    required PinnedMessageFamily super.from,
    required (GroupId, String) super.argument,
  }) : super(
         retry: null,
         name: r'pinnedMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pinnedMessageHash();

  @override
  String toString() {
    return r'pinnedMessageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Message?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Message?> create(Ref ref) {
    final argument = this.argument as (GroupId, String);
    return pinnedMessage(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedMessageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pinnedMessageHash() => r'e606988eacda71e8d28bbaf51d4ef76e9dbcd807';

/// A pinned message, live, for the bar at the top of the chat (CHAT-15).

final class PinnedMessageFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Message?>, (GroupId, String)> {
  PinnedMessageFamily._()
    : super(
        retry: null,
        name: r'pinnedMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A pinned message, live, for the bar at the top of the chat (CHAT-15).

  PinnedMessageProvider call(GroupId groupId, String messageId) =>
      PinnedMessageProvider._(argument: (groupId, messageId), from: this);

  @override
  String toString() => r'pinnedMessageProvider';
}

/// The team's pinned messages, newest pin first (CHAT-15).

@ProviderFor(pinnedMessageIds)
final pinnedMessageIdsProvider = PinnedMessageIdsFamily._();

/// The team's pinned messages, newest pin first (CHAT-15).

final class PinnedMessageIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// The team's pinned messages, newest pin first (CHAT-15).
  PinnedMessageIdsProvider._({
    required PinnedMessageIdsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'pinnedMessageIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pinnedMessageIdsHash();

  @override
  String toString() {
    return r'pinnedMessageIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as GroupId;
    return pinnedMessageIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedMessageIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pinnedMessageIdsHash() => r'f7b31153b34edb712c0116222f874617f000b775';

/// The team's pinned messages, newest pin first (CHAT-15).

final class PinnedMessageIdsFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, GroupId> {
  PinnedMessageIdsFamily._()
    : super(
        retry: null,
        name: r'pinnedMessageIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The team's pinned messages, newest pin first (CHAT-15).

  PinnedMessageIdsProvider call(GroupId groupId) =>
      PinnedMessageIdsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pinnedMessageIdsProvider';
}

/// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).

@ProviderFor(memberNames)
final memberNamesProvider = MemberNamesFamily._();

/// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).

final class MemberNamesProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).
  MemberNamesProvider._({
    required MemberNamesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'memberNamesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberNamesHash();

  @override
  String toString() {
    return r'memberNamesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    final argument = this.argument as GroupId;
    return memberNames(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberNamesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberNamesHash() => r'756491b6172439944284984d6da8897572e986ed';

/// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).

final class MemberNamesFamily extends $Family
    with $FunctionalFamilyOverride<Map<String, String>, GroupId> {
  MemberNamesFamily._()
    : super(
        retry: null,
        name: r'memberNamesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone's name on a team now, by ID, for showing @mentions (CHAT-14).

  MemberNamesProvider call(GroupId groupId) =>
      MemberNamesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'memberNamesProvider';
}

/// Who can be named with @ in a team's chat (CHAT-14): everyone on the
/// team but me, by name.

@ProviderFor(mentionCandidates)
final mentionCandidatesProvider = MentionCandidatesFamily._();

/// Who can be named with @ in a team's chat (CHAT-14): everyone on the
/// team but me, by name.

final class MentionCandidatesProvider
    extends
        $FunctionalProvider<
          List<MentionCandidate>,
          List<MentionCandidate>,
          List<MentionCandidate>
        >
    with $Provider<List<MentionCandidate>> {
  /// Who can be named with @ in a team's chat (CHAT-14): everyone on the
  /// team but me, by name.
  MentionCandidatesProvider._({
    required MentionCandidatesFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'mentionCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mentionCandidatesHash();

  @override
  String toString() {
    return r'mentionCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<MentionCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MentionCandidate> create(Ref ref) {
    final argument = this.argument as GroupId;
    return mentionCandidates(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MentionCandidate> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MentionCandidate>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MentionCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mentionCandidatesHash() => r'7c779a1a684d2d95c9c403d44be83a37a245e6a7';

/// Who can be named with @ in a team's chat (CHAT-14): everyone on the
/// team but me, by name.

final class MentionCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<List<MentionCandidate>, GroupId> {
  MentionCandidatesFamily._()
    : super(
        retry: null,
        name: r'mentionCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who can be named with @ in a team's chat (CHAT-14): everyone on the
  /// team but me, by name.

  MentionCandidatesProvider call(GroupId groupId) =>
      MentionCandidatesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'mentionCandidatesProvider';
}
