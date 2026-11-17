import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/team_setup.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Puts away [groupId]'s setup card for me (TEAM-1, #3), on every device:
/// its X, its Done, or leaving the chat once it said the team is ready. A
/// failed save is logged, and the card stays until a later one works.
Future<void> closeTeamSetup(WidgetRef ref, GroupId groupId) async {
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) return;
  final members = ref.read(memberRepositoryProvider);
  try {
    await members.closeMySetup(groupId, UserId(uid));
  } on Object catch (e) {
    Log.warn('Putting away the setup card failed', e);
  }
}

/// The setup card at the top of a new team's chat (TEAM-1, #3; owner's go
/// 2026-11-16): "Get Hornets ready", then the steps in the order to do
/// them, Add your players, Invite families, and Add your first practice or
/// game, each opening its screen, and a quiet link to Import. A group's
/// has no players step and says it in group words (TEAM-14).
///
/// The steps tick themselves off ([setup]); the first one not done is the
/// only coral thing on it. With every step done it says "Hornets is
/// ready", with Done. The X ([onClose]) puts it away. Built from the app's
/// own pieces: a true card ([SettingsPanel]) of rows ([PageRow]).
class TeamSetupCard extends ConsumerWidget {
  const new({
    required this.groupId,
    required this.setup,
    required this.onClose,
    super.key,
  });

  final GroupId groupId;
  final TeamSetup setup;

  /// The X, and Done once it's ready.
  final VoidCallback onClose;

  /// Opens what [step] asks for, coming back to the chat.
  void _open(BuildContext context, WidgetRef ref, SetupStep step) {
    final l10n = AppLocalizations.of(context);
    final id = groupId.value;
    final back = BackLabel(l10n.tabChat);
    switch (step) {
      case SetupStep.players:
        unawaited(context.push('/g/$id/players/add', extra: back));
      case SetupStep.invite:
        unawaited(context.push('/g/$id/invite', extra: back));
      case SetupStep.event:
        // As the schedule's + does it: full storage stops new events, and
        // says why (STORE-4).
        final full = ref.read(
          groupProvider(groupId).select((g) => g.value?.storageFull ?? false),
        );
        if (full) {
          showStorageFull(context);
        } else {
          unawaited(context.push('/g/$id/schedule/new'));
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(
      groupProvider(groupId).select((g) => g.value?.name ?? ''),
    );
    final ready = setup.ready;
    final group = setup.group;
    final next = setup.next;
    return SettingsPanel(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 8),
      child: Builder(
        // Inside the panel, for the card's colors.
        builder: (context) {
          final c = GumdropColors.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: ready ? 10 : 0),
                      child: CardHeading(
                        ready
                            ? l10n.teamSetupReady(name)
                            : l10n.teamSetupTitle(name),
                      ),
                    ),
                  ),
                  // Done says it once the team's ready.
                  if (!ready)
                    IconButton(
                      tooltip: l10n.teamSetupHide,
                      icon: Icon(AppIcons.close, color: c.textMuted),
                      onPressed: onClose,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: PageRows(
                  children: [
                    for (final step in setup.steps)
                      _StepRow(
                        title: _title(l10n, step, group: group),
                        subtitle: switch (step) {
                          SetupStep.players => l10n.teamSetupPlayersHint,
                          SetupStep.invite => l10n.teamSetupInviteHint,
                          SetupStep.event => null,
                        },
                        done: setup.isDone(step),
                        next: step == next,
                        onTap: () => _open(context, ref, step),
                      ),
                  ],
                ),
              ),
              if (ready)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 10, 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      style: GumdropButtons.of(context).accent(c.you),
                      onPressed: onClose,
                      child: Text(l10n.done),
                    ),
                  ),
                )
              else
                // Quiet: Import stays in Team settings (Option B); this
                // only links to it.
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 10),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: GumdropButtons.of(context).link(),
                      onPressed: () => unawaited(
                        context.push(
                          '/g/${groupId.value}/import',
                          extra: BackLabel(l10n.tabChat),
                        ),
                      ),
                      child: Text(
                        group
                            ? l10n.teamSetupImportGroup
                            : l10n.teamSetupImport,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _title(
    AppLocalizations l10n,
    SetupStep step, {
    required bool group,
  }) => switch (step) {
    SetupStep.players => l10n.teamSetupPlayers,
    SetupStep.invite =>
      group ? l10n.teamSetupInviteGroup : l10n.teamSetupInvite,
    SetupStep.event => group ? l10n.teamSetupEventGroup : l10n.teamSetupEvent,
  };
}

/// One step: its circle (empty, coral for the one to do next, or a mint
/// check once done), its name and hint, and a chevron. A done step goes
/// muted and still opens its screen. Screen readers hear "Add your
/// players, not done" or "done", then the hint.
class _StepRow extends StatelessWidget {
  const new({
    required this.title,
    required this.done,
    required this.next,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final bool next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final state = done
        ? l10n.teamSetupStepDone(title)
        : l10n.teamSetupStepToDo(title);
    return PageRow(
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 3,
      leading: _StepMark(done: done, next: next),
      titleColor: done ? c.textMuted : null,
      bold: next,
      semanticsLabel: [state, ?subtitle].join(', '),
      onTap: onTap,
    );
  }
}

/// A step's 24 px circle: a 2 px ring in the card's outline, in coral for
/// the step to do next, or once done a mint disc with a check, as "Sent"
/// draws it (CHAT-4).
class _StepMark extends StatelessWidget {
  const new({required this.done, required this.next});

  final bool done;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return SizedBox.square(
      dimension: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? c.mint.face : null,
          border: done
              ? null
              : Border.all(
                  color: next ? c.you.face : c.outline,
                  width: next ? 2.5 : 2,
                ),
        ),
        child: done
            ? Icon(AppIcons.check, size: 17, weight: 800, color: c.ink)
            : null,
      ),
    );
  }
}

/// The setup card where it sits in the chat: at the top of the history,
/// as wide as a message can be (520) and centered, inside the page's
/// gutter.
class TeamSetupCardSlot extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, Space.md, gutter, Space.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }
}
