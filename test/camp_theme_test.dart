// The theme editor's Boot Camp Mix colors (#88): read from config/app,
// checked for colors nearly the same as what they sit on, and drawn in
// every scheme they change, except the Super Admin Panel's; and the header
// backgrounds drawn from its camouflage colors (#91).
import 'dart:ui' as ui;

import 'package:battleplan/core/camp_theme.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/theme_readability.dart';
import 'package:battleplan/core/widgets/header_patterns.dart';
import 'package:battleplan/features/admin/data/functions_admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _coral = 0xFFF45B5B;

void main() {
  tearDown(() => ThemeCatalog.installCamp(const {}));

  group('config/app.campThemes', () {
    test("reads each scheme's tokens as colors, skipping anything else", () {
      final themes = campThemesFromConfig({
        'dark': {'red': '#f45b5b', 'mustard': '#FDD023', 'accent': '#000000'},
        'light': {'page': 'white', 'red': 12},
        'plaid': {'red': '#F45B5B'},
        'army': 'not a map',
      });
      expect(themes, {
        TeamScheme.dark: const CampTheme(
          colors: {CampColor.red: _coral, CampColor.mustard: 0xFFFDD023},
        ),
      });
      expect(campThemesFromConfig(null), isEmpty);
      expect(campColorsToConfig({CampColor.red: _coral}), {'red': '#F45B5B'});
    });

    test('the app reads them with the rest of config/app, leaving the first '
        "editor's themes as they were", () {
      final config = appConfigFromFirestore({
        'campThemes': {
          'sky': {'red': '#F45B5B'},
        },
        'themes': {
          'army': {'accent': '#123456'},
        },
      });
      expect(config.campThemes, {
        TeamScheme.sky: const CampTheme(colors: {CampColor.red: _coral}),
      });
      expect(config.themes.keys, [TeamScheme.army]);
    });

    test('compares by what they hold', () {
      expect(
        campThemesEqual(
          {
            TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
          },
          {
            TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
          },
        ),
        isTrue,
      );
      expect(
        campThemesEqual(
          {
            TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
          },
          {
            TeamScheme.dark: const CampTheme(colors: {CampColor.blue: _coral}),
          },
        ),
        isFalse,
      );
    });
  });

  group("a palette with the editor's colors", () {
    test('changes only what they set, the see-through dots and halftone '
        'kept', () {
      const base = CampPalette.black;
      final edited = base.withColors({
        CampColor.red: const Color(_coral),
        CampColor.page: const Color(0xFF101010),
      });
      expect(edited.red, const Color(_coral));
      expect(edited.page, const Color(0xFF101010));
      for (final c in CampColor.values) {
        if (c == CampColor.red || c == CampColor.page) continue;
        expect(edited.colorOf(c), base.colorOf(c), reason: c.value);
      }
      expect(edited.pageDots, base.pageDots);
      expect(edited.headerHalftone, base.headerHalftone);
      expect(base.withColors(const {}), same(base));
    });
  });

  group('colors nearly the same as what they sit on', () {
    test('none in any scheme as it ships', () {
      for (final scheme in bootCampSchemes) {
        final p = SchemeRoles.builtIn(scheme).palette;
        expect(campThemeProblems(p, p), isEmpty, reason: scheme.value);
        expect(campThemeReads(scheme, const CampTheme()), isTrue);
      }
    });

    test('games, send and alerts can be any color that stands apart', () {
      expect(
        campThemeReads(
          TeamScheme.dark,
          const CampTheme(colors: {CampColor.red: _coral}),
        ),
        isTrue,
      );
      // Not the page's, nor the panels'.
      const army = CampPalette.army;
      final problems = campThemeProblems(
        army,
        army.withColors({CampColor.red: army.page}),
      );
      expect(problems.map((p) => (p.fg, p.bg)), [
        (CampColor.red, CampColor.page),
        (CampColor.red, CampColor.panel),
      ]);
    });

    test("text on its page, tab bar, text boxes and panels, the header's "
        "lettering, the tags' trim, the current tab, and your messages", () {
      List<(CampColor, CampColor)> problems(
        CampPalette p,
        Map<CampColor, Color> colors,
      ) => [
        for (final pair in campThemeProblems(p, p.withColors(colors)))
          (pair.fg, pair.bg),
      ];
      const dark = CampPalette.black;
      expect(problems(dark, {CampColor.page: dark.text}), [
        (CampColor.text, CampColor.page),
      ]);
      expect(problems(dark, {CampColor.mustard: const Color(0xFF050505)}), [
        (CampColor.ink, CampColor.mustard),
        (CampColor.mustard, CampColor.tabBar),
      ]);
      expect(problems(dark, {CampColor.balloon: dark.page}), [
        (CampColor.balloon, CampColor.page),
      ]);
      expect(problems(dark, {CampColor.headerLettering: dark.camoGround}), [
        (CampColor.headerLettering, CampColor.camoGround),
      ]);
      // Tropic Blue's text boxes are the camouflage's ground.
      const candy = CampPalette.tropicBlue;
      expect(problems(candy, {CampColor.camoGround: const Color(0xFFFFFFFF)}), [
        (CampColor.text, CampColor.camoGround),
        (CampColor.headerLettering, CampColor.camoGround),
      ]);
      // Black's ink is black on its near-black page as it ships: never
      // refused for that.
      expect(problems(dark, {CampColor.shadow: dark.ink}), isEmpty);
    });

    test('colors saved that would be hard to read are never drawn', () {
      final themes = readableCampThemes({
        TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
        TeamScheme.light: CampTheme(
          colors: {CampColor.text: CampPalette.light.page.toARGB32()},
        ),
      });
      expect(themes.keys, [TeamScheme.dark]);
    });
  });

  group('drawing them', () {
    test('every scheme they change is drawn in them, built once per change; '
        'the Super Admin Panel keeps the colors as they ship', () {
      expect(SchemeRoles.of(TeamScheme.dark), same(SchemeRoles.dark));
      final before = ThemeCatalog.version;
      ThemeCatalog.installCamp({
        TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
      });
      expect(ThemeCatalog.version, before + 1);
      final roles = SchemeRoles.of(TeamScheme.dark);
      expect(roles.palette.red, const Color(_coral));
      expect(SchemeRoles.of(TeamScheme.dark), same(roles));
      // A pick stored as an old scheme draws in its Boot Camp Mix one.
      expect(
        SchemeRoles.of(TeamScheme.scoreboard).palette.red,
        const Color(_coral),
      );
      // The other schemes, and the panel's colors, as they ship.
      expect(SchemeRoles.of(TeamScheme.light), same(SchemeRoles.light));
      expect(
        GumdropColors.forScheme(TeamScheme.dark, shipped: true).roles,
        same(SchemeRoles.dark),
      );
      expect(
        GumdropColors.forScheme(TeamScheme.dark).roles.palette.red,
        const Color(_coral),
      );
      // The same colors again change nothing.
      ThemeCatalog.installCamp({
        TeamScheme.dark: const CampTheme(colors: {CampColor.red: _coral}),
      });
      expect(ThemeCatalog.version, before + 1);
    });

    test("the app's theme is built again when they change, and follows a "
        'page made light', () {
      final darkBefore = AppTheme.of(TeamScheme.dark);
      expect(darkBefore.brightness, Brightness.dark);
      ThemeCatalog.installCamp({
        TeamScheme.dark: const CampTheme(
          colors: {
            CampColor.page: 0xFFF2EBE0,
            CampColor.text: 0xFF1A1A18,
            CampColor.tabBar: 0xFFFFFFFF,
            CampColor.panel: 0xFFFFFFFF,
            CampColor.panelText: 0xFF1A1A18,
            CampColor.headerLettering: 0xFF1A1A18,
            CampColor.camoGround: 0xFFC7B787,
          },
        ),
      });
      final after = AppTheme.of(TeamScheme.dark);
      expect(after, isNot(same(darkBefore)));
      expect(after.brightness, Brightness.light);
    });

    test("the editor's preview draws unsaved colors without installing "
        'them', () {
      final roles = SchemeRoles.edited(TeamScheme.purplegold, const {
        CampColor.red: 0xFFFDD023,
      });
      expect(roles.palette.red, const Color(0xFFFDD023));
      expect(
        SchemeRoles.of(TeamScheme.purplegold),
        same(SchemeRoles.purplegold),
      );
    });
  });

  group('header backgrounds (#91)', () {
    test("are read and kept with the scheme's colors, the camouflage unless "
        'set', () {
      final themes = campThemesFromConfig({
        'dark': {'red': '#F45B5B', 'header': 'topo'},
        'light': {'header': 'stripes'},
        'army': {'header': 'plaid'},
        'sky': {'header': 'camo'},
      });
      expect(themes, {
        TeamScheme.dark: const CampTheme(
          colors: {CampColor.red: _coral},
          header: HeaderStyle.topo,
        ),
        TeamScheme.light: const CampTheme(header: HeaderStyle.stripes),
      });
      expect(const CampTheme().isEmpty, isTrue);
      expect(
        const CampTheme(header: HeaderStyle.digital),
        isNot(const CampTheme()),
      );
    });

    test('a scheme is drawn under its own; the panel under the camouflage', () {
      expect(ThemeCatalog.headerStyleOf(TeamScheme.dark), HeaderStyle.camo);
      ThemeCatalog.installCamp({
        TeamScheme.dark: const CampTheme(header: HeaderStyle.playbook),
      });
      expect(ThemeCatalog.headerStyleOf(TeamScheme.dark), HeaderStyle.playbook);
      expect(
        ThemeCatalog.headerStyleOf(TeamScheme.scoreboard),
        HeaderStyle.playbook,
      );
      expect(ThemeCatalog.headerStyleOf(TeamScheme.light), HeaderStyle.camo);
      // A header alone changes no color.
      expect(SchemeRoles.of(TeamScheme.dark), same(SchemeRoles.dark));
    });

    for (final style in HeaderStyle.values.skip(1)) {
      test(
        '${style.value} is drawn in the four camouflage colors only',
        () async {
          const p = CampPalette.army;
          final recorder = ui.PictureRecorder();
          HeaderPatternPainter(
            style,
            p,
          ).paint(Canvas(recorder), HeaderPatternPainter.tile);
          final image = await recorder.endRecording().toImage(400, 140);
          final bytes = (await image.toByteData())!;
          final counts = <int, int>{};
          for (var i = 0; i < bytes.lengthInBytes; i += 4) {
            final argb =
                bytes.getUint8(i + 3) << 24 |
                bytes.getUint8(i) << 16 |
                bytes.getUint8(i + 1) << 8 |
                bytes.getUint8(i + 2);
            counts[argb] = (counts[argb] ?? 0) + 1;
          }
          image.dispose();
          final camo = {
            p.camoGround.toARGB32(),
            p.camoBig.toARGB32(),
            p.camoMid.toARGB32(),
            p.camoSmall.toARGB32(),
          };
          // Every color that covers a real share of it is one of the four (or
          // the halftone's 55% big-color wash), or, along the edges, a blend
          // of two of them.
          final colors = [
            ...camo,
            Color.alphaBlend(
              p.camoBig.withValues(alpha: 0.55),
              p.camoGround,
            ).toARGB32(),
          ];
          bool between(int c, int a, int b) {
            double? t;
            for (final shift in [16, 8, 0]) {
              final (x, y, z) = (
                c >> shift & 0xFF,
                a >> shift & 0xFF,
                b >> shift & 0xFF,
              );
              if (y == z) {
                if ((x - y).abs() > 2) return false;
                continue;
              }
              final u = (x - y) / (z - y);
              if (u < -0.02 || u > 1.02) return false;
              if (t != null && (u - t).abs() > 0.08) return false;
              t ??= u;
            }
            return true;
          }

          final main = [
            for (final MapEntry(:key, :value) in counts.entries)
              if (value > 400 * 140 * 0.01) key,
          ];
          expect(main, isNotEmpty);
          for (final argb in main) {
            expect(
              colors.any((a) => colors.any((b) => between(argb, a, b))),
              isTrue,
              reason: '${style.value}: ${argb.toRadixString(16)}',
            );
          }
          // And the ground shows, as on the camouflage.
          expect(counts[p.camoGround.toARGB32()] ?? 0, greaterThan(0));
        },
      );
    }
  });
}
