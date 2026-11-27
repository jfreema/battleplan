// The server checks a theme's text against the schemes' own colors, from
// shared/constants.json's schemeInk (#83). They must be the app's, or a
// theme the app allows could be refused (or the other way round): every
// stored scheme has its entry, with its roles as the app draws them (the
// closest Boot Camp Mix scheme's since #85).
import 'dart:convert';
import 'dart:io';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // The theme editor's server check starts from each Boot Camp Mix
  // scheme's colors as it ships (#88): campPalettes, which must be the
  // app's CampPalette, every token the editor changes.
  test("campPalettes is each Boot Camp Mix scheme's colors as it ships", () {
    final json = jsonDecode(
      File('shared/constants.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final palettes = Map.of(json['campPalettes'] as Map<String, dynamic>)
      ..remove(r'$comment');
    expect(palettes.keys.toSet(), {for (final s in bootCampSchemes) s.value});
    for (final scheme in bootCampSchemes) {
      final p = SchemeRoles.builtIn(scheme).palette;
      expect(palettes[scheme.value], {
        for (final c in CampColor.values) c.value: ColorMath.hex(p.colorOf(c)),
      }, reason: '${scheme.value}: run the change through campPalettes too');
    }
  });

  // The server also checks the header's lettering against the page in the
  // schemes whose own header is plain (#117): campPlainHeaders, which must
  // be the schemes whose palette says so.
  test('campPlainHeaders is the schemes whose own header is plain', () {
    final json = jsonDecode(
      File('shared/constants.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final plain = json['campPlainHeaders'] as Map<String, dynamic>;
    expect(plain['schemes'], [
      for (final s in bootCampSchemes)
        if (SchemeRoles.builtIn(s).palette.touches.plainHeader) s.value,
    ]);
    expect(plain['schemes'], ['candypop']);
  });
}
