import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/season.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// TEAM-16 at `/g/:groupId/season` (the owner): a new team for the next
/// season, with this one's logo, color, sport, settings, chat look, and
/// default reminders, and the people the owner checks, all checked to
/// start; the documents and saved plays come when asked. This team is then
/// archived, with its chat, photos, schedule, and results kept.
class NewSeasonScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<NewSeasonScreen> createState() => _NewSeasonScreenState();
}

class _NewSeasonScreenState extends ConsumerState<NewSeasonScreen> {
  /// This screen's attempt, the same on every retry, so a first request
  /// that arrives late and a retry make one season between them.
  final String _requestId = newRequestId();

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  SeasonChoices _choices = const SeasonChoices();
  bool _named = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start(Group group) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final ok = await showConfirmDialog(
      context,
      title: l10n.newSeasonConfirmTitle(name),
      message: l10n.newSeasonConfirmBody(group.name),
      confirmLabel: l10n.newSeasonConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final made = await ref
          .read(groupRepositoryProvider)
          .startNewSeason(
            group.id,
            name: name,
            // A group has no players or plays (TEAM-14).
            choices: group.hasPlayers
                ? _choices
                : _choices.copyWith(players: false, plays: false),
            requestId: _requestId,
          );
      if (!mounted) return;
      showAppSnackBar(
        context,
        made.leftOut > 0
            ? l10n.newSeasonLeftOut(name, made.leftOut)
            : l10n.newSeasonReady(name),
      );
      context.go('/g/${made.groupId.value}/chat');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e) {
          EmailNotVerified() => l10n.createTeamNeedsVerifiedEmail,
          RateLimited() => l10n.createTeamRateLimited,
          TooManyTeams() => l10n.tooManyTeams,
          PermissionDenied(message: 'group-creation-off') =>
            l10n.createTeamTurnedOff,
          PermissionDenied(message: 'team-archived') => l10n.teamArchived,
          PermissionDenied() => l10n.notAllowed,
          Offline() => l10n.signInOffline,
          _ => l10n.newSeasonFailed,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final group = ref.watch(groupProvider(widget.groupId)).value;
    if (group == null) {
      return Scaffold(appBar: gumdropAppBar(context, title: l10n.newSeason));
    }
    if (!_named) {
      _name.text = group.name;
      _named = true;
    }
    // Who each box brings, counted the way the server sorts people.
    final roster = ref.watch(rosterProvider(group.id)).value ?? const [];
    final players = group.hasPlayers
        ? ref.watch(playersProvider(group.id)).value ?? const <Player>[]
        : const <Player>[];
    final links = group.hasPlayers
        ? ref.watch(guardianLinksProvider(group.id)).value ??
              const <GuardianLink>[]
        : const <GuardianLink>[];
    final active = {for (final p in players) p.id};
    final linked = {
      for (final l in links)
        if (active.contains(l.playerId)) l.uid,
    };
    int count(SeasonGroup kind) => roster
        .where((m) => seasonGroupOf(m, linked: linked.contains(m.uid)) == kind)
        .length;

    final c = GumdropColors.of(context);
    final error = _error;
    Widget check({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
      String? subtitle,
    }) => CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title, style: switchRowTitle(context)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: c.card.textMuted,
              ),
            ),
      value: value,
      onChanged: _saving ? null : (v) => onChanged(v ?? false),
    );

    return Scaffold(
      appBar: gumdropAppBar(context, title: l10n.newSeason),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
              children: [
                SettingsPanel(
                  radius: Corners.panel,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  child: Builder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.newSeasonIntro(group.name),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: GumdropColors.of(context).textMuted,
                          ),
                        ),
                        const SizedBox(height: 9),
                        LabeledField(
                          label: l10n.newSeasonName,
                          child: TextFormField(
                            controller: _name,
                            maxLength: Limits.groupNameMax,
                            textCapitalization: TextCapitalization.words,
                            style: gumdropFieldText(context),
                            decoration: gumdropField(),
                            validator: (v) {
                              final name = (v ?? '').trim();
                              if (name.isEmpty) return l10n.teamNameRequired;
                              return name == group.name.trim()
                                  ? l10n.newSeasonNameSame
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PageHeading(l10n.newSeasonWho),
                const SizedBox(height: 10),
                SettingsCard(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  children: [
                    if (group.hasPlayers)
                      check(
                        title: l10n.newSeasonPlayers,
                        subtitle: l10n.newSeasonPlayersCount(players.length),
                        value: _choices.players,
                        onChanged: (v) => setState(
                          () => _choices = _choices.copyWith(players: v),
                        ),
                      ),
                    check(
                      title: group.hasPlayers
                          ? l10n.newSeasonStaff
                          : l10n.newSeasonAdmins,
                      subtitle: l10n.newSeasonPeople(count(SeasonGroup.staff)),
                      value: _choices.staff,
                      onChanged: (v) => setState(
                        () => _choices = _choices.copyWith(staff: v),
                      ),
                    ),
                    check(
                      title: l10n.newSeasonOthers,
                      subtitle: l10n.newSeasonPeople(count(SeasonGroup.others)),
                      value: _choices.members,
                      onChanged: (v) => setState(
                        () => _choices = _choices.copyWith(members: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.newSeasonWhoHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textMutedOnPage,
                  ),
                ),
                const SizedBox(height: 18),
                PageHeading(l10n.newSeasonAlso),
                const SizedBox(height: 10),
                SettingsCard(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  children: [
                    check(
                      title: l10n.newSeasonDocuments,
                      subtitle: l10n.newSeasonDocumentsHelp,
                      value: _choices.documents,
                      onChanged: (v) => setState(
                        () => _choices = _choices.copyWith(documents: v),
                      ),
                    ),
                    if (group.hasPlayers)
                      check(
                        title: l10n.newSeasonPlays,
                        value: _choices.plays,
                        onChanged: (v) => setState(
                          () => _choices = _choices.copyWith(plays: v),
                        ),
                      ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: _saving || group.isArchived
                      ? null
                      : () => unawaited(_start(group)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Copying a big team's files can take a while.
                      if (_saving) ...[
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(child: Text(l10n.newSeasonStart)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
