import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One of [TeamCard]'s buttons: an outlined pill with an icon.
typedef TeamCardAction = ({IconData icon, String label, VoidCallback onTap});

/// The team's card (SPEC §7.5, a true card): its logo or initials, its
/// name, and its sport (or Group) and member count. On the Team tab it
/// carries [actions] under them, Invite and Dues, as outlined pills that
/// share the card's width (SPEC §5.3); Team settings shows it bare.
class TeamCard extends StatelessWidget {
  const new({required this.group, this.actions = const [], super.key});

  final Group group;
  final List<TeamCardAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SettingsPanel(
      child: Builder(
        // Inside the panel, for the card's colors.
        builder: (context) {
          final c = GumdropColors.of(context);
          final header = Row(
            children: [
              GroupBadge(group: group, size: 56),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardHeading(group.name),
                    Text(
                      [
                        // A basic group has no sport (TEAM-14).
                        if (group.hasPlayers)
                          sportName(l10n, group.sport)
                        else
                          l10n.kindGroup,
                        l10n.membersCount(group.memberCount),
                      ].join(' · '),
                      style: text.bodyMedium?.copyWith(color: c.card.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (actions.isEmpty) return header;
          final style = GumdropButtons.of(context).secondary(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: text.labelLarge,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              // Side by side while each fits, one above the other with
              // large text.
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in actions)
                    LayoutBuilder(
                      builder: (context, box) => ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: _pillWidth(box, actions.length),
                        ),
                        child: OutlinedButton.icon(
                          style: style,
                          onPressed: a.onTap,
                          icon: Icon(a.icon, size: 20),
                          label: Text(a.label),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Each pill's share of the card's width, so [count] of them fill one
  /// row at the usual text size.
  static double _pillWidth(BoxConstraints box, int count) {
    final width = box.maxWidth.isFinite ? box.maxWidth : 0.0;
    return count < 2 ? width : (width - 10 * (count - 1)) / count;
  }
}
