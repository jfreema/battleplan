import 'package:battleplan/core/constants.g.dart';

/// Someone a message can name with @ (CHAT-14): a team member by their ID
/// and display name, or everyone ([everyoneCandidate], admins only).
typedef MentionCandidate = ({String uid, String name});

/// "@everyone": the whole team, for admins (CHAT-14).
const MentionCandidate everyoneCandidate = (uid: '', name: 'everyone');

/// The most suggestions shown under the @ being typed.
const mentionSuggestionsMax = 5;

/// The @ word being typed just before [cursor] in [text], if any: an @ at
/// the start or after a space, punctuation, or a line break, and what
/// follows it up to the cursor ("@ma" gives "ma"). It may hold spaces, for
/// names like "Mary Ann", but no line break. Null when the cursor isn't in
/// one.
({int start, String query})? mentionQueryAt(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  if (at < 0 || (at > 0 && _beforeAt(before.codeUnitAt(at - 1)))) {
    return null;
  }
  final query = before.substring(at + 1);
  if (query.contains('\n') || query.startsWith(' ') || query.length > 60) {
    return null;
  }
  return (start: at, query: query);
}

/// Who to suggest for [query] (CHAT-14): members whose name, or a word of
/// it, starts with it, ignoring case, full-name matches first, then by
/// name; and @everyone first when [everyone] and it matches. A query with
/// a space matches whole names only, so the list closes once the person
/// types on past a name.
List<MentionCandidate> mentionSuggestions(
  String query,
  List<MentionCandidate> candidates, {
  bool everyone = false,
  int max = mentionSuggestionsMax,
}) {
  final q = query.toLowerCase();
  bool startsName(MentionCandidate c) => c.name.toLowerCase().startsWith(q);
  bool startsWord(MentionCandidate c) =>
      !q.contains(' ') &&
      c.name
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .skip(1)
          .any((w) => w.startsWith(q));
  final byName = [...candidates]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [
    if (everyone && startsName(everyoneCandidate)) everyoneCandidate,
    ...byName.where(startsName),
    ...byName.where((c) => !startsName(c) && startsWord(c)),
  ].take(max).toList();
}

/// The text that completes [candidate]: "@Mary Ann Lee " or "@everyone ".
String mentionText(MentionCandidate candidate) => '@${candidate.name} ';

/// Who [text] names with @ (CHAT-14). Each @ at the start or after a space,
/// punctuation, or a line break is matched against [members]' full names,
/// ignoring case, longest name first, so "@Mary Ann Lee" is Mary Ann Lee
/// even with a Mary Ann on the team. A name must end the text or be
/// followed by something that can't continue a name, so an email address
/// never mentions anyone. "@everyone" counts only when
/// [canMentionEveryone] (admins). At most [Limits.mentionsMax] people, in
/// the order they're named.
({List<String> uids, bool everyone}) mentionsIn(
  String text,
  List<MentionCandidate> members, {
  required bool canMentionEveryone,
}) {
  final uids = <String>[];
  var everyone = false;
  for (final m in _mentionMatches(text, [
    ...members,
    if (canMentionEveryone) everyoneCandidate,
  ])) {
    if (m.candidate.uid.isEmpty) {
      everyone = true;
    } else if (!uids.contains(m.candidate.uid) &&
        uids.length < Limits.mentionsMax) {
      uids.add(m.candidate.uid);
    }
  }
  return (uids: uids, everyone: everyone);
}

/// Where a sent message names people (CHAT-14), for highlighting: each
/// "@Name" of someone it mentions, by [names] (the mentioned people's
/// current names, by ID), and "@everyone" when it mentions [everyone].
/// Mentions of [me], and @everyone, are marked `isMe`: they stand out more.
List<({int start, int end, bool isMe})> mentionRanges(
  String text, {
  required Map<String, String> names,
  bool everyone = false,
  String? me,
}) => [
  for (final m in _mentionMatches(text, [
    for (final e in names.entries) (uid: e.key, name: e.value),
    if (everyone) everyoneCandidate,
  ]))
    (
      start: m.start,
      end: m.end,
      isMe: m.candidate.uid.isEmpty || m.candidate.uid == me,
    ),
];

/// Every "@Name" in [text] naming one of [candidates], left to right, the
/// longest name winning where two start the same way.
Iterable<({int start, int end, MentionCandidate candidate})> _mentionMatches(
  String text,
  List<MentionCandidate> candidates,
) sync* {
  final longestFirst = [
    for (final c in candidates)
      if (c.name.trim().isNotEmpty) (c, c.name.trim().toLowerCase()),
  ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));
  var i = 0;
  while (i < text.length) {
    final at = text.indexOf('@', i);
    if (at < 0) return;
    i = at + 1;
    if (at > 0 && _beforeAt(text.codeUnitAt(at - 1))) continue;
    for (final (c, name) in longestFirst) {
      // Compared in the text's own lengths, so indexes stay true to it.
      final end = at + 1 + c.name.trim().length;
      if (end > text.length) continue;
      if (text.substring(at + 1, end).toLowerCase() != name) continue;
      if (end < text.length && _continuesName(text.codeUnitAt(end))) continue;
      yield (start: at, end: end, candidate: c);
      i = end;
      break;
    }
  }
}

final _addressChar = RegExp(r'[\p{L}\p{N}._%+\-@]', unicode: true);
final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Whether an @ after [unit] is part of an email address ("sam.lee@…"),
/// not a mention.
bool _beforeAt(int unit) => _addressChar.hasMatch(String.fromCharCode(unit));

/// Whether [unit] after a name carries the word on ("@Alexander" isn't
/// Alex). Punctuation ends it: "Thanks @Alex." and "@Alex's" name Alex.
bool _continuesName(int unit) =>
    _letterOrDigit.hasMatch(String.fromCharCode(unit));
