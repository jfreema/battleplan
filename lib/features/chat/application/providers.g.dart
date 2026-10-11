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

String _$chatMessagesHash() => r'5be030606a5699e3649192eb2762c604f75c2812';

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
