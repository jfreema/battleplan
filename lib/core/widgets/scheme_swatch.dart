import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:material_ui/material_ui.dart';

/// A little picture of a color scheme (SET-2): its page with a tiny card on
/// it, a dot of its "you" color and a line of its text color. Decorative;
/// the row names it. In core, so the theme editor (#82) draws one too.
class SchemeSwatch extends StatelessWidget {
  /// [scheme] as everyone sees it, with any theme editor changes.
  new(TeamScheme scheme, {Key? key})
    : this.roles(SchemeRoles.of(scheme), key: key);

  /// Colors not saved yet: the theme editor's preview (#82).
  const new roles(this.roles, {super.key});

  final SchemeRoles roles;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(64, 44),
      painter: _SwatchPainter(roles, GumdropColors.of(context).outline),
    ),
  );
}

class _SwatchPainter extends CustomPainter {
  new(this.roles, this.ring);

  final SchemeRoles roles;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(outer, Paint()..color = roles.page);
    // The tiny card, on its 2 px lip.
    const card = Rect.fromLTWH(9, 10, 46, 20);
    final cardShape = RRect.fromRectAndRadius(card, const Radius.circular(6));
    canvas
      ..drawRRect(
        cardShape.shift(const Offset(0, 2)),
        Paint()..color = roles.cardRim,
      )
      ..drawRRect(cardShape, Paint()..color = roles.card)
      ..drawRRect(
        cardShape.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = roles.cardRim,
      )
      ..drawCircle(
        card.topLeft + const Offset(5 + 3, 5.5 + 3),
        3,
        // The scheme's "you" color (#82).
        Paint()..color = roles.you,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(card.left + 15, card.top + 6.5, 20, 4),
          const Radius.circular(2),
        ),
        // The card's own text color (Candy Pop's navy, #72).
        Paint()..color = roles.cardText,
      )
      // The inset ring in the screen's outline.
      ..drawRRect(
        outer.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.roles != roles || old.ring != ring;
}
