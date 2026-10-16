import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/calendar_link.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Calendar link (SCHED-11), from the team menu: a private link that keeps
/// Google, Apple, or Outlook Calendar in sync with this team's schedule,
/// or with every team's. Made when asked; reset or turned off here.
class CalendarLinkScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<CalendarLinkScreen> createState() => _CalendarLinkState();
}

class _CalendarLinkState extends ConsumerState<CalendarLinkScreen> {
  /// Showing the link for all my teams rather than this team's.
  bool _allTeams = false;
  bool _busy = false;

  /// The team the link on show is for; null for all my teams.
  GroupId? get _scope => _allTeams ? null : widget.groupId;

  Future<void> _set(CalendarLinkAction action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(calendarLinkRepositoryProvider).set(_scope, action);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.calendarLinkFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Reset or Turn off, after asking: calendars on the old link stop.
  Future<void> _confirm(CalendarLinkAction action) async {
    final l10n = AppLocalizations.of(context);
    final reset = action == CalendarLinkAction.reset;
    final ok = await showConfirmDialog(
      context,
      title: reset ? l10n.calendarLinkResetTitle : l10n.calendarLinkOffTitle,
      message: reset ? l10n.calendarLinkResetBody : l10n.calendarLinkOffBody,
      confirmLabel: reset
          ? l10n.calendarLinkResetConfirm
          : l10n.calendarLinkOff,
      cancelLabel: l10n.cancel,
      destructive: !reset,
    );
    if (ok && mounted) await _set(action);
  }

  Future<void> _open(Uri uri) async {
    final l10n = AppLocalizations.of(context);
    final opened = await ref.read(linkOpenerProvider).open(uri);
    if (!opened && mounted) showAppSnackBar(context, l10n.eventCalendarFailed);
  }

  Future<void> _copy(Uri uri) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (mounted) showAppSnackBar(context, l10n.linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (ref.watch(myMembershipProvider(widget.groupId)) == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.calendarLinkTitle)),
        body: EmptyState(icon: AppIcons.group, message: l10n.notAMember),
      );
    }
    final team = ref.watch(groupProvider(widget.groupId)).value?.name ?? '';
    final teamCount = ref.watch(scheduleTeamsProvider).length;
    final links = ref.watch(myCalendarLinksProvider);
    final link = links.value?.where((l) => l.groupId == _scope).firstOrNull;
    final service = ref.watch(linkServiceProvider);
    // webcal:// opens Calendar on an iPhone, iPad, or Mac, in the app or in
    // a browser; elsewhere it opens nothing.
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    List<Widget> linkActions(CalendarLink link) {
      // The name a new calendar gets: the team's, or the server's own name
      // for all teams.
      final name = _allTeams ? 'Battleplan' : team;
      final fetched = link.fetchedAt?.toLocal();
      final adds = [
        (l10n.calendarLinkGoogle, service.googleCalendarAdd(link.token)),
        if (apple) (l10n.calendarLinkApple, service.calendarWebcal(link.token)),
        (l10n.calendarLinkOutlook, service.outlookAdd(link.token, name)),
      ];
      return [
        for (final (label, uri) in adds) ...[
          FilledButton.tonalIcon(
            onPressed: () => unawaited(_open(uri)),
            icon: const Icon(AppIcons.addToCalendar),
            label: Text(label),
          ),
          const SizedBox(height: Space.sm),
        ],
        OutlinedButton.icon(
          onPressed: () => unawaited(_copy(service.calendarFeed(link.token))),
          icon: const Icon(AppIcons.copy),
          label: Text(l10n.calendarLinkCopy),
        ),
        const SizedBox(height: Space.xl),
        Text(l10n.calendarLinkSync, style: muted),
        const SizedBox(height: Space.sm),
        Text(l10n.calendarLinkGooglePhone, style: muted),
        const SizedBox(height: Space.sm),
        Text(
          fetched == null
              ? l10n.calendarLinkNotChecked
              : l10n.calendarLinkChecked(
                  DateFormat.MMMMd(l10n.localeName).format(fetched),
                  DateFormat.jm(l10n.localeName).format(fetched),
                ),
          style: muted,
        ),
        const SizedBox(height: Space.xl),
        Text(l10n.calendarLinkPrivate),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          children: [
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => unawaited(_confirm(CalendarLinkAction.reset)),
              icon: const Icon(AppIcons.retry),
              label: Text(l10n.calendarLinkReset),
            ),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => unawaited(_confirm(CalendarLinkAction.off)),
              icon: const Icon(AppIcons.close),
              label: Text(l10n.calendarLinkOff),
            ),
          ],
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarLinkTitle)),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
          vertical: Space.lg,
        ),
        children: [
          if (teamCount > 1) ...[
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(team, overflow: TextOverflow.ellipsis),
                ),
                ButtonSegment(value: true, label: Text(l10n.scheduleAllTeams)),
              ],
              selected: {_allTeams},
              onSelectionChanged: (choice) =>
                  setState(() => _allTeams = choice.first),
            ),
            const SizedBox(height: Space.lg),
          ],
          Text(
            _allTeams
                ? l10n.calendarLinkIntroAll
                : l10n.calendarLinkIntroTeam(team),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Space.lg),
          if (!links.hasValue)
            const Center(child: CircularProgressIndicator())
          else if (link == null)
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => unawaited(_set(CalendarLinkAction.make)),
              icon: const Icon(AppIcons.calendarLink),
              label: Text(l10n.calendarLinkMake),
            )
          else
            ...linkActions(link),
        ],
      ),
    );
  }
}
