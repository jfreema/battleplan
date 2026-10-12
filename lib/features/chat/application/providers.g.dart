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

String _$unreadCountHash() => r'474f962f21d1c941b931831089a896fc3c0dc240';

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

String _$chatMessagesHash() => r'3ef263383f984dde99b1c4c6239d30a3b4fdfccb';

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
