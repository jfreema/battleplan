import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/color_scheme_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Team admin → Team color scheme (SET-2, owner's request 2026-11-08): the
/// team's default color scheme, set by its admins (and super admins), which
/// everyone who hasn't picked their own in Team info → Color scheme sees.
/// None is checked until one is set.
class TeamSchemeSection extends StatelessWidget {
  const new({required this.group, required this.onPick, super.key});

  final Group group;

  /// Saves [TeamScheme] as the team's default.
  final Future<void> Function(TeamScheme scheme) onPick;

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
        if (current == null) ...[
          const SizedBox(height: 8),
          Text(l10n.teamDefaultSchemeNone, style: muted),
        ],
      ],
    );
  }
}
