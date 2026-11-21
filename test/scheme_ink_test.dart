// The server checks a theme's text against the built-in schemes' own
// colors, from shared/constants.json's schemeInk (#83). They must be the
// app's, or a theme the editor allows could be refused (or the other way
// round): every built-in scheme has its entry, with its roles as they are.
// And every color the editor offers from the built-in themes has a name.
import 'dart:convert';
import 'dart:io';

import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/admin/presentation/theme_palette.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Color;

void main() {
  test("schemeInk is each built-in scheme's text and what it sits on", () {
    final json = jsonDecode(
      File('shared/constants.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ink = Map.of(json['schemeInk'] as Map<String, dynamic>)
      ..remove(r'$comment');
    expect(ink.keys.toSet(), {for (final s in builtInSchemes) s.value});
    for (final scheme in builtInSchemes) {
      final r = SchemeRoles.builtIn(scheme);
      final entry = ink[scheme.value] as Map<String, dynamic>;
      expect(entry, {
        'page': ColorMath.hex(r.page),
        'text': ColorMath.hex(r.text),
        'tabbar': ColorMath.hex(r.tabbar),
        'field': ColorMath.hex(r.field),
        'card': ColorMath.hex(r.card),
        'cardText': ColorMath.hex(r.cardText),
        'cardField': ColorMath.hex(r.cardField),
        'popup': ColorMath.hex(r.popup),
        'candyInk': ColorMath.hex(r.candyInk),
      }, reason: '${scheme.value}: run the change through schemeInk too');
    }
  });

  test("every built-in theme's color in the editor has a name", () {
    final l10n = AppLocalizationsEn();
    for (final scheme in builtInSchemes) {
      for (final named in schemeColors(l10n, scheme)) {
        expect(
          named.name,
          isNot(startsWith('#')),
          reason: '${scheme.value} ${named.name}: name it in theme_palette',
        );
      }
    }
    // A color typed in gets the nearest name.
    expect(colorNameOf(l10n, const Color(0xFF701C30)), 'Wine');
    expect(colorNameOf(l10n, const Color(0xFF702030)), 'Close to Wine');
  });
}
