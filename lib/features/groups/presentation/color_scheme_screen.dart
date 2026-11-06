import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a color scheme (SET-2): my default at `/teams/scheme`, or how I see
/// one team at `/g/:groupId/scheme`. A tap applies it at once; the checked
/// row does nothing.
class ColorSchemeScreen extends ConsumerWidget {
  /// My default: Teams, Profile, and every team I haven't picked for.
  const new defaultScheme({super.key}) : groupId = null;

  /// How I see [groupId]. Everyone on the team picks their own.
  const new team(GroupId this.groupId, {super.key});

  final GroupId? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final id = groupId;
    // A super admin viewing a team they aren't on has no membership to save
    // a pick on: back to Team info (the router does this too, once their
    // teams have loaded).
    if (id != null && ref.watch(viewingAsSuperAdminProvider(id))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/g/${id.value}/info');
      });
      return const Scaffold();
    }
    final group = id == null ? null : ref.watch(groupProvider(id)).value;
    final current = id == null
        ? ref.watch(defaultSchemeControllerProvider)
        : ref.watch(teamSchemeProvider(id));
    final title = id == null ? l10n.defaultColorScheme : l10n.colorScheme;
    final lede = id == null
        ? l10n.defaultColorSchemeLede
        : group?.isGroup ?? false
        ? l10n.colorSchemeGroupLede(group?.name ?? '')
        : l10n.colorSchemeTeamLede(group?.name ?? '');
    final note = id == null
        ? l10n.defaultColorSchemeNote
        : l10n.colorSchemeNote;

    Future<void> pick(TeamScheme scheme) async {
      if (scheme == current) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        if (id == null) {
          await ref.read(defaultSchemeControllerProvider.notifier).set(scheme);
        } else {
          final uid = ref.read(authUserProvider).value?.uid;
          if (uid == null) return;
          await ref
              .read(memberRepositoryProvider)
              .setMyColorScheme(id, UserId(uid), scheme);
        }
      } on Object catch (e) {
        Log.warn('Color scheme save failed', e);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.colorSchemeSaveFailed)),
        );
      }
    }

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: title,
        backLabel: id == null
            ? l10n.tabTeams
            : group?.isGroup ?? false
            ? l10n.groupInfo
            : l10n.teamInfo,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            // Level with the title.
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              6,
              Space.page,
              Space.xl,
            ),
            children: [
              Text(
                lede,
                style: text.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 21 / 15,
                  fontWeight: FontWeight.w600,
                  color: c.textMutedOnPage,
                ),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: c.divider),
              for (final scheme in TeamScheme.values) ...[
                SchemeRow(
                  scheme: scheme,
                  title: scheme.label(l10n),
                  subtitle: scheme.shortLabel(l10n),
                  selected: scheme == current,
                  onTap: () => unawaited(pick(scheme)),
                ),
                Container(height: 1, color: c.divider),
              ],
              const SizedBox(height: 16),
              Text(
                note,
                style: text.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 19 / 14,
                  fontWeight: FontWeight.w600,
                  color: c.textMutedOnPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a scheme's swatch, a title and a line under it: a scheme in
/// the picker ([selected] checks it), or the Default color scheme row on
/// Teams (a chevron).
class SchemeRow extends StatelessWidget {
  const new({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected,
    super.key,
  });

  final TeamScheme scheme;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Null for a row that opens something (a chevron); otherwise whether
  /// it's the picked one (a check).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final picked = selected;
    final row = FocusRingInk(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 69),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SchemeSwatch(scheme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w700,
                        color: c.textOnPage,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 19 / 14,
                        fontWeight: FontWeight.w600,
                        color: c.textMutedOnPage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (picked == null)
                Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  weight: 700,
                  color: c.textMutedOnPage,
                )
              else
                SizedBox(
                  width: 22,
                  child: picked
                      ? Icon(
                          AppIcons.check,
                          size: 22,
                          weight: 800,
                          color: c.you.text,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) {
      return Semantics(
        button: true,
        label: '$title, $subtitle',
        onTap: onTap,
        excludeSemantics: true,
        child: row,
      );
    }
    return Semantics(
      button: true,
      selected: picked,
      inMutuallyExclusiveGroup: true,
      label: '$title, $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: row,
    );
  }
}

/// A little picture of [scheme] (SET-2): its page with a tiny card on it, a
/// coral dot and a line of its text color. Decorative; the row names it.
class SchemeSwatch extends StatelessWidget {
  const new(this.scheme, {super.key});

  final TeamScheme scheme;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(64, 44),
      painter: _SwatchPainter(
        SchemeRoles.of(scheme),
        GumdropColors.of(context).outline,
      ),
    ),
  );
}

class _SwatchPainter extends CustomPainter {
  new(this.roles, this.ring);

  final SchemeRoles roles;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(outer, Paint()..color = roles.page);
    // The tiny card, on its 2 px lip.
    const card = Rect.fromLTWH(9, 10, 46, 20);
    final cardShape = RRect.fromRectAndRadius(card, const Radius.circular(6));
    canvas
      ..drawRRect(
        cardShape.shift(const Offset(0, 2)),
        Paint()..color = roles.cardRim,
      )
      ..drawRRect(cardShape, Paint()..color = roles.card)
      ..drawRRect(
        cardShape.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = roles.cardRim,
      )
      ..drawCircle(
        card.topLeft + const Offset(5 + 3, 5.5 + 3),
        3,
        Paint()..color = CandyFaces.coral,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(card.left + 15, card.top + 6.5, 20, 4),
          const Radius.circular(2),
        ),
        Paint()..color = roles.text,
      )
      // The inset ring in the screen's outline.
      ..drawRRect(
        outer.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ring,
      );
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.roles != roles || old.ring != ring;
}
