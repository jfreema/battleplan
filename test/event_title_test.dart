// The event page's title (#74, owner's report 2026-11-20: "makes event
// header too big", with "@ Springfield Isotopes" broken as "Springfie /
// ld"): the title is the big outlined stencil (51 since Boot Camp Mix,
// #85), steps down for a long word, and never breaks a word in two; "vs." or "@" stays with the first
// word; and "Who's going" lets RSVP for a player go under it.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/scenes.dart';

void main() {
  List<Event> withOpponent(String opponent) => [
    sceneEvent(
      'e1',
      day: 14,
      title: autoGameTitle(opponent, HomeAway.away),
      type: EventType.game,
      counts: const RsvpCounts(going: 2, maybe: 1, notGoing: 1),
    ).copyWith(opponent: opponent, homeAway: HomeAway.away),
    ...sceneEvents.skip(1),
  ];

  Future<void> openEvent(
    WidgetTester tester,
    String opponent, {
    double text = 1,
    double width = 390,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpTeam(
      tester,
      scheme: TeamScheme.army,
      events: withOpponent(opponent),
      size: Size(width, 900),
    );
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(opponent).first);
    await tester.pumpAndSettle();
  }

  /// The title's paragraph: "@ Springfield Isotopes".
  RenderParagraph title(WidgetTester tester, String opponent) =>
      tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(OutlinedText),
              matching: find.byWidgetPredicate(
                (w) => w is RichText && w.text.toPlainText().endsWith(opponent),
              ),
            )
            .first,
      );

  /// [p]'s text laid out as it is, to ask about its lines.
  TextPainter painterOf(RenderParagraph p) => TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
  )..layout(maxWidth: p.constraints.maxWidth);

  TextRange lineOf(RenderParagraph p, int offset) {
    final painter = painterOf(p);
    final line = painter.getLineBoundary(TextPosition(offset: offset));
    painter.dispose();
    return line;
  }

  testWidgets('a long name never breaks a word, with large text or on a '
      'small phone, and "@" stays with its first word', (tester) async {
    const opponent = 'Springfield Isotopes';
    for (final (text, width) in [
      (1.0, 390.0),
      (1.3, 390.0),
      (2.0, 390.0),
      (1.0, 320.0),
    ]) {
      await openEvent(tester, opponent, text: text, width: width);
      final p = title(tester, opponent);
      final plain = p.text.toPlainText();
      expect(plain, '@ Springfield Isotopes');
      for (final word in ['Springfield', 'Isotopes']) {
        final start = plain.indexOf(word);
        expect(
          lineOf(p, start + word.length - 1),
          lineOf(p, start),
          reason: '$word whole at ${text}x, $width wide',
        );
      }
      expect(
        lineOf(p, plain.indexOf('Springfield')),
        lineOf(p, 0),
        reason: '"@" with Springfield at ${text}x, $width wide',
      );
      // Nothing runs past the side.
      expect(p.size.width, lessThanOrEqualTo(width));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a short name is the big outlined stencil, 51 (#85)', (
    tester,
  ) async {
    // Wide enough for the test font's 1 em letters.
    await openEvent(tester, 'Eagles', width: 1000);
    expect(title(tester, 'Eagles').text.style?.fontSize, 51);
  });

  testWidgets('RSVP for a player goes under "Who\'s going" when both '
      "don't fit, and beside it when they do", (tester) async {
    await openEvent(tester, 'Eagles');
    final heading = find.text("Who's going");
    final button = find.text('RSVP for a player');
    await tester.ensureVisible(heading);
    await tester.pumpAndSettle();
    // One line for the heading, the button under it.
    final lines = painterOf(tester.renderObject<RenderParagraph>(heading));
    expect(lines.computeLineMetrics(), hasLength(1));
    lines.dispose();
    expect(
      tester.getTopLeft(button).dy,
      greaterThan(tester.getBottomLeft(heading).dy),
    );

    await openEvent(tester, 'Eagles', width: 1000);
    await tester.ensureVisible(heading);
    await tester.pumpAndSettle();
    expect(
      (tester.getCenter(button).dy - tester.getCenter(heading).dy).abs(),
      lessThan(4),
    );
    expect(
      tester.getTopLeft(button).dx,
      greaterThan(tester.getTopRight(heading).dx),
    );
  });
}
