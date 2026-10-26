import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Answers [event] from the schedule list without opening it (SCHED-4,
/// the owner's request 2026-10-26): a sheet on phones, or a panel under
/// [anchor] (the answer that was tapped) on wide screens, with the event
/// page's answer buttons. [rsvpRange] is the "My RSVPs" window the list
/// already listens to, so the answers are there at once.
Future<void> showRsvpSheet(
  BuildContext context,
  Event event, {
  required ({DateTime? from, DateTime? until}) rsvpRange,
  BuildContext? anchor,
}) => showAdaptiveSheet<void>(
  context,
  anchor: anchor,
  builder: (_) => RsvpSheet(event: event, rsvpRange: rsvpRange),
);

/// "Are you going?" for one event: All my players when I answer for two or
/// more, then a row for each person I answer for, with Maybe only where the
/// team allows it, Clear, and a note, as on the event's page; and See event.
class RsvpSheet extends ConsumerWidget {
  const new({required this.event, required this.rsvpRange, super.key});

  final Event event;
  final ({DateTime? from, DateTime? until}) rsvpRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final g = event.groupId;
    final allowMaybe =
        ref.watch(groupProvider(g)).value?.settings.allowMaybe ?? true;
    final zone = ref.watch(viewerTimeZoneProvider).value ?? event.timeZone;
    final mine = ref.watch(myParticipantsProvider(g));
    final answers =
        ref
            .watch(
              myRsvpsProvider(g, from: rsvpRange.from, until: rsvpRange.until),
            )
            .value?[event.id.value] ??
        const <String, Rsvp>{};
    final players = [
      for (final p in mine)
        if (p.isPlayer) p,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.xs,
        Space.lg,
        Space.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.eventAreYouGoing, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(event.title, style: theme.textTheme.titleMedium),
          Text(
            '${dayLabel(l10n, dayOf(event, zone))} · '
            '${timeRange(l10n, event, zone)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (players.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: SameAnswerButtons(
                event: event,
                players: players,
                answerOf: (id) => answers[id],
                enabled: true,
                allowMaybe: allowMaybe,
              ),
            ),
          for (final p in mine)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: RsvpButtons(
                event: event,
                participant: p,
                answer: answers[p.id],
                label: rsvpRowLabel(l10n, p, mine.length),
                enabled: true,
                allowMaybe: allowMaybe,
              ),
            ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openEvent(context, event);
              },
              child: Text(l10n.rsvpSeeEvent),
            ),
          ),
        ],
      ),
    );
  }
}
