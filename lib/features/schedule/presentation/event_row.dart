import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// One event in a schedule list (SCHED-1): the date block on the day's
/// first row, the type's color and icon, the title, time, and place, my
/// answer (one per player on youth teams), and the counts. In "All my
/// teams" it also names the team and, for parents, their players (SCHED-2,
/// PLAYER-9). Canceled events are struck through with a badge (SCHED-7).
class EventRow extends StatelessWidget {
  const new({
    required this.event,
    required this.group,
    required this.viewerZone,
    required this.onTap,
    this.day,
    this.participants = const [],
    this.answers = const {},
    this.showTeam = false,
    super.key,
  });

  final Event event;

  /// The event's team, for Maybe and the team label.
  final Group? group;
  final String viewerZone;
  final VoidCallback onTap;

  /// Shown as the date block on the first event of a day.
  final DateTime? day;

  /// Who I answer for on this team, and my answers by participant ID.
  final List<Participant> participants;
  final Map<String, Rsvp> answers;
  final bool showTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = typeColor(context, event.type);
    final canceled = event.isCanceled;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final allowMaybe = group?.settings.allowMaybe ?? true;
    final players = [
      for (final p in participants)
        if (p.isPlayer) p,
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
          vertical: Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: day == null ? null : _DateBlock(day: day!),
            ),
            const SizedBox(width: Space.md),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Corners.chip),
              ),
              // The type is read out, as it isn't written on the row.
              child: Icon(
                typeIcon(event.type),
                color: color,
                size: 20,
                semanticLabel: typeLabel(l10n, event.type),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTeam && group != null)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: group!.color == null
                                ? AppTokens.brand
                                : Color(group!.color!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Flexible(
                          child: Text(
                            [
                              group!.name,
                              if (players.isNotEmpty)
                                l10n.eventForPlayers(
                                  joinAnd(l10n, [
                                    for (final p in players)
                                      p.name.split(' ').first,
                                  ]),
                                ),
                            ].join(' · '),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: canceled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canceled) ...[
                        const SizedBox(width: Space.sm),
                        const CanceledBadge(),
                      ],
                    ],
                  ),
                  Text(timeRange(l10n, event, viewerZone), style: muted),
                  if (event.location case final loc?)
                    Text(
                      loc.label,
                      style: muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (event.takesRsvps) ...[
                    if (participants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.xs,
                          children: [
                            for (final p in participants)
                              _MyAnswer(
                                label: participants.length > 1 || p.isPlayer
                                    ? (p.isPlayer
                                          ? p.name.split(' ').first
                                          : l10n.eventYou)
                                    : null,
                                status: answers[p.id]?.status,
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(
                        countsText(
                          l10n,
                          event.rsvpCounts,
                          allowMaybe: allowMaybe,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "OCT" over "13".
class _DateBlock extends StatelessWidget {
  const new({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: dayLabel(l10n, day),
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            DateFormat.MMM(l10n.localeName).format(day).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${day.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            DateFormat.E(l10n.localeName).format(day),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// My answer on a row: "Emma: Going", or "No response".
class _MyAnswer extends StatelessWidget {
  const new({required this.label, required this.status});

  final String? label;
  final RsvpStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = status;
    final text = s == null ? l10n.rsvpNoResponse : statusLabel(l10n, s);
    final color = s == null
        ? theme.colorScheme.onSurfaceVariant
        : statusColor(context, s);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s != null) ...[
          Icon(statusIcon(s), size: 16, color: color),
          const SizedBox(width: 2),
        ],
        // Wraps rather than overflowing with large text (SPEC §7.6).
        Flexible(
          child: Text(
            label == null ? text : '$label: $text',
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// The red "Canceled" badge (SCHED-7).
class CanceledBadge extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Text(
        AppLocalizations.of(context).eventCanceled,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
