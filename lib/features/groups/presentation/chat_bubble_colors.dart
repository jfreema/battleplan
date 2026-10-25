import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// [candy] in the theme [c]: its face and lip in that theme's shade.
GumdropAccent chatCandyAccent(GumdropColors c, ChatCandy candy) =>
    switch (candy) {
      ChatCandy.blueRaspberry => c.blueRaspberry,
      ChatCandy.bubblegum => c.bubblegum,
      ChatCandy.grape => c.grape,
      ChatCandy.mint => c.mint,
      ChatCandy.lemon => c.lemon,
      ChatCandy.tangerine => c.tangerine,
      ChatCandy.cherry => c.cherry,
    };

/// A candy's name.
String chatCandyName(AppLocalizations l10n, ChatCandy candy) => switch (candy) {
  ChatCandy.blueRaspberry => l10n.candyBlueRaspberry,
  ChatCandy.bubblegum => l10n.candyBubblegum,
  ChatCandy.grape => l10n.candyGrape,
  ChatCandy.mint => l10n.candyMint,
  ChatCandy.lemon => l10n.candyLemon,
  ChatCandy.tangerine => l10n.candyTangerine,
  ChatCandy.cherry => l10n.candyCherry,
};

/// The candies in the order the Chat look shows them: the theme's own
/// "you" color first, so Gumdrop Candy starts with Lemon and puts Blue
/// raspberry fifth, where the others have Lemon (design §4.3).
List<ChatCandy> chatCandyOrder(GumdropFlavor flavor) =>
    flavor == GumdropFlavor.candy
    ? const [
        ChatCandy.lemon,
        ChatCandy.bubblegum,
        ChatCandy.grape,
        ChatCandy.mint,
        ChatCandy.blueRaspberry,
        ChatCandy.tangerine,
        ChatCandy.cherry,
      ]
    : const [
        ChatCandy.blueRaspberry,
        ChatCandy.bubblegum,
        ChatCandy.grape,
        ChatCandy.mint,
        ChatCandy.lemon,
        ChatCandy.tangerine,
        ChatCandy.cherry,
      ];

/// My bubbles' color for a team's chat look (CHAT-18) in the theme [c]: a
/// candy in the theme's shade, a team palette color as it is, or null
/// (nothing picked) for the theme's "you" color.
Color? chatBubbleColor(GumdropColors c, int? stored) {
  final candy = ChatCandy.fromStored(stored);
  if (candy != null) return chatCandyAccent(c, candy).face;
  return stored == null ? null : Color(stored | 0xFF000000);
}
