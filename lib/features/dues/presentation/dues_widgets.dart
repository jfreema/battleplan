import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// [cents] as dollars: "$45" or "$45.50" (US only, DUES-1).
String formatDues(AppLocalizations l10n, int cents) {
  final whole = cents % 100 == 0;
  return NumberFormat.simpleCurrency(
    locale: 'en_US',
    name: 'USD',
    decimalDigits: whole ? 0 : 2,
  ).format(cents / 100);
}

/// "Nov 30" for a day stored as "2026-11-30".
String duesDay(AppLocalizations l10n, String day) {
  final d = DateTime.tryParse(day);
  return d == null ? day : DateFormat.MMMd(l10n.localeName).format(d);
}

/// "Due Nov 30", or "Overdue since Nov 30" once the day has passed with
/// something still [owed] (DUES-2).
String dueDateLine(AppLocalizations l10n, String dueOn, {required bool owed}) =>
    owed && duePassed(dueOn, DateTime.now())
    ? l10n.duesOverdue(duesDay(l10n, dueOn))
    : l10n.duesDueOn(duesDay(l10n, dueOn));

/// Whether I see and change every due on [groupId] (DUES-4): its admins,
/// and super admins.
bool isDuesAdmin(WidgetRef ref, GroupId groupId) =>
    (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
    (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);

/// Shown where a list couldn't load, rather than a skeleton forever.
class DuesLoadError extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: AppIcons.error,
    message: AppLocalizations.of(context).loadError,
  );
}

/// A share's state in a word or two (DUES-2): Owes, Partly paid, Paid, or
/// Waived.
String shareStateName(AppLocalizations l10n, DueShareState s) => switch (s) {
  DueShareState.owes => l10n.duesStatusOwed,
  DueShareState.partlyPaid => l10n.duesStatusPartly,
  DueShareState.paid => l10n.duesStatusPaid,
  DueShareState.waived => l10n.duesStatusWaived,
};

/// Where a share stands, for its row (DUES-2): "$45", "$20 of $45 paid ·
/// $25 left", "$45 paid", or on a waived share with some paid, "$20 of $45
/// paid · rest waived".
String shareLine(AppLocalizations l10n, DueCharge c) {
  String d(int cents) => formatDues(l10n, cents);
  return switch (c.state) {
    DueShareState.owes => d(c.amountCents),
    DueShareState.partlyPaid => [
      l10n.duesPaidOfAmount(d(c.paidCents), d(c.amountCents)),
      l10n.duesLeft(d(c.owedCents)),
    ].join(' · '),
    DueShareState.paid => l10n.duesAmountPaid(d(c.amountCents)),
    DueShareState.waived when c.paidCents > 0 => [
      l10n.duesPaidOfAmount(d(c.paidCents), d(c.amountCents)),
      l10n.duesRestWaived,
    ].join(' · '),
    DueShareState.waived => d(c.amountCents),
  };
}

/// The same in words, for a screen reader's sentence: "owes $45", "$25
/// left of $45", "$45 paid", "Waived".
String shareSpoken(AppLocalizations l10n, DueCharge c) {
  String d(int cents) => formatDues(l10n, cents);
  return switch (c.state) {
    DueShareState.owes => l10n.duesOwesAmount(d(c.amountCents)),
    DueShareState.partlyPaid => l10n.duesLeftOf(
      d(c.owedCents),
      d(c.amountCents),
    ),
    DueShareState.paid => l10n.duesAmountPaid(d(c.amountCents)),
    DueShareState.waived when c.paidCents > 0 =>
      '${l10n.duesAmountPaid(d(c.paidCents))}, ${l10n.duesRestWaived}',
    DueShareState.waived => l10n.duesStatusWaived,
  };
}

/// Muted text on a card or the page: Nunito 600 15/19.
TextStyle duesMuted(GumdropColors c) => TextStyle(
  fontFamily: AppFonts.body,
  fontWeight: FontWeight.w600,
  fontSize: 15,
  height: 19 / 15,
  color: c.textMuted,
);

/// A quiet line on the page.
class DuesQuiet extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: GumdropColors.of(context).textMutedOnPage,
      ),
    ),
  );
}

/// A share's state as a pill (DUES-2): Paid in mint, Partly paid in lemon,
/// Owes in coral, Waived quiet.
class DueStatePill extends StatelessWidget {
  const new({required this.state, super.key});

  final DueShareState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final (face, text) = switch (state) {
      DueShareState.paid => (c.mint.face, c.ink),
      DueShareState.partlyPaid => (c.lemon.face, c.ink),
      DueShareState.owes => (c.cherry.face, c.ink),
      DueShareState.waived => (null, c.textMutedOnPage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(12),
        border: face == null ? Border.all(color: c.outline, width: 1.5) : null,
      ),
      child: Text(
        shareStateName(l10n, state),
        style: GumdropStyle.of(context).label(
          TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 16 / 13,
            color: text,
          ),
        ),
      ),
    );
  }
}

/// A bar [width] wide and 5 tall, mint for what's paid.
class DuesBar extends StatelessWidget {
  const new({required this.fraction, this.width = 40, super.key});

  final double fraction;

  /// Null to fill the width it's given.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: width ?? double.infinity,
          height: 5,
          child: ColoredBox(
            color: c.cardTrack,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0, 1),
                heightFactor: 1,
                child: ColoredBox(color: c.mint.face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What's owed in all, paid, and left, across [totals]' shares (DUES-5),
/// on a card, with a bar for what's paid. Screen readers hear it as one
/// sentence. With [onWhoOwesWhat], a row under it opens Who owes what.
class DuesTotalsPanel extends StatelessWidget {
  const new({required this.totals, this.onWhoOwesWhat, super.key});

  final DueTotals totals;
  final VoidCallback? onWhoOwesWhat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String d(int cents) => formatDues(l10n, cents);
    final open = onWhoOwesWhat;
    return SettingsPanel(
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (context) {
          final c = GumdropColors.of(context);
          Widget figure(String label, int cents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  height: 15 / 12,
                  letterSpacing: 12 * 0.1,
                  color: c.textMuted,
                ),
              ),
              Text(
                d(cents),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 28 / 22,
                  color: c.textPrimary,
                ),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: l10n.duesTotalsSentence(
                  d(totals.chargedCents),
                  d(totals.paidCents),
                  d(totals.owedCents),
                ),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          figure(l10n.duesOwedInAll, totals.chargedCents),
                          figure(l10n.duesPaidInAll, totals.paidCents),
                          figure(l10n.duesLeftInAll, totals.owedCents),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DuesBar(
                        width: null,
                        fraction: totals.chargedCents == 0
                            ? 0
                            : totals.paidCents / totals.chargedCents,
                      ),
                    ],
                  ),
                ),
              ),
              if (open != null) ...[
                Container(height: 1, color: c.divider),
                MergeSemantics(
                  child: Semantics(
                    button: true,
                    child: FocusRingInk(
                      onTap: open,
                      radius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.roster,
                                size: 22,
                                color: c.textPrimary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.duesWhoOwesWhat,
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        height: 21 / 16,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      l10n.duesWhoOwesWhatSub,
                                      style: duesMuted(c)
                                          .copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                AppIcons.chevronRight,
                                size: 20,
                                weight: 700,
                                color: c.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
