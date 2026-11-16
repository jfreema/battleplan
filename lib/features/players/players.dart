/// The players feature's public widgets (ARCH §5.2 rule 7). Other features
/// import this file, never players' presentation/ files.
library;

// "Who are you here for?" prompts (PLAYER-3): the card at the top of a
// team's chat, the way to the screen, and how "waiting" is worded.
export 'presentation/player_pick_card.dart'
    show PlayerPickCard, openPlayerPick, playerPickWaitingText;
