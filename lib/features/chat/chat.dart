/// The chat feature's public widgets (ARCH §5.2 rule 7). Other features
/// import this file, never chat's presentation/ files.
library;

export 'presentation/direct_actions.dart'
    show MessageButton, openDirectChatWith, openPersonPage, personPageLocation;
export 'presentation/messages_button.dart' show MessagesButton;
