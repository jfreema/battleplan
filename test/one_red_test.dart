// One meaning per red (the usability review's #12, owner's go 2026-11-16):
// coral is "you" (your messages, the main button, the current tab, and
// unread), and a deeper warning red is only for Not going, Canceled, what's
// owed, errors, and Delete. Until then they were one color, so a normal
// week read like a list of problems (SPEC §7.2).

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/gumdrop_icon_button.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_widgets.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/features/groups/presentation/chat_bubble_colors.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';
import 'helpers/scenes.dart';

/// [child] alone, in [scheme]'s theme, with the app's strings.
Future<void> _pumpThemed(
  WidgetTester tester,
  Widget child, {
  TeamScheme scheme = TeamScheme.dark,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.of(scheme),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

/// The color of [text]'s first run.
Color? _textColor(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

/// Every box under [of] filled with [color].
Iterable<BoxDecoration> _filled(Finder of, Color color, WidgetTester tester) =>
    tester
        .widgetList<Container>(
          find.descendant(of: of, matching: find.byType(Container)),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == color);

void main() {
  group('the warning red is only for warnings', () {
    for (final scheme in TeamScheme.values) {
      testWidgets('${scheme.value}: Not going, Canceled, and Owes take it, '
          'with white text', (tester) async {
        final c = GumdropColors.forScheme(scheme);
        await _pumpThemed(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RsvpChoice(
                statuses: RsvpStatus.values,
                current: RsvpStatus.notGoing,
                onChanged: _ignore,
                compact: true,
              ),
              CanceledBadge(),
              DueStatePill(state: DueShareState.owes),
              DueStatePill(state: DueShareState.paid),
            ],
          ),
          scheme: scheme,
        );
        expect(c.cherry.face, CandyFaces.cherry);
        expect(_textColor(tester, 'Not going'), Colors.white);
        expect(_textColor(tester, 'Canceled'), Colors.white);
        expect(_textColor(tester, 'Owes'), Colors.white);
        // Other candies keep the ink.
        expect(_textColor(tester, 'Paid'), c.ink);
        expect(
          _filled(find.byType(CanceledBadge), CandyFaces.cherry, tester),
          isNotEmpty,
        );
      });
    }
  });

  group('unread is coral', () {
    testWidgets('the count on the bell and the tabs', (tester) async {
      await _pumpThemed(
        tester,
        Builder(
          builder: (context) => unreadBadge(
            context,
            label: '3',
            child: const Icon(Icons.notifications),
          ),
        ),
      );
      final pill = tester
          .widgetList<Container>(
            find.ancestor(of: find.text('3'), matching: find.byType(Container)),
          )
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .first;
      expect(pill.color, CandyFaces.coral);
    });

    testWidgets("Material's badges, the theme's", (tester) async {
      for (final scheme in TeamScheme.values) {
        expect(
          AppTheme.of(scheme).badgeTheme.backgroundColor,
          CandyFaces.coral,
        );
      }
    });
  });

  group('colors people picked keep their look', () {
    test('a "Cherry" icon color is coral, as it was', () {
      for (final scheme in TeamScheme.values) {
        final c = GumdropColors.forScheme(scheme);
        expect(Avatar.faceOf(c, AvatarColor.cherry), CandyFaces.coral);
        // Nobody's hashed color turns the warning red either.
        for (var i = 0; i < 200; i++) {
          expect(Avatar.colorFor(c, 'person$i'), isNot(CandyFaces.cherry));
        }
      }
    });

    test('a "Cherry" chat color is coral, as it was', () {
      for (final scheme in TeamScheme.values) {
        final c = GumdropColors.forScheme(scheme);
        expect(chatCandyAccent(c, ChatCandy.cherry), c.you);
      }
    });
  });

  group('in the app', () {
    testWidgets('the stencil eyebrow over the team name is muted', (
      tester,
    ) async {
      await pumpChat(tester, scheme: TeamScheme.dark);
      final c = GumdropColors.forScheme(TeamScheme.dark);
      expect(HeaderEyebrow.style(c).color, c.textMutedOnPage);
      expect(_textColor(tester, 'TEAM CHAT'), c.textMutedOnPage);
    });

    testWidgets('the pin in the chat is lemon', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        groups: {
          'a': testGroup('a', 'Thunder').copyWith(pinnedMessageIds: ['m1']),
        },
        memberRepo: FakeMemberRepository([
          testMembership('a', 'coach', role: MemberRole.owner),
        ]),
        messageRepo: FakeMessageRepository([
          Message(
            id: 'm1',
            groupId: const GroupId('a'),
            authorId: 'coach',
            authorName: 'Coach Lee',
            type: MessageType.text,
            text: 'Bring water',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ]),
        size: phoneSize,
      );
      final c = GumdropColors.of(tester.element(find.byType(Scaffold).first));
      final pin = tester.widget<Icon>(find.byIcon(AppIcons.pin).first);
      expect(pin.color, c.lemon.text);
    });

    testWidgets('jersey numbers are on a plain disc', (tester) async {
      await pumpTeamTab(tester, scheme: TeamScheme.dark);
      final c = GumdropColors.forScheme(TeamScheme.dark);
      final disc =
          tester
                  .widget<Container>(
                    find
                        .ancestor(
                          of: find.text('7'),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(disc.shape, BoxShape.circle);
      expect(disc.color, c.well);
      expect(_textColor(tester, '7'), c.textOnPage);
    });

    testWidgets('an unanswered card has one mark: a coral dot by the name, '
        "and the count's own gray for who hasn't answered", (tester) async {
      await pumpSchedule(tester, scheme: TeamScheme.dark);
      final c = GumdropColors.forScheme(TeamScheme.dark).card;
      final note = find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains("Noah hasn't answered"),
      );
      expect(note, findsWidgets);
      final span = tester.widget<RichText>(note.first).text as TextSpan;
      // No run in another color: the count's muted text throughout.
      void noColor(InlineSpan s) {
        if (s is TextSpan) {
          if (s != span) expect(s.style?.color, isNull);
          s.children?.forEach(noColor);
        }
      }

      noColor(span);
      expect(span.style?.color, c.textMuted);
      // The dot by Noah's name where he hasn't answered (not on the game,
      // where he has), coral; and nothing in the warning red.
      final dots = [
        for (final e in find.text('Noah').evaluate())
          ..._filled(
            find
                .ancestor(
                  of: find.byElementPredicate((x) => x == e),
                  matching: find.byType(Stack),
                )
                .first,
            CandyFaces.coral,
            tester,
          ),
      ];
      expect(dots, isNotEmpty);
      expect(dots.map((d) => d.shape), everyElement(BoxShape.circle));
      final schedule = find.byType(Scaffold).first;
      expect(_filled(schedule, CandyFaces.cherry, tester), isEmpty);
    });
  });
}

void _ignore(RsvpStatus _) {}
