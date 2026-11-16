import 'package:battleplan/l10n/gen/app_localizations.dart';

/// A list in words: "Max", "Max and Sofia", "Mon, Wed, and Fri". Weekdays
/// on a series, the players a card is for, and who a claim waits on use
/// it.
String joinAnd(AppLocalizations l10n, List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;
  if (items.length == 2) return l10n.listTwo(items[0], items[1]);
  // gen-l10n orders the arguments by name: last, then rest.
  return l10n.listMany(
    items.last,
    items.sublist(0, items.length - 1).join(', '),
  );
}
