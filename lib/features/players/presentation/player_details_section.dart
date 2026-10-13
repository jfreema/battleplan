import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The player card's Details (PLAYER-12): age and date of birth, emergency
/// contacts with tap-to-call, medical notes, and notes, and Edit, which
/// opens the form at `/g/:groupId/roster/players/:playerId/details`. The
/// card shows it only to the team's admins and the members linked to the
/// player ([seesPlayerDetails]), so nobody else's app asks for the details;
/// [canEdit] is false on an archived team, where they're read-only.
class PlayerDetailsSection extends ConsumerWidget {
  const new({
    required this.groupId,
    required this.playerId,
    required this.canEdit,
    super.key,
  });

  final GroupId groupId;
  final PlayerId playerId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final details = ref.watch(playerDetailsProvider(playerId));
    final d = details.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.playerDetailsTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            // Editing starts from what's stored, so it waits for it.
            if (canEdit)
              TextButton.icon(
                onPressed: details.hasValue
                    ? () => context.push(
                        '/g/${groupId.value}/roster/players/'
                        '${playerId.value}/details',
                      )
                    : null,
                icon: const Icon(AppIcons.edit),
                label: Text(l10n.editPlayerDetails),
              ),
          ],
        ),
        Text(
          l10n.playerDetailsWhoSees,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!details.hasValue && details.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l10n.loadError),
          )
        else if (!details.hasValue)
          const Padding(
            padding: EdgeInsets.all(Space.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (d == null || d.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l10n.playerDetailsEmpty),
          )
        else
          _DetailsList(details: d),
      ],
    );
  }
}

/// What's filled in, with a dash for what isn't.
class _DetailsList extends ConsumerWidget {
  const new({required this.details});

  final PlayerDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = details;
    final born = switch (d.dateOfBirth) {
      final dob? => parseDateOfBirth(dob),
      null => null,
    };
    final age = d.ageAt(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.birthday),
          title: Text(l10n.dateOfBirthLabel),
          // "Mar 3, 2014 · Age 12", with the year (a medium date has none).
          subtitle: Text(
            born == null
                ? '—'
                : [
                    MaterialLocalizations.of(context).formatShortDate(born),
                    if (age != null) l10n.playerAge(age),
                  ].join(' · '),
          ),
        ),
        if (d.emergencyContacts.isEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.call),
            title: Text(l10n.emergencyContactsLabel),
            subtitle: const Text('—'),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Text(
              l10n.emergencyContactsLabel,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          for (final c in d.emergencyContacts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.name),
              subtitle: Text(
                [
                  if (c.relationship?.isNotEmpty ?? false) c.relationship!,
                  c.phone,
                ].join(' · '),
              ),
              // Tap-to-call, through the phone app.
              trailing: IconButton(
                tooltip: l10n.callContact(c.name),
                icon: const Icon(AppIcons.call),
                onPressed: () =>
                    unawaited(ref.read(linkOpenerProvider).open(c.telUri)),
              ),
            ),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.medical),
          title: Text(l10n.medicalNotesLabel),
          subtitle: Text(d.medicalNotes ?? '—'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.notes),
          title: Text(l10n.playerNotesLabel),
          subtitle: Text(d.notes ?? '—'),
        ),
      ],
    );
  }
}
