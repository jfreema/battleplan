import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_rules.dart';
import 'package:battleplan/features/plays/presentation/play_board.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// What a new play starts with (BOARD-1): the board, its variant, and the
/// formations on it.
typedef NewPlayChoice = ({
  PlayBoard board,
  BoardVariant variant,
  String? team,
  String? opponent,
});

/// The draft a [choice] starts the editor with.
PlayDraft draftFor(NewPlayChoice choice) {
  Formation? pick(List<Formation> all, String? id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  return (
    board: choice.board,
    variant: choice.variant,
    title: '',
    note: '',
    steps: [
      startingStep(
        pick(teamFormations(choice.board, choice.variant), choice.team),
        pick(opponentFormations(choice.board, choice.variant), choice.opponent),
        ball: ballSpot(choice.board, choice.variant),
      ),
    ],
  );
}

/// The team's saved plays (SPEC §6.16, BOARD-4): every board's, newest
/// change first, with a picture of each. Everyone on the team opens them;
/// coaches save them from the whiteboard.
class SavedPlaysScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plays = ref.watch(teamPlaysProvider(groupId));
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canEdit =
        group != null && canEditPlays(group, me, superAdmin: superAdmin);
    final list = plays.value ?? const <Play>[];
    final Widget body;
    if (plays.isLoading && list.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (list.isEmpty) {
      body = EmptyState(
        art: const PlaysIcon(colorful: true, size: 64),
        message: canEdit ? l10n.playsEmptyAdmin : l10n.playsEmpty,
      );
    } else {
      body = LayoutBuilder(
        builder: (context, box) {
          // A grid of pictures on a tablet or laptop, a list on a phone.
          final columns = (box.maxWidth / 300).floor().clamp(1, 4);
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _PlayCard(groupId: groupId, play: list[i]),
          );
        },
      );
    }
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: canEdit ? l10n.playsSaved : l10n.tabPlays,
      ),
      body: body,
    );
  }
}

class _PlayCard extends StatelessWidget {
  const new({required this.groupId, required this.play});

  final GroupId groupId;
  final Play play;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final updated = play.updatedAt;
    return SettingsPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => unawaited(
          context.push('/g/${groupId.value}/plays/${play.id.value}'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: PlayBoardView(
                    board: play.board,
                    variant: play.variant,
                    elements: play.steps.first.elements,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                play.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: GumdropColors.of(context).textPrimary,
                ),
              ),
              Text(
                [
                  boardName(l10n, play.board),
                  if (play.steps.length > 1)
                    l10n.playStepCount(play.steps.length),
                  if (updated != null)
                    DateFormat.MMMd(Localizations.localeOf(context).toString())
                        .format(updated.toLocal()),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: GumdropColors.of(context).textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks which board a new play starts on, and with which formations
/// (BOARD-1). [suggested] is the team's sport's board.
Future<NewPlayChoice?> showNewPlaySheet(
  BuildContext context,
  PlayBoard suggested,
) => showModalBottomSheet<NewPlayChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _NewPlaySheet(suggested: suggested),
);

class _NewPlaySheet extends StatefulWidget {
  const new({required this.suggested});

  final PlayBoard suggested;

  @override
  State<_NewPlaySheet> createState() => _NewPlaySheetState();
}

class _NewPlaySheetState extends State<_NewPlaySheet> {
  late PlayBoard _board = widget.suggested;
  late BoardVariant _variant = boardVariants(_board).first;
  late String? _team = teamFormations(_board, _variant).firstOrNull?.id;
  String? _opponent;

  void _pickBoard(PlayBoard b) => setState(() {
    _board = b;
    _variant = boardVariants(b).first;
    _team = teamFormations(b, _variant).firstOrNull?.id;
    _opponent = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final teams = teamFormations(_board, _variant);
    final opponents = opponentFormations(_board, _variant);
    final football = _board == PlayBoard.football;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.playNew, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            Text(l10n.playBoard, style: theme.textTheme.titleSmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final b in PlayBoard.values)
                  ChoiceChip(
                    label: Text(boardName(l10n, b)),
                    selected: b == _board,
                    onSelected: (_) => _pickBoard(b),
                  ),
              ],
            ),
            if (boardVariants(_board).length > 1) ...[
              const SizedBox(height: Space.md),
              SegmentedButton<BoardVariant>(
                segments: [
                  for (final v in boardVariants(_board))
                    ButtonSegment(
                      value: v,
                      label: Text(variantName(l10n, _board, v)),
                    ),
                ],
                selected: {_variant},
                onSelectionChanged: (s) => setState(() {
                  _variant = s.first;
                  _team = teamFormations(_board, _variant).firstOrNull?.id;
                }),
              ),
            ],
            if (teams.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String?>(
                initialValue: _team,
                decoration: InputDecoration(
                  labelText: football ? l10n.playOffense : l10n.playYourTeam,
                ),
                items: [
                  DropdownMenuItem(child: Text(l10n.playNobody)),
                  for (final f in teams)
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() => _team = v),
              ),
            ],
            if (opponents.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String?>(
                initialValue: _opponent,
                decoration: InputDecoration(
                  labelText: football ? l10n.playDefense : l10n.playOtherTeam,
                ),
                items: [
                  DropdownMenuItem(child: Text(l10n.playNobody)),
                  for (final f in opponents)
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() => _opponent = v),
              ),
            ],
            const SizedBox(height: Space.md),
            // What it'll look like.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: PlayBoardView(
                board: _board,
                variant: _variant,
                elements: draftFor((
                  board: _board,
                  variant: _variant,
                  team: _team,
                  opponent: _opponent,
                )).steps.first.elements,
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                board: _board,
                variant: _variant,
                team: _team,
                opponent: _opponent,
              )),
              child: Text(l10n.playStart),
            ),
          ],
        ),
      ),
    );
  }
}

/// The board a new play opens with when the editor's address is opened on
/// its own (a reload): the team's sport's, with its first formation.
NewPlayChoice defaultChoice(Sport? sport) {
  final board = boardForSport(sport);
  final variant = boardVariants(board).first;
  return (
    board: board,
    variant: variant,
    team: teamFormations(board, variant).firstOrNull?.id,
    opponent: null,
  );
}
