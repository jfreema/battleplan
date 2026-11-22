import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// [candy] in the theme [c]: its own face, the same in every scheme as
/// people's colors are (#85), on the theme's lip, with the theme's ink on
/// it (every candy face reads it) and its text made to read where it sits.
GumdropAccent chatCandyAccent(GumdropColors c, ChatCandy candy) {
  GumdropAccent own(Color face, GumdropAccent theme) => GumdropAccent(
    face: face,
    lip: theme.lip,
    text: ColorMath.readable(face, [if (c.onCard) c.surface else c.page]),
  );
  return switch (candy) {
    ChatCandy.blueRaspberry => own(CandyFaces.blueRaspberry, c.blueRaspberry),
    ChatCandy.bubblegum => own(CandyFaces.bubblegum, c.bubblegum),
    ChatCandy.grape => own(CandyFaces.grape, c.grape),
    ChatCandy.mint => own(CandyFaces.mint, c.mint),
    ChatCandy.lemon => own(CandyFaces.lemon, c.lemon),
    ChatCandy.tangerine => own(CandyFaces.tangerine, c.tangerine),
    // The theme's "you" color, your own balloon's (mustard, or light blue
    // in Black, #85): what a team that hasn't picked a color sees, and the
    // stored "Cherry" pick from when it was coral.
    ChatCandy.cherry => c.you,
  };
}

/// A candy's name. Cherry is the theme's "you" color, so with [c], where
/// "you" isn't coral (every Boot Camp Mix scheme, #85), it's "Theme
/// color" (#83).
String chatCandyName(
  AppLocalizations l10n,
  ChatCandy candy, {
  GumdropColors? c,
}) => switch (candy) {
  ChatCandy.blueRaspberry => l10n.candyBlueRaspberry,
  ChatCandy.bubblegum => l10n.candyBubblegum,
  ChatCandy.grape => l10n.candyGrape,
  ChatCandy.mint => l10n.candyMint,
  ChatCandy.lemon => l10n.candyLemon,
  ChatCandy.tangerine => l10n.candyTangerine,
  ChatCandy.cherry when c != null && c.you.face != c.coral.face =>
    l10n.candyThemeColor,
  ChatCandy.cherry => l10n.candyCherry,
};

/// The candies in the order the Chat look shows them: coral (Cherry)
/// first, the "you" color when nothing is picked, in every scheme
/// (CHAT-18).
const List<ChatCandy> chatCandyOrder = [
  ChatCandy.cherry,
  ChatCandy.bubblegum,
  ChatCandy.grape,
  ChatCandy.mint,
  ChatCandy.lemon,
  ChatCandy.tangerine,
  ChatCandy.blueRaspberry,
];

/// My bubbles' color for a team's chat look (CHAT-18) in the theme [c]: a
/// candy in the theme's shade, a team palette color as it is, or null
/// (nothing picked) for the theme's "you" color.
Color? chatBubbleColor(GumdropColors c, int? stored) {
  final candy = ChatCandy.fromStored(stored);
  if (candy != null) return chatCandyAccent(c, candy).face;
  return stored == null ? null : Color(stored | 0xFF000000);
}
