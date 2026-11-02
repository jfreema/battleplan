import 'package:battleplan/core/constants.g.dart';

/// The words chat search finds [text] by (CHAT-20), and the words of a
/// search: lowercase, without apostrophes or accents ([searchFolds]), each
/// run of letters and digits from 2 to [Limits.searchWordLengthMax] long
/// that isn't one of [searchStopWords], a plural read as its singular, each
/// once, in order. A message keeps at most [max], its longest. The rules
/// are in shared/search_words.json; functions/src/chat/search_words.ts
/// takes the same steps on the server, so a search finds what either wrote.
List<String> searchWords(String text, {int max = Limits.searchWordsMax}) {
  if (text.isEmpty) return const [];
  final plain = StringBuffer();
  for (final rune in text.toLowerCase().replaceAll(_apostrophes, '').runes) {
    final c = String.fromCharCode(rune);
    plain.write(searchFolds[c] ?? c);
  }
  final words = <String>[];
  final seen = <String>{};
  for (final m in _word.allMatches(plain.toString().replaceAll(_marks, ''))) {
    var w = m[0]!;
    final length = w.runes.length;
    if (length < 2 ||
        length > Limits.searchWordLengthMax ||
        searchStopWords.contains(w)) {
      continue;
    }
    if (length >= 5 && w.endsWith('ies')) {
      w = '${w.substring(0, w.length - 3)}y';
    } else if (length >= 4 && w.endsWith('s') && !w.endsWith('ss')) {
      w = w.substring(0, w.length - 1);
    }
    if (seen.add(w)) words.add(w);
  }
  if (words.length <= max) return words;
  // The longest, in their order.
  final byLength = List.generate(words.length, (i) => i)
    ..sort((a, b) {
      final longer = words[b].runes.length - words[a].runes.length;
      return longer != 0 ? longer : a - b;
    });
  final keep = byLength.take(max).toSet();
  return [
    for (final (i, w) in words.indexed)
      if (keep.contains(i)) w,
  ];
}

/// Whether [text]'s words include every one of [terms], a search's words.
bool hasSearchWords(String text, List<String> terms) {
  if (terms.isEmpty) return false;
  final words = searchWords(text).toSet();
  return terms.every(words.contains);
}

final _apostrophes = RegExp(r"['\u2019\u02BC]");
final _marks = RegExp(r'[\u0300-\u036F]');
final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);
