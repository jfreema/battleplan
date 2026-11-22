import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';

/// A person's dog tag (#85, SPEC §7.4): their initials in ink stencil on
/// their color (or their photo), on a rounded tag in a 3 px ink outline,
/// with a punched hole and a hard shadow, turned a little.
///
/// [DogTag.chat] is the one beside their messages, 42 × 30 with the hole
/// at its left, turned -7°; [DogTag.hanging] hangs from a ball chain on
/// the event's players list, 38 × 46 with the hole at its top.
class DogTag extends StatelessWidget {
  const new({
    required this.name,
    this.colorKey,
    this.color,
    this.imageUrl,
    this.width = 42,
    this.height = 30,
    this.turn = -7,
    this.holeOnTop = false,
    this.fill,
    super.key,
  });

  /// Beside their messages in the chat.
  const new chat({
    required this.name,
    this.colorKey,
    this.color,
    this.imageUrl,
    super.key,
  }) : width = 42,
       height = 30,
       turn = -7,
       holeOnTop = false,
       fill = null;

  /// Hanging from the ball chain on the event's players list; [turn]
  /// alternates down the list. [fill] is the unanswered tag's color.
  const new hanging({
    required this.name,
    this.colorKey,
    this.color,
    this.imageUrl,
    this.turn = -4,
    this.fill,
    super.key,
  }) : width = 38,
       height = 46,
       holeOnTop = true;

  final String name;

  /// Keeps a person's color the same everywhere (their uid, usually).
  final String? colorKey;

  /// The icon color they picked; null for the hashed one.
  final AvatarColor? color;
  final String? imageUrl;
  final double width;
  final double height;

  /// How far it's turned, in degrees.
  final double turn;

  /// Whether the hole is at the top (hanging) or the left (chat).
  final bool holeOnTop;

  /// A fill other than their color: the unanswered tag's.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final ink = c.ink;
    final url = imageUrl;
    final background = fill ?? Avatar.fillOf(c, color, colorKey ?? name);
    final radius = BorderRadius.circular(holeOnTop ? 10 : 9);
    final initials = Text(
      Avatar.initialsOf(name),
      maxLines: 1,
      // The tag doesn't grow with the text size, so its initials don't
      // either, or big text would clip them.
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppFonts.stencil,
        fontWeight: FontWeight.w900,
        fontSize: holeOnTop ? 19 : 15,
        height: 1,
        letterSpacing: holeOnTop ? 0.6 : 0.75,
        color: ink,
      ),
    );
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: turn * 3.141592653589793 / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: ink, width: 3),
            boxShadow: [
              BoxShadow(color: c.pageShadow, offset: const Offset(2, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                if (url == null)
                  Padding(
                    // Clear of the hole.
                    padding: holeOnTop
                        ? const EdgeInsets.only(top: 8)
                        : const EdgeInsets.only(left: 6),
                    child: Center(child: initials),
                  ),
                // The punched hole.
                Align(
                  alignment: holeOnTop
                      ? const Alignment(0, -0.78)
                      : const Alignment(-0.74, 0),
                  child: Container(
                    width: holeOnTop ? 6 : 5,
                    height: holeOnTop ? 6 : 5,
                    decoration: BoxDecoration(
                      color: ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
