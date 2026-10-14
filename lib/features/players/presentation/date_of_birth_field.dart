import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a date of birth from a calendar (PLAYER-12), within
/// [dateOfBirthRange]: opening on [current], or on the year list near a
/// youth player's age. Returns the day at midnight UTC, or null when
/// canceled.
Future<DateTime?> pickDateOfBirth(
  BuildContext context,
  DateTime? current,
) async {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final range = dateOfBirthRange(now);
  var initial = current == null
      ? DateTime(now.year - 10, now.month, now.day)
      : DateTime(current.year, current.month, current.day);
  if (initial.isBefore(range.first)) initial = range.first;
  if (initial.isAfter(range.last)) initial = range.last;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: range.first,
    lastDate: range.last,
    initialDatePickerMode: current == null
        ? DatePickerMode.year
        : DatePickerMode.day,
    helpText: l10n.dateOfBirthLabel,
  );
  return picked == null
      ? null
      : DateTime.utc(picked.year, picked.month, picked.day);
}

/// An optional date of birth on the player forms (PLAYER-12): the date and
/// age once picked, with ✕ to clear it, and who sees it. It's kept in the
/// player's details, which only the team's admins and the player's own
/// people see, never on the roster (PLAYER-10).
class DateOfBirthField extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  /// The day at midnight UTC, or null when not set.
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dob = value;
    final age = dob == null
        ? null
        : ageOn(formatDateOfBirth(dob), DateTime.now());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(AppIcons.birthday),
      title: Text(l10n.dateOfBirthLabel),
      subtitle: Text(
        [
          if (dob == null)
            l10n.dateOfBirthNotSet
          else ...[
            MaterialLocalizations.of(context).formatShortDate(dob),
            if (age != null) l10n.playerAge(age),
          ],
        ].join(' · '),
      ),
      trailing: dob == null
          ? const Icon(AppIcons.edit)
          : IconButton(
              tooltip: l10n.clearDateOfBirth,
              icon: const Icon(AppIcons.close),
              onPressed: () => onChanged(null),
            ),
      onTap: () => unawaited(
        pickDateOfBirth(context, dob).then((d) {
          if (d != null) onChanged(d);
        }),
      ),
    );
  }
}

/// "Optional. Only the team's admins and the player's own people see it",
/// under a [DateOfBirthField] on a form.
class DateOfBirthPrivacyNote extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context).dateOfBirthPrivate,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
