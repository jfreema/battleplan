import 'package:battleplan/core/constants.g.dart';

/// [text] with the swear words and slurs in [strongLanguage] masked, each
/// keeping its first letter: "What the f***" (SAFE-7). Whole words only,
/// ignoring case; links are left alone. functions/src/safety/
/// strong_language.ts does the same on the server.
String maskStrongLanguage(String text) {
  if (text.isEmpty) return text;
  final out = StringBuffer();
  var at = 0;
  for (final link in _links.allMatches(text)) {
    out
      ..write(_mask(text.substring(at, link.start)))
      ..write(link[0]);
    at = link.end;
  }
  out.write(_mask(text.substring(at)));
  return out.toString();
}

String _mask(String part) =>
    part.replaceAllMapped(_words, (m) => m[0]![0] + '*' * (m[0]!.length - 1));

final _links = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);

final _words = RegExp(
  '(?<!\\p{L})(?:${strongLanguage.map(_pattern).join('|')})(?!\\p{L})',
  caseSensitive: false,
  unicode: true,
);

/// A listed word, or with a trailing * any longer word that starts with it.
String _pattern(String word) => word.endsWith('*')
    ? '${RegExp.escape(word.substring(0, word.length - 1))}\\p{L}*'
    : RegExp.escape(word);
