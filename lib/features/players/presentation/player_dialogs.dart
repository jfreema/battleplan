import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
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

/// What a guardian is called on the player card (#95): "Guardian" or
/// "Parent". Purely a label; a parent is a guardian everywhere else.
String guardianTitleName(AppLocalizations l10n, GuardianTitle t) => switch (t) {
  GuardianTitle.guardian => l10n.playerLinkGuardian,
  GuardianTitle.parent => l10n.playerLinkParent,
};

/// How a player is claimed: as the player, or as a guardian listed as
/// `title` (#95).
typedef ClaimChoice = ({PlayerRelation relation, GuardianTitle title});

/// Asks how the member is linked to [playerName] before claiming it
/// (PLAYER-3): "I am this player" or "I'm their parent or guardian", and
/// for a guardian, Listed as Guardian (the default) or Parent (#95). "I am
/// this player" is left out when [canBeSelf] is false: the player already
/// has its member, or the member already is a player on this team. Null
/// when canceled.
Future<ClaimChoice?> askClaimRelation(
  BuildContext context, {
  required String playerName,
  required bool canBeSelf,
}) {
  final l10n = AppLocalizations.of(context);
  var relation = canBeSelf ? null : PlayerRelation.guardian;
  var title = GuardianTitle.guardian;
  return showCardDialog<ClaimChoice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.claimPlayerTitle(playerName)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.claimPlayerHelp),
              const SizedBox(height: Space.sm),
              RadioGroup<PlayerRelation>(
                groupValue: relation,
                onChanged: (r) => setState(() => relation = r),
                child: Column(
                  children: [
                    for (final r in PlayerRelation.values)
                      if (r != PlayerRelation.self || canBeSelf)
                        RadioListTile<PlayerRelation>(
                          contentPadding: EdgeInsets.zero,
                          value: r,
                          title: Text(relationChoice(l10n, r)),
                        ),
                  ],
                ),
              ),
              if (relation == PlayerRelation.guardian) ...[
                const SizedBox(height: Space.sm),
                GuardianTitleField(
                  value: title,
                  onChanged: (t) => setState(() => title = t),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: switch (relation) {
              final r? => () => Navigator.of(
                context,
              ).pop((relation: r, title: title)),
              null => null,
            },
            child: Text(l10n.claimSend),
          ),
        ],
      ),
    ),
  );
}

/// "Listed as" Guardian or Parent (#95), wherever a guardian links to a
/// player: claiming one, adding one who isn't listed, and their own row on
/// the player card. A guardian unless they pick Parent; the help says it's
/// only a label.
class GuardianTitleField extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  final GuardianTitle value;
  final ValueChanged<GuardianTitle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<GuardianTitle>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.guardianTitleLabel,
        helperText: l10n.guardianTitleHelp,
        helperMaxLines: 3,
      ),
      items: [
        for (final t in GuardianTitle.values)
          DropdownMenuItem(value: t, child: Text(guardianTitleName(l10n, t))),
      ],
      onChanged: (t) {
        if (t != null) onChanged(t);
      },
    );
  }
}

/// A player a member adds (PLAYER-4).
typedef ProposedPlayer = ({
  String name,
  String? jerseyNumber,

  /// 'YYYY-MM-DD', or null (PLAYER-12).
  String? dateOfBirth,
  PlayerRelation relation,

  /// What a guardian is listed as (#95); a guardian unless they picked it.
  GuardianTitle title,
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
  GuardianTitle _title = GuardianTitle.guardian;
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
      title: _title,
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
        // A guardian picks how they're listed (#95).
        if (_relation == PlayerRelation.guardian) ...[
          const SizedBox(height: Space.md),
          GuardianTitleField(
            value: _title,
            onChanged: (t) => setState(() => _title = t),
          ),
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
