import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-1 at `/admin`: the platform's totals, each opening its list. Each
/// is a card across the page in the look of the team cards on Teams (#66,
/// owner's request 2026-11-18): its icon on a badge of its color, the
/// label over a muted line saying what it counts, and the number at the
/// end. One column on a phone, two or three on wider screens.
class AdminDashboardScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final totals = ref.watch(adminTotalsProvider);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return AdminScaffold(
      section: AdminSection.dashboard,
      title: l10n.adminDashboard,
      actions: [
        IconButton(
          tooltip: l10n.retry,
          icon: const Icon(AppIcons.retry),
          onPressed: () => ref.invalidate(adminTotalsProvider),
        ),
      ],
      body: switch (totals) {
        AsyncValue(:final AdminTotals value) => AdminBody(
          children: [
            _StatGrid(
              stats: [
                _Stat(
                  label: l10n.adminStatUsers,
                  note: l10n.adminStatUsersNote,
                  value: number.format(value.users),
                  icon: AppIcons.person,
                  accent: (c) => c.blueRaspberry,
                  route: AdminSection.users.path,
                ),
                _Stat(
                  label: l10n.adminStatTeams,
                  note: l10n.adminStatTeamsNote,
                  value: number.format(value.teams),
                  icon: AppIcons.group,
                  accent: (c) => c.grape,
                  route: AdminSection.teams.path,
                ),
                _Stat(
                  label: l10n.adminStatNewTeams,
                  note: l10n.adminStatNewTeamsNote,
                  value: number.format(value.newTeams),
                  icon: AppIcons.add,
                  accent: (c) => c.mint,
                ),
                _Stat(
                  label: l10n.adminStatActiveTeams,
                  note: l10n.adminStatActiveTeamsNote,
                  value: number.format(value.activeTeams),
                  icon: AppIcons.chat,
                  accent: (c) => c.tangerine,
                ),
                _Stat(
                  label: l10n.adminStatMessages,
                  note: l10n.adminStatMessagesNote,
                  value: number.format(value.messages),
                  icon: AppIcons.send,
                  accent: (c) => c.bubblegum,
                ),
                _Stat(
                  label: l10n.adminStatStorage,
                  note: l10n.adminStatStorageNote,
                  value: formatBytes(value.storageBytes),
                  icon: AppIcons.storage,
                  accent: (c) => c.lemon,
                ),
                // The day's one email budget (#47): its warning color once
                // invites and RSVP emails have stopped, red when it's full.
                // A server from before it sends no budget: no card.
                if (value.emailBudget > 0)
                  _Stat(
                    label: l10n.adminStatEmails,
                    note: l10n.adminStatEmailsNote(
                      number.format(value.emailBulkLimit),
                    ),
                    value: l10n.adminStatEmailsValue(
                      number.format(value.emailsToday),
                      number.format(value.emailBudget),
                    ),
                    icon: AppIcons.email,
                    accent: (c) => value.emailsToday >= value.emailBulkLimit
                        ? c.lemon
                        : c.mint,
                    alert:
                        value.emailBudget > 0 &&
                        value.emailsToday >= value.emailBudget,
                  ),
                _Stat(
                  label: l10n.adminStatOpenReports,
                  note: value.openReports > 0
                      ? l10n.adminStatReportsWaiting
                      : l10n.adminStatReportsNone,
                  value: number.format(value.openReports),
                  icon: AppIcons.report,
                  accent: (c) => c.blueRaspberry,
                  route: AdminSection.reports.path,
                  alert: value.openReports > 0,
                ),
              ],
            ),
          ],
        ),
        AsyncError() => LoadError(
          onRetry: () => ref.invalidate(adminTotalsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The totals in one column on a phone, two from 600 px, and three from
/// 900, the cards in a line the same height.
class _StatGrid extends StatelessWidget {
  const new({required this.stats});

  final List<_Stat> stats;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 900
          ? 3
          : box.maxWidth >= 600
          ? 2
          : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i += columns)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: i + j < stats.length
                            ? stats[i + j]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// One total as a team card (Teams, SPEC §5.1): a 48 px badge with its icon
/// on [accent]'s face, the label in the card's title style over [note], and
/// the number at the end, or under the note with large text. A total with
/// a list ([route]) opens it, with the card's chevron.
class _Stat extends StatelessWidget {
  const new({
    required this.label,
    required this.note,
    required this.value,
    required this.icon,
    required this.accent,
    this.route,
    this.alert = false,
  });

  final String label;

  /// What it counts: "Made in the last 7 days".
  final String note;
  final String value;
  final IconData icon;
  final GumdropAccent Function(GumdropColors colors) accent;
  final String? route;

  /// Open reports waiting (SAFE-4's 24-hour goal): the warning red, on its
  /// badge and its number.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final page = GumdropColors.of(context);
    final c = page.card;
    final style = GumdropStyle.of(context);
    final color = alert ? page.cherry : accent(page);
    final target = route;
    // The number under the words with large text, and a long one ("38 of
    // 90", #47) on the narrowest screens (Slide Over, 320 wide), where it
    // wouldn't fit beside them.
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > 1.5 ||
        (value.length > 6 && MediaQuery.sizeOf(context).width < 340);
    final name = Text(
      label,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        height: 22 / 18,
        color: c.textPrimary,
      ),
    );
    final what = Text(
      note,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 19 / 15,
        letterSpacing: -0.2,
        color: c.textMuted,
      ),
    );
    final total = Text(
      value,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        height: 26 / 22,
        color: alert ? c.cherry.text : c.textPrimary,
      ),
    );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [name, what, if (stacked) total],
    );
    return Semantics(
      // One item each: "New teams: 4. Made in the last 7 days."
      container: true,
      button: target != null,
      label: '$label: $value. $note.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: style.cardDecoration(
            c.surface,
            18,
            side: BorderSide(color: c.surfaceBorder, width: 2),
          ),
          child: FocusRingInk(
            onTap: target == null ? null : () => context.go(target),
            radius: BorderRadius.circular(18),
            child: GumdropSurface(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.face,
                        // The team badge's corners.
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 24, color: c.inkOn(color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: words),
                    if (!stacked) ...[const SizedBox(width: 12), total],
                    const SizedBox(width: 8),
                    // Room kept where there's no list, so the numbers line
                    // up.
                    SizedBox(
                      width: 20,
                      child: target == null
                          ? null
                          : Icon(
                              AppIcons.chevronRight,
                              size: 20,
                              weight: 700,
                              color: c.textMuted,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
