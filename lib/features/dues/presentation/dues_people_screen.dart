import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/dues/application/providers.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_widgets.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Who owes what at `/g/:groupId/dues/people` (admins, DUES-5), a tap from
/// Dues: what's owed in all, paid, and left, then each person (a player on
/// a team, a member in a group), who owes most first, with what they owe
/// in all, have paid, and have left, and every due they're on: what it's
/// for, what they've paid, and what's left. A tap on a due opens it, to
/// record a payment. Screen readers hear each row as one sentence ("Luke
/// #7, Uniforms, $25 left of $45").
class DuesPeopleScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final admin = isDuesAdmin(ref, groupId);
    final all = admin ? ref.watch(teamChargesProvider(groupId)) : null;
    final list = all?.value;
    final Widget body;
    if (!admin) {
      body = Center(child: DuesQuiet(l10n.duesPeopleAdminsOnly));
    } else if (list == null) {
      body = (all?.hasError ?? false)
          ? const DuesLoadError()
          : const SkeletonList();
    } else {
      final people = duePeople(list);
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              Text(
                l10n.duesPeopleLede,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 21 / 15,
                  color: c.textMutedOnPage,
                ),
              ),
              const SizedBox(height: 18),
              if (people.isEmpty)
                DuesQuiet(l10n.duesPeopleEmpty)
              else ...[
                DuesTotalsPanel(totals: dueTotals(list)),
                const SizedBox(height: 20),
                for (final p in people) ...[
                  _Person(groupId: groupId, person: p),
                  const SizedBox(height: 20),
                ],
              ],
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.duesWhoOwesWhat,
        backLabel: l10n.duesTitle,
      ),
      body: body,
    );
  }
}

/// One person across every due: their name and what's left, what they've
/// paid of what they owe in all, and a row for each due.
class _Person extends StatelessWidget {
  const new({required this.groupId, required this.person});

  final GroupId groupId;
  final DuePerson person;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    String d(int cents) => formatDues(l10n, cents);
    final t = person.totals;
    final strong = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w800,
      fontSize: 18,
      height: 22 / 18,
      color: c.textOnPage,
    );
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 19 / 14,
      color: c.textMutedOnPage,
    );
    final paidLine = t.chargedCents == 0
        ? l10n.duesAllWaived
        : l10n.duesPaidOfAmount(d(t.paidCents), d(t.chargedCents));
    final spoken = [
      person.name,
      if (t.owedCents > 0)
        l10n.duesLeftOf(d(t.owedCents), d(t.chargedCents))
      else ...[
        l10n.duesNothingLeft,
        paidLine,
      ],
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          label: spoken,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // What's left on the right, or under the name when both
                // don't fit (large text).
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(person.name, style: strong),
                    Text(
                      t.owedCents > 0
                          ? l10n.duesLeft(d(t.owedCents))
                          : l10n.duesNothingLeft,
                      style: t.owedCents > 0 ? strong : muted,
                    ),
                  ],
                ),
                Text(paidLine, style: muted),
              ],
            ),
          ),
        ),
        PageRows(
          children: [
            for (final share in person.shares)
              PageRow(
                title: share.title,
                subtitle: [
                  shareLine(l10n, share),
                  if (share.dueOn case final on? when share.owedCents > 0)
                    dueDateLine(l10n, on, owed: true),
                ].join(' · '),
                subtitleMaxLines: null,
                semanticsLabel: [
                  person.name,
                  share.title,
                  shareSpoken(l10n, share),
                ].join(', '),
                leading: Icon(
                  share.paid ? AppIcons.going : AppIcons.payments,
                  size: 22,
                  color: share.paid ? c.successOnPage : c.textOnPage,
                ),
                trailing: DueStatePill(state: share.state),
                // Back here, to Who owes what.
                onTap: () => unawaited(
                  context.push(
                    '/g/${groupId.value}/dues/${share.dueId}',
                    extra: BackLabel(l10n.duesWhoOwesWhat),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
