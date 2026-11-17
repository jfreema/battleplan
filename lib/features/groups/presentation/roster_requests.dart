import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/button_spinner.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/roster_screen.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Why an admin's approval failed (PLAYER-3, PLAYER-4): [who] is a player
/// on the team already, someone already is this player, the player's
/// guardians are full, or the roster is.
String decisionFailure(
  AppLocalizations l10n,
  AppFailure e, {
  required String who,
}) => switch (e) {
  InvalidInput(message: 'already-a-player') => l10n.approveAlreadyAPlayer(who),
  InvalidInput(message: 'player-already-claimed') =>
    l10n.approvePlayerAlreadyClaimed,
  InvalidInput(message: 'too-many-guardians') => l10n.claimLimitReached,
  InvalidInput(message: 'too-many-players') => l10n.tooManyPlayers(
    Limits.playersPerGroupMax,
  ),
  _ => l10n.errorGuardianRequest,
};

/// "Phil" from "Phil Dunphy", for the confirmations.
String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// One request waiting for a team's admins (PLAYER-4, #23): a member's new
/// player ([pending]), or a member's claim on a player already on the
/// roster ([claim], of [claimed]).
class RosterRequest {
  const new player({
    required Player this.pending,
    required this.requesterName,
    this.requester,
  }) : claim = null,
       claimed = null,
       linked = const [];

  const new claim({
    required GuardianRequest this.claim,
    required this.requesterName,
    this.claimed,
    this.requester,
    this.linked = const [],
  }) : pending = null;

  /// The member's new player, waiting to go on the roster.
  final Player? pending;

  /// The member's claim, and the player it's for (null while the roster
  /// loads).
  final GuardianRequest? claim;
  final Player? claimed;

  /// Who asked: their membership, for the photo, and their name (Former
  /// member once they've left).
  final Membership? requester;
  final String requesterName;

  /// Who's already linked to the claimed player, by name, so the coach can
  /// tell a real parent from a mistake.
  final List<({String name, PlayerRelation relation})> linked;

  /// When it was asked, oldest first; null sorts last.
  DateTime? get at => pending?.addedAt ?? claim?.createdAt;

  /// Its row's key, so a spinner stays with its request when one above it
  /// leaves the list.
  String get key => switch (pending) {
    final p? => 'player ${p.id.value}',
    null => 'claim ${claim!.playerId.value} ${claim!.uid.value}',
  };

  /// The player as the sentence names them: "Emma Rodriguez #7" for a new
  /// one, "Noah #4" for one on the roster.
  String get _playerName => switch (pending) {
    final p? =>
      p.jerseyNumber?.isNotEmpty ?? false
          ? '${p.displayName} #${p.jerseyNumber}'
          : p.displayName,
    null => claimed?.label ?? '…',
  };

  /// The player's first name, for the confirmations.
  String get _playerFirst => pending?.firstName ?? claimed?.firstName ?? '…';

  /// What it asks, as a parent would say it, and the names in it, which
  /// are drawn bold. Never anyone's pronouns but "they".
  (String, List<String>) sentence(AppLocalizations l10n) {
    final who = requesterName;
    final player = _playerName;
    final p = pending;
    if (p != null) {
      if (p.proposedRelation == PlayerRelation.self) {
        final number = p.jerseyNumber;
        return number == null || number.isEmpty
            ? (l10n.requestPlayerSelf(who), [who])
            : (l10n.requestPlayerSelfNumber(who, number), [who]);
      }
      return (
        l10n.requestPlayerGuardian(who, player, p.firstName),
        [who, player],
      );
    }
    return claim!.relation == PlayerRelation.self
        ? (l10n.requestClaimSelf(who, player), [who, player])
        : (l10n.requestClaimGuardian(who, player), [who, player]);
  }

  /// Approves or declines it, and says what changed for the person who
  /// asked: who can answer which RSVPs now, or that they can ask again.
  /// Returns the snackbar's message, and for a new player approved
  /// without a number, its Add number action.
  Future<(String, SnackBarAction?)> decide(
    WidgetRef ref,
    AppLocalizations l10n, {
    required bool approve,
    required VoidCallback openPlayer,
  }) async {
    final repo = ref.read(playerRepositoryProvider);
    final who = _first(requesterName);
    final first = _playerFirst;
    final p = pending;
    if (p != null) {
      final linked = await repo.resolvePendingPlayer(
        p.groupId,
        p.id,
        approve: approve,
      );
      if (!approve) return (l10n.requestDeclined(who), null);
      // Added, but its member couldn't be linked to it: say so, so nobody
      // thinks they're on it (PLAYER-4).
      if (!linked && p.proposedBy != null) {
        return (
          l10n.pendingPlayerNotLinked(p.displayName, requesterName),
          null,
        );
      }
      final message = p.proposedRelation == PlayerRelation.self
          ? l10n.requestApprovedPlayerSelf(who)
          : l10n.requestApprovedPlayer(first, who);
      final numbered = p.jerseyNumber?.isNotEmpty ?? false;
      return (
        message,
        numbered
            ? null
            : SnackBarAction(
                label: l10n.requestAddNumber,
                onPressed: openPlayer,
              ),
      );
    }
    final c = claim!;
    await repo.resolvePlayerClaim(
      c.groupId,
      c.playerId,
      c.uid,
      approve: approve,
    );
    if (!approve) return (l10n.requestDeclined(who), null);
    return (
      c.relation == PlayerRelation.self
          ? l10n.requestApprovedClaimSelf(who)
          : l10n.requestApprovedClaim(who, first),
      null,
    );
  }

  /// The roster's player page for what was approved or claimed.
  String get _playerPath {
    final id = pending?.id ?? claim!.playerId;
    final group = pending?.groupId ?? claim!.groupId;
    return '/g/${group.value}/team/players/${id.value}';
  }
}

/// Runs [request]'s decision (PLAYER-4), then says what it did, or why it
/// failed, through [messenger]: the row or sheet is gone by then.
Future<void> _run(
  WidgetRef ref,
  AppLocalizations l10n,
  ScaffoldMessengerState messenger,
  GoRouter router,
  RosterRequest request, {
  required bool approve,
}) async {
  void say(String message, [SnackBarAction? action]) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
  try {
    final (message, action) = await request.decide(
      ref,
      l10n,
      approve: approve,
      openPlayer: () => unawaited(router.push(request._playerPath)),
    );
    say(message, action);
  } on AppFailure catch (e) {
    say(decisionFailure(l10n, e, who: request.requesterName));
    rethrow;
  }
}

/// [text] with each of [bold] in it drawn at 800.
InlineSpan _boldNames(String text, List<String> bold, TextStyle? strong) {
  final spans = <InlineSpan>[];
  var rest = text;
  while (rest.isNotEmpty) {
    // The earliest name still to come.
    (int, String)? next;
    for (final name in bold) {
      if (name.isEmpty) continue;
      final at = rest.indexOf(name);
      if (at >= 0 && (next == null || at < next.$1)) next = (at, name);
    }
    if (next == null) {
      spans.add(TextSpan(text: rest));
      break;
    }
    if (next.$1 > 0) spans.add(TextSpan(text: rest.substring(0, next.$1)));
    spans.add(TextSpan(text: next.$2, style: strong));
    rest = rest.substring(next.$1 + next.$2.length);
  }
  return TextSpan(children: spans);
}

/// The requester's photo or initials; a former member's initials.
class _RequesterAvatar extends StatelessWidget {
  const new({required this.request});

  final RosterRequest request;

  @override
  Widget build(BuildContext context) => switch (request.requester) {
    final m? => MemberAvatar(member: m),
    null => Avatar(
      name: request.requesterName,
      colorKey: request.requesterName,
      size: 40,
    ),
  };
}

/// One request on the Team tab (PLAYER-4, #23): the requester's photo, one
/// plain sentence ("Phil Dunphy says they're a parent or guardian of Noah
/// #4."), and Decline and Approve on their own line under it, so the
/// buttons never squeeze the words. Tapping the sentence opens the request
/// to review it, and for a new player, to fix its name and number first.
class RequestTile extends ConsumerWidget {
  const new({required this.request, super.key});

  final RosterRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      height: 21 / 16,
      fontWeight: FontWeight.w600,
      color: c.textOnPage,
    );
    final (sentence, names) = request.sentence(l10n);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: sentence,
            // "Double tap to review".
            onTapHint: l10n.requestReviewHint,
            excludeSemantics: true,
            child: FocusRingInk(
              radius: BorderRadius.circular(12),
              onTap: () => unawaited(
                showAdaptiveSheet<void>(
                  context,
                  // Over the whole app, as a member's card is.
                  useRootNavigator: true,
                  builder: (_) => RequestSheet(
                    request: request,
                    messenger: messenger,
                    router: router,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequesterAvatar(request: request),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Text.rich(
                        _boldNames(
                          sentence,
                          names,
                          const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            // Level with the sentence.
            padding: const EdgeInsets.only(left: 40 + 14),
            child: _Decision(
              decide: ({required approve}) =>
                  _run(ref, l10n, messenger, router, request, approve: approve),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decline (outlined) and Approve (coral), each a full 48 px target. Once
/// one is tapped, both are off and the tapped one spins until the server
/// answers (PLAYER-4): a cold start can take several seconds, and taps
/// meanwhile used to send the decision again. [decide] throws when it
/// fails, and the buttons come back.
class _Decision extends StatefulWidget {
  const new({required this.decide, this.onDone});

  final Future<void> Function({required bool approve}) decide;

  /// After a decision goes through: the sheet closes.
  final VoidCallback? onDone;

  @override
  State<_Decision> createState() => _DecisionState();
}

class _DecisionState extends State<_Decision> {
  /// The decision on its way: true for Approve, false for Decline, null
  /// when there's none.
  bool? _deciding;

  Future<void> _send({required bool approve}) async {
    // Checked as well as the buttons being off, for two taps in one frame.
    if (_deciding != null) return;
    setState(() => _deciding = approve);
    var done = false;
    try {
      await widget.decide(approve: approve);
      done = true;
    } on Object catch (_) {
      // Said already; the request stays, with both buttons back.
    } finally {
      // A decided row usually goes from the list first.
      if (mounted) setState(() => _deciding = null);
    }
    if (done && mounted) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _deciding != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: busy ? null : () => unawaited(_send(approve: false)),
          child: _deciding == false
              ? const ButtonSpinner()
              : Text(l10n.decline),
        ),
        FilledButton(
          onPressed: busy ? null : () => unawaited(_send(approve: true)),
          child: _deciding == true ? const ButtonSpinner() : Text(l10n.approve),
        ),
      ],
    );
  }
}

/// A request opened from its row (PLAYER-4, #23), over the whole app: the
/// sentence, then for a new player its Name and Number, filled in and
/// editable, which Approve saves first; for a claim, the player and who's
/// already linked to them. Decline and Approve decide it as the row does,
/// and close it; closing it otherwise changes nothing.
class RequestSheet extends ConsumerStatefulWidget {
  const new({
    required this.request,
    required this.messenger,
    required this.router,
    super.key,
  });

  final RosterRequest request;

  /// The Team tab's, for what it did once the sheet is gone.
  final ScaffoldMessengerState messenger;
  final GoRouter router;

  @override
  ConsumerState<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<RequestSheet> {
  late final _name = TextEditingController(
    text: widget.request.pending?.displayName ?? '',
  );
  late final _number = TextEditingController(
    text: widget.request.pending?.jerseyNumber ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  /// Saves a changed name or number first (`updatePlayer`; the rules let
  /// admins), then decides. A failed save doesn't approve, and says so.
  Future<void> _decide({required bool approve}) async {
    final l10n = AppLocalizations.of(context);
    var request = widget.request;
    final p = request.pending;
    if (approve && p != null) {
      final name = _name.text.trim();
      final number = _number.text.trim();
      if (name.isEmpty) {
        setState(() => _error = l10n.playerNameRequired);
        throw const InvalidInput('name');
      }
      if (name != p.displayName || number != (p.jerseyNumber ?? '')) {
        try {
          await ref
              .read(playerRepositoryProvider)
              .updatePlayer(
                p.id,
                name: name,
                jerseyNumber: number,
                walkUpSong: p.walkUpSong,
              );
        } on Object catch (_) {
          if (mounted) setState(() => _error = l10n.requestSaveFailed);
          rethrow;
        }
        request = RosterRequest.player(
          pending: p.copyWith(displayName: name, jerseyNumber: number),
          requesterName: request.requesterName,
          requester: request.requester,
        );
      }
    }
    if (_error != null && mounted) setState(() => _error = null);
    await _run(
      ref,
      l10n,
      widget.messenger,
      widget.router,
      request,
      approve: approve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final request = widget.request;
    final pending = request.pending;
    final (sentence, names) = request.sentence(l10n);
    final error = _error;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.md,
          Space.xl,
          Space.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CardHeading(
              pending != null
                  ? l10n.requestSheetPlayerTitle
                  : l10n.requestSheetClaimTitle,
            ),
            const SizedBox(height: Space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RequesterAvatar(request: request),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    _boldNames(
                      sentence,
                      names,
                      const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (pending != null) ...[
              // The same rules as Add players: a name of 1 to 60, a number
              // of up to 4.
              TextField(
                controller: _name,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.playerNameLabel,
                  counterText: '',
                ),
              ),
              const SizedBox(height: Space.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: l10n.jerseyNumberLabel,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ] else ...[
              SectionLabel(l10n.requestAlreadyLinked),
              const SizedBox(height: Space.xs),
              if (request.linked.isEmpty)
                Text(
                  l10n.requestNobodyLinked(request.claimed?.label ?? '…'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.textMuted,
                  ),
                )
              else
                for (final l in request.linked)
                  Text(
                    l.relation == PlayerRelation.self
                        ? l10n.requestLinkedSelf(l.name)
                        : l10n.requestLinkedGuardian(l.name),
                    style: theme.textTheme.bodyMedium,
                  ),
            ],
            if (error != null) ...[
              const SizedBox(height: Space.md),
              Text(error, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: Space.xl),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _Decision(
                decide: _decide,
                onDone: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
