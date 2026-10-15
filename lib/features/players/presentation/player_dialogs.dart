import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/players/presentation/date_of_birth_field.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// "I am this player" or "I'm their parent or guardian" (PLAYER-3): how
/// the signed-in member is linked to a player they claim or add.
String relationChoice(AppLocalizations l10n, PlayerRelation r) => switch (r) {
  PlayerRelation.self => l10n.relationSelf,
  PlayerRelation.guardian => l10n.relationGuardian,
};

/// Asks how the member is linked to [playerName] before claiming it
/// (PLAYER-3). "I am this player" is left out when [canBeSelf] is false:
/// the player already has its member, or the member already is a player
/// on this team. Null when canceled.
Future<PlayerRelation?> askClaimRelation(
  BuildContext context, {
  required String playerName,
  required bool canBeSelf,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<PlayerRelation>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.claimPlayerTitle(playerName)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.sm),
          child: Text(l10n.claimPlayerHelp),
        ),
        for (final r in PlayerRelation.values)
          if (r != PlayerRelation.self || canBeSelf)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(r),
              child: Text(relationChoice(l10n, r)),
            ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );
}

/// A player a member adds (PLAYER-4).
typedef ProposedPlayer = ({
  String name,
  String? jerseyNumber,

  /// 'YYYY-MM-DD', or null (PLAYER-12).
  String? dateOfBirth,
  PlayerRelation relation,
});

/// The form for a player who isn't listed (PLAYER-4): name, number, date
/// of birth, and how the member is linked. [relation] fixes the link (as
/// "Who are you here for?" does) instead of asking; [name] prefills the
/// name, such as the member's own when they add themselves.
class ProposePlayerForm extends StatefulWidget {
  const new({
    required this.onSubmit,
    this.relation,
    this.name,
    this.canBeSelf = true,
    this.saving = false,
    super.key,
  });

  final ValueChanged<ProposedPlayer> onSubmit;
  final PlayerRelation? relation;
  final String? name;

  /// False when the member is already a player on this team (PLAYER-3).
  final bool canBeSelf;
  final bool saving;

  @override
  State<ProposePlayerForm> createState() => _ProposePlayerFormState();
}

class _ProposePlayerFormState extends State<ProposePlayerForm> {
  late final _name = TextEditingController(text: widget.name);
  final _number = TextEditingController();
  late PlayerRelation? _relation =
      widget.relation ?? (widget.canBeSelf ? null : PlayerRelation.guardian);
  DateTime? _dob;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  String? _blank(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _submit() {
    setState(() => _tried = true);
    final relation = _relation;
    if (_name.text.trim().isEmpty || relation == null) return;
    widget.onSubmit((
      name: _name.text.trim(),
      jerseyNumber: _blank(_number),
      dateOfBirth: _dob == null ? null : formatDateOfBirth(_dob!),
      relation: relation,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = TextStyle(color: Theme.of(context).colorScheme.error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.playerNameLabel,
            counterText: '',
            errorText: _tried && _name.text.trim().isEmpty
                ? l10n.playerNameRequired
                : null,
          ),
        ),
        const SizedBox(height: Space.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 110,
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
        DateOfBirthField(
          value: _dob,
          onChanged: (d) => setState(() => _dob = d),
        ),
        const DateOfBirthPrivacyNote(),
        if (widget.relation == null) ...[
          const SizedBox(height: Space.lg),
          Text(
            l10n.howAreYouLinked,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RadioGroup<PlayerRelation>(
            groupValue: _relation,
            onChanged: (r) => setState(() => _relation = r),
            child: Column(
              children: [
                for (final r in PlayerRelation.values)
                  if (r != PlayerRelation.self || widget.canBeSelf)
                    RadioListTile<PlayerRelation>(
                      contentPadding: EdgeInsets.zero,
                      value: r,
                      title: Text(relationChoice(l10n, r)),
                    ),
              ],
            ),
          ),
          if (_tried && _relation == null)
            Text(l10n.howAreYouLinkedRequired, style: error),
        ],
        const SizedBox(height: Space.md),
        Text(
          l10n.proposePlayerHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: widget.saving ? null : _submit,
          child: Text(l10n.addPlayer),
        ),
      ],
    );
  }
}

/// What a failed claim or add says (PLAYER-3, PLAYER-4).
String playerRequestFailure(AppLocalizations l10n, AppFailure e) => switch (e) {
  RateLimited() => l10n.guardianRequestsRateLimited,
  InvalidInput(message: 'player-already-claimed') => l10n.playerAlreadyClaimed,
  InvalidInput(message: 'already-a-player') => l10n.alreadyAPlayer,
  InvalidInput(message: 'already-linked') => l10n.alreadyLinked,
  InvalidInput(message: 'too-many-guardians') => l10n.tooManyGuardians,
  InvalidInput(message: 'too-many-players') => l10n.tooManyPlayers(
    Limits.playersPerGroupMax,
  ),
  PermissionDenied(message: 'team-archived') => l10n.teamArchived,
  NotFound() => l10n.playerNotFound,
  Offline() => l10n.signInOffline,
  _ => l10n.errorWhoAreYou,
};
