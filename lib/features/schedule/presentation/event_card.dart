import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/presentation/event_row.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// An event in the chat (CHAT-11): its type, title, day and time, and
/// place, kept live, so a canceled event shows struck through and a
/// deleted one says so. Tapping opens the event (SCHED-4).
class EventCard extends ConsumerWidget {
  const new({required this.eventId, required this.groupId, super.key});

  final EventId eventId;
  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final async = ref.watch(eventProvider(eventId));
    final zone = ref.watch(viewerTimeZoneProvider).value;
    final frame = BoxDecoration(
      color: scheme.surfaceContainerLow,
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(Corners.bubble),
    );
    final event = async.value;
    if (event == null || zone == null) {
      return Container(
        width: 320,
        padding: const EdgeInsets.all(Space.md),
        decoration: frame,
        child: async.isLoading || zone == null
            ? const LinearProgressIndicator()
            : Text(
                l10n.eventCardDeleted,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
      );
    }
    final color = typeColor(context, event.type);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.bubble),
        onTap: () => openEvent(context, event),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(Space.md),
          decoration: frame,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(typeIcon(event.type), size: 16, color: color),
                  const SizedBox(width: Space.xs),
                  Text(
                    typeLabel(l10n, event.type),
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                  if (event.isCanceled) ...[
                    const SizedBox(width: Space.sm),
                    const CanceledBadge(),
                  ],
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                event.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: event.isCanceled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              Text(timeRange(l10n, event, zone, withDay: true), style: muted),
              if (event.location case final loc?) Text(loc.label, style: muted),
            ],
          ),
        ),
      ),
    );
  }
}
