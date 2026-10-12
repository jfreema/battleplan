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
/// deleted one says so. A series' card whose event is gone shows the
/// series' next event, or, with none left, the series as posted.
/// Tapping opens the event (SCHED-4).
class EventCard extends ConsumerWidget {
  const new({
    required this.eventId,
    required this.groupId,
    this.seriesId,
    this.text = '',
    super.key,
  });

  final EventId eventId;
  final GroupId groupId;

  /// The series a series' card was posted for.
  final String? seriesId;

  /// The card's one-line summary, as the server wrote it.
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    var async = ref.watch(eventProvider(eventId));
    final zone = ref.watch(viewerTimeZoneProvider).value;
    final frame = BoxDecoration(
      color: scheme.surfaceContainerLow,
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(Corners.bubble),
    );
    // The card's event is gone, but its series goes on.
    var seriesLeft = false;
    if (seriesId case final s? when async.hasValue && async.value == null) {
      async = ref.watch(nextSeriesEventProvider(groupId, s));
      final series = ref.watch(eventSeriesProvider(s));
      seriesLeft = series.value != null;
      if (async.hasValue && async.value == null && series.isLoading) {
        async = const AsyncLoading();
      }
    }
    final event = async.value;
    if (event == null || zone == null) {
      final muted = TextStyle(
        fontStyle: FontStyle.italic,
        color: scheme.onSurfaceVariant,
      );
      return Container(
        width: 320,
        padding: const EdgeInsets.all(Space.md),
        decoration: frame,
        child: async.isLoading || zone == null
            ? const LinearProgressIndicator()
            : seriesLeft && text.isNotEmpty
            ? Text(text, style: theme.textTheme.bodyMedium)
            : Text(l10n.eventCardDeleted, style: muted),
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
