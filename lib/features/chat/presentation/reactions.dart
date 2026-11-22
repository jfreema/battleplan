import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The 16 reactions in picker order (CHAT-6): the main four, then the
/// rest.
const List<Reaction> reactionOrder = [
  Reaction.like,
  Reaction.love,
  Reaction.dislike,
  Reaction.laugh,
  Reaction.fire,
  Reaction.clap,
  Reaction.party,
  Reaction.hundred,
  Reaction.pray,
  Reaction.wow,
  Reaction.sad,
  Reaction.angry,
  Reaction.baseball,
  Reaction.basketball,
  Reaction.soccer,
  Reaction.trophy,
];

String reactionEmoji(Reaction r) => switch (r) {
  Reaction.like => '👍',
  Reaction.love => '❤️',
  Reaction.dislike => '👎',
  Reaction.laugh => '😂',
  Reaction.fire => '🔥',
  Reaction.clap => '👏',
  Reaction.party => '🎉',
  Reaction.hundred => '💯',
  Reaction.pray => '🙏',
  Reaction.wow => '😮',
  Reaction.sad => '😢',
  Reaction.angry => '😡',
  Reaction.baseball => '⚾',
  Reaction.basketball => '🏀',
  Reaction.soccer => '⚽',
  Reaction.trophy => '🏆',
};

/// [r]'s emoji, with ❤️ drawn in [heart] (the scheme's red, as a heart
/// always looks): some
/// fonts, the web's among them, only have a plain black heart, which the
/// color tints.
TextSpan reactionSpan(Reaction r, {Color? heart}) => TextSpan(
  text: reactionEmoji(r),
  style: r == Reaction.love && heart != null ? TextStyle(color: heart) : null,
);

String reactionName(AppLocalizations l10n, Reaction r) => switch (r) {
  Reaction.like => l10n.reactionLike,
  Reaction.love => l10n.reactionLove,
  Reaction.dislike => l10n.reactionDislike,
  Reaction.laugh => l10n.reactionLaugh,
  Reaction.fire => l10n.reactionFire,
  Reaction.clap => l10n.reactionClap,
  Reaction.party => l10n.reactionParty,
  Reaction.hundred => l10n.reactionHundred,
  Reaction.pray => l10n.reactionPray,
  Reaction.wow => l10n.reactionWow,
  Reaction.sad => l10n.reactionSad,
  Reaction.angry => l10n.reactionAngry,
  Reaction.baseball => l10n.reactionBaseball,
  Reaction.basketball => l10n.reactionBasketball,
  Reaction.soccer => l10n.reactionSoccer,
  Reaction.trophy => l10n.reactionTrophy,
};

/// How many of [reactionOrder] lead the picker on their own row.
const _mainReactions = 4;

/// The reactions at the top of the message menu (CHAT-6): the main four on
/// one row, then the other 12 in two rows of 6, or three of 4 where 6
/// won't fit (a narrow screen with large text). Every emoji sits in an
/// equal cell, so they line up in columns with no ragged last row (#19,
/// 2026-11-16: a wrap made rows of 8 and 4 at 390 px, 7 and 5 at 360).
class ReactionPicker extends StatelessWidget {
  const new({required this.mine, required this.onPick, super.key});

  final Reaction? mine;
  final void Function(Reaction) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    Widget button(Reaction r) => Tooltip(
      message: reactionName(l10n, r),
      // The emoji's own label already names it for screen readers.
      excludeFromSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onPick(r),
        child: Container(
          padding: const EdgeInsets.all(Space.xs),
          // At least 48 × 48 to tap (SPEC §7.6), and no wider than that
          // (no alignment, which would stretch it): a circle in its cell.
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimension,
            minHeight: kMinInteractiveDimension,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Mine in my reaction's bubblegum, as its chip is.
            color: r == mine ? c.bubblegum.face : null,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text.rich(
              reactionSpan(r, heart: c.you.face),
              style: const TextStyle(fontSize: 28),
              semanticsLabel: reactionName(l10n, r),
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // A button as drawn: the 28 px emoji at this text size and its
        // padding, at least 48. Six to a row when six such fit.
        final extent = math.max(
          kMinInteractiveDimension,
          MediaQuery.textScalerOf(context).scale(28) * 1.25 + 2 * Space.xs,
        );
        final perRow = constraints.maxWidth / 6 >= extent ? 6 : 4;
        Widget row(Iterable<Reaction> reactions) => Row(
          children: [
            for (final r in reactions)
              Expanded(child: Center(child: button(r))),
          ],
        );
        final rest = reactionOrder.skip(_mainReactions).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(reactionOrder.take(_mainReactions)),
            for (var i = 0; i < rest.length; i += perRow)
              row(rest.skip(i).take(perRow)),
          ],
        );
      },
    );
  }
}

/// Chips under a bubble: each reaction with its count, mine highlighted
/// (CHAT-6), as 30 px gumdrops (Gumdrop Pop §3.1): secondary, or
/// bubblegum for mine. Tapping one gives it my reaction, or takes mine
/// back if it was mine already; a long-press or right-click shows who
/// reacted.
class ReactionChips extends StatelessWidget {
  const new({
    required this.message,
    required this.me,
    required this.onShowWho,
    this.onReact,
    this.alignEnd = false,
    super.key,
  });

  final Message message;
  final String? me;
  final VoidCallback onShowWho;

  /// Null where I can't react (viewing as a super admin): then a tap shows
  /// who reacted.
  final void Function(Reaction)? onReact;

  /// Under my own bubble, the chips line up on the right.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final counts = <Reaction, int>{};
    for (final r in message.reactions.values) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final mine = me == null ? null : message.reactions[me];
    final l10n = AppLocalizations.of(context);
    // Pill chips (Boot Camp Mix, #85, SPEC §5.4.6): the emoji and its count
    // in stencil on the panel color, mine on my own color, in a 2.5 px ink
    // outline, 6 apart and set in from the message's edge, each in a 48
    // tall tap area that doesn't move the layout: the areas reach up over
    // the message's bottom, so the chips overlap its edge, as the design
    // has them.
    final ink = c.ink;
    return _RaisedBy(
      by: _raise,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: alignEnd ? 0 : 16,
          end: alignEnd ? 16 : 0,
        ),
        child: Wrap(
          alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
          children: [
            for (final r in reactionOrder)
              if (counts[r] case final n?)
                // Read as "Like, 2" rather than the emoji.
                Semantics(
                  container: true,
                  button: true,
                  selected: r == mine,
                  label: l10n.reactionChipLabel(reactionName(l10n, r), n),
                  hint: onReact == null
                      ? null
                      : r == mine
                      ? l10n.reactionChipRemoveHint
                      : l10n.reactionChipAddHint,
                  excludeSemantics: true,
                  onTap: onReact == null ? onShowWho : () => onReact!(r),
                  onLongPress: onShowWho,
                  customSemanticsActions: {
                    CustomSemanticsAction(label: l10n.whoReacted): onShowWho,
                  },
                  child: GestureDetector(
                    onSecondaryTap: onShowWho,
                    onLongPress: onShowWho,
                    child: FocusRingInk(
                      onTap: onReact == null ? onShowWho : () => onReact!(r),
                      radius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        child: Align(
                          alignment: alignEnd
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: alignEnd ? _gap : 0,
                              end: alignEnd ? 0 : _gap,
                            ),
                            child: _Chip(
                              reaction: r,
                              count: n,
                              mine: r == mine,
                              ink: ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  /// Between one reaction and the next.
  static const double _gap = 6;

  /// How far the tap areas reach up over the message: the chips overlap
  /// its bottom edge by about 12 px.
  static const double _raise = 23;
}

/// One reaction chip (#85): the emoji and its count in stencil, on the
/// panel color or, for [mine], my own color, in a 2.5 px ink pill.
class _Chip extends StatelessWidget {
  const new({
    required this.reaction,
    required this.count,
    required this.mine,
    required this.ink,
  });

  final Reaction reaction;
  final int count;
  final bool mine;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final face = mine ? c.you.face : c.card.surface;
    final text = mine ? c.inkOn(c.you) : c.card.textOnPage;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: face,
        shape: StadiumBorder(side: BorderSide(color: ink, width: 2.5)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 1, 9, 1),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                // ❤️ in the scheme's red, as it always was a red heart.
                children: [reactionSpan(reaction, heart: c.coral.face)],
                style: const TextStyle(fontSize: 13),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: '$count'),
            ],
          ),
          style: TextStyle(
            fontFamily: AppFonts.stencil,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            height: 21 / 13,
            letterSpacing: 13 * 0.04,
            color: text,
          ),
        ),
      ),
    );
  }
}

/// Draws [child] [by] px higher than it's laid out, and takes that much
/// less room, so the reactions' 48 px tap areas overlap the message's
/// bottom edge instead of pushing everything under them down. A tap in the
/// overlap goes to the reactions, which are tested first.
class _RaisedBy extends SingleChildRenderObjectWidget {
  const new({required this.by, required Widget super.child});

  final double by;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRaisedBy(by);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderRaisedBy renderObject,
  ) => renderObject.by = by;
}

class _RenderRaisedBy extends RenderProxyBox {
  new(this._by);

  double get by => _by;
  double _by;
  set by(double value) {
    if (_by == value) return;
    _by = value;
    markNeedsLayout();
  }

  double _less(double height) => math.max(0, height - _by);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _less(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _less(super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final s = child?.getDryLayout(constraints.widthConstraints()) ?? Size.zero;
    return constraints.constrain(Size(s.width, _less(s.height)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.widthConstraints(), parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, _less(child.size.height)),
    );
  }

  @override
  Rect get paintBounds =>
      Rect.fromLTWH(0, -_by, size.width, child?.size.height ?? 0);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset.translate(0, -_by));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(0, -_by, 0, 1);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (!Rect.fromLTWH(
      0,
      -_by,
      size.width,
      child.size.height,
    ).contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: Offset(0, -_by),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}

/// Who reacted, grouped by reaction.
class ReactionsSheet extends ConsumerWidget {
  const new({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(rosterProvider(message.groupId)).value ?? const [];
    String nameOf(String uid) =>
        roster.where((m) => m.uid == UserId(uid)).firstOrNull?.displayName ??
        l10n.formerMember;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        for (final r in reactionOrder)
          for (final e in message.reactions.entries)
            if (e.value == r)
              ListTile(
                leading: Avatar(
                  name: nameOf(e.key),
                  colorKey: e.key,
                  color: roster
                      .where((m) => m.uid == UserId(e.key))
                      .firstOrNull
                      ?.avatarColor,
                  size: 32,
                ),
                title: Text(nameOf(e.key)),
                trailing: Text.rich(
                  reactionSpan(r, heart: GumdropColors.of(context).you.face),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
      ],
    );
  }
}

/// Runs [f] without waiting; its failure is shown elsewhere or not at all.
void fireAndForget(Future<void> f) => unawaited(f.catchError((Object _) {}));
