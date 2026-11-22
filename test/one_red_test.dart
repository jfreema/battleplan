// One meaning per color (the usability review's #12, owner's go
// 2026-11-16, as Boot Camp Mix has it since #85, SPEC §7.2): your own color
// (mustard, or light blue in Black) is "you"; the scheme's red is games,
// warnings (Canceled, what's owed, errors, Delete), unread, and the send
// and + buttons; and Can't go is its own salmon, never the red. Labels and
// decorations are never red.

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
  group("the red is for warnings, and Can't go is its own", () {
    for (final scheme in bootCampSchemes) {
      testWidgets("${scheme.value}: Canceled and Owes take the red, Can't "
          'go the salmon, each lettered to read', (tester) async {
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
        expect(c.cherry.face, c.roles.palette.red);
        expect(c.cantGo.face, CampPalette.cantGo);
        expect(_textColor(tester, 'Not going'), c.inkOn(c.cantGo));
        expect(_textColor(tester, 'Canceled'), c.inkOn(c.cherry));
        expect(_textColor(tester, 'Owes'), c.inkOn(c.cherry));
        // Other candies keep the ink.
        expect(_textColor(tester, 'Paid'), c.ink);
        expect(
          _filled(find.byType(CanceledBadge), c.cherry.face, tester),
          isNotEmpty,
        );
      });
    }
  });

  group('unread is red', () {
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
      expect(pill.color, GumdropColors.forScheme(TeamScheme.dark).cherry.face);
    });

    testWidgets("Material's badges, the theme's", (tester) async {
      for (final scheme in bootCampSchemes) {
        final c = GumdropColors.forScheme(scheme);
        expect(AppTheme.of(scheme).badgeTheme.backgroundColor, c.cherry.face);
      }
    });
  });

  group('colors people picked keep their look', () {
    test('icon colors are the same in every scheme; "Cherry" is coral', () {
      for (final scheme in bootCampSchemes) {
        final c = GumdropColors.forScheme(scheme);
        expect(Avatar.faceOf(c, AvatarColor.cherry), CandyFaces.coral);
        expect(Avatar.faceOf(c, AvatarColor.grape), CandyFaces.grape);
        expect(Avatar.faceOf(c, AvatarColor.lemon), CandyFaces.lemon);
        // Nobody's hashed color turns the warning red either.
        for (var i = 0; i < 200; i++) {
          expect(Avatar.colorFor(c, 'person$i'), isNot(c.roles.palette.red));
        }
      }
    });

    test('a "Cherry" chat color is your own color; the others are their '
        'own', () {
      for (final scheme in bootCampSchemes) {
        final c = GumdropColors.forScheme(scheme);
        expect(chatCandyAccent(c, ChatCandy.cherry), c.you);
        expect(chatCandyAccent(c, ChatCandy.grape).face, CandyFaces.grape);
      }
    });
  });

  group('in the app', () {
    testWidgets('the eyebrow over the team name is a mustard tag in ink, '
        'never red (#85)', (tester) async {
      // A name short enough for one line in the test font's wide letters,
      // so the eyebrow shows (#13).
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: FakeLocalPrefs()..defaultSchemeValue = TeamScheme.dark,
        users: FakeUserRepository()..colorScheme = TeamScheme.dark,
        groups: {'a': testGroup('a', 'Hawks')},
        memberships: [testMembership('a', 'coach')],
      );
      final c = GumdropColors.forScheme(TeamScheme.dark);
      expect(_textColor(tester, 'TEAM CHAT'), c.ink);
      final tag = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('TEAM CHAT'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((tag.decoration as BoxDecoration).color, c.roles.palette.mustard);
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

    testWidgets('an unanswered card has one mark: a dot by the name, '
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
      // where he has), in your own color; and nothing in the warning red.
      final dots = [
        for (final e in find.text('Noah').evaluate())
          ..._filled(
            find
                .ancestor(
                  of: find.byElementPredicate((x) => x == e),
                  matching: find.byType(Stack),
                )
                .first,
            GumdropColors.forScheme(TeamScheme.dark).you.face,
            tester,
          ),
      ];
      expect(dots, isNotEmpty);
      expect(dots.map((d) => d.shape), everyElement(BoxShape.circle));
      final schedule = find.byType(Scaffold).first;
      expect(_filled(schedule, c.cherry.face, tester), isEmpty);
    });
  });
}

void _ignore(RsvpStatus _) {}
