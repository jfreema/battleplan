/// The candy message colors of the chat look (CHAT-18), as Gumdrop Pop
/// shows them. Each is stored in `chatTheme.bubbleColor` as its Gumdrop Pop
/// Dark face (the value is the choice, not the paint: every theme draws
/// it in its own shade of that candy). A team palette color there is the
/// team's color (or one picked before 1.1), drawn as it is; null is the
/// theme's "you" color.
enum ChatCandy {
  blueRaspberry(0xFF4D9BFF),
  bubblegum(0xFFFF7AC8),
  grape(0xFFA88BFF),
  mint(0xFF4DDC8C),
  lemon(0xFFFFD84A),
  tangerine(0xFFFF9B42),
  cherry(0xFFFF5D73);

  new(this.stored);

  /// The ARGB value saved for it.
  final int stored;

  /// The candy saved as [argb], if it is one.
  static ChatCandy? fromStored(int? argb) {
    if (argb == null) return null;
    for (final c in values) {
      if (c.stored == argb | 0xFF000000) return c;
    }
    return null;
  }
}
