/// The schedule feature's public widgets (ARCH §5.2 rule 7). Other features
/// import this file, never schedule's presentation/ files.
library;

export 'presentation/event_card.dart' show EventCard;
// How answers and times read, for a player's RSVP history (PLAYER-11).
export 'presentation/schedule_format.dart'
    show statusColor, statusIcon, statusLabel, timeRange;
