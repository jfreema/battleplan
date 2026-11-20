import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/color_scheme_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Admin settings → Team color scheme (SET-2, owner's request 2026-11-08): the
/// team's default color scheme, set by its admins (and super admins), which
/// everyone who hasn't picked their own in Team settings → Color scheme sees.
///
/// The first row is System default (#73, owner's request 2026-11-20): no
/// team default, so each member sees their own default; it's checked until
/// one is set. Under the six, Reset for everyone takes back every member's
/// own pick, so they all see what's checked here, and can pick again.
class TeamSchemeSection extends StatelessWidget {
  const new({
    required this.group,
    required this.mine,
    required this.onPick,
    required this.onReset,
    super.key,
  });

  final Group group;

  /// My own default, which the System default row shows: what I'd see.
  final TeamScheme mine;

  /// Saves the team's default, or with null System default (none).
  final Future<void> Function(TeamScheme? scheme) onPick;

  /// Reset for everyone, which asks first.
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: c.textMutedOnPage);
    final current = group.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          group.isGroup
              ? l10n.groupDefaultSchemeIntro(group.name)
              : l10n.teamDefaultSchemeIntro(group.name),
          style: muted,
        ),
        const SizedBox(height: 10),
        Container(height: 1, color: c.divider),
        SchemeRow(
          scheme: mine,
          title: l10n.teamSchemeSystemDefault,
          subtitle: l10n.teamSchemeSystemDefaultSubtitle,
          selected: current == null,
          onTap: () {
            if (current != null) unawaited(onPick(null));
          },
        ),
        Container(height: 1, color: c.divider),
        for (final scheme in TeamScheme.values) ...[
          SchemeRow(
            scheme: scheme,
            title: scheme.label(l10n),
            subtitle: scheme.shortLabel(l10n),
            selected: scheme == current,
            onTap: () {
              if (scheme != current) unawaited(onPick(scheme));
            },
          ),
          Container(height: 1, color: c.divider),
        ],
        const SizedBox(height: 24),
        Text(
          group.isGroup
              ? l10n.resetSchemesHelpGroup(group.name)
              : l10n.resetSchemesHelp(group.name),
          style: muted,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            icon: const Icon(AppIcons.reset),
            label: Text(l10n.resetSchemesButton),
            onPressed: () => unawaited(onReset()),
          ),
        ),
      ],
    );
  }
}
