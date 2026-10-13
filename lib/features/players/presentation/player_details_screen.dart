import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Waits for who may edit (the team, the player, my membership, and the
/// player's links), then for the stored details, and shows
/// [PlayerDetailsScreen] (PLAYER-12) at
/// `/g/:groupId/roster/players/:playerId/details`. Only the team's admins
/// and the members linked to the player edit, and not on an archived or
/// suspended team; anyone else is told so, and their app never asks for
/// the details.
class PlayerDetailsRoute extends ConsumerWidget {
  const new({required this.groupId, required this.playerId, super.key});

  final GroupId groupId;
  final PlayerId playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final players = ref.watch(playersProvider(groupId));
    final links = ref.watch(guardianLinksProvider(groupId));
    final memberships = ref.watch(myMembershipsProvider);
    final uid = ref.watch(authUserProvider).value?.uid;
    if (group == null ||
        !players.hasValue ||
        !links.hasValue ||
        !memberships.hasValue) {
      return Scaffold(appBar: AppBar(), body: const SkeletonList());
    }
    final player = players.value!.where((p) => p.id == playerId).firstOrNull;
    if (player == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: AppIcons.roster, message: l10n.playerNotFound),
      );
    }
    final allowed =
        uid != null &&
        !group.isArchived &&
        group.suspendedAt == null &&
        seesPlayerDetails(
          uid,
          playerId,
          teamAdmin: ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false,
          links: links.value!,
        );
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: AppIcons.block, message: l10n.notAllowed),
      );
    }
    final details = ref.watch(playerDetailsProvider(playerId));
    if (!details.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: details.hasError
            ? Center(child: Text(l10n.loadError))
            : const SkeletonList(),
      );
    }
    return PlayerDetailsScreen(
      player: player,
      uid: UserId(uid),
      stored: details.value,
    );
  }
}

/// The details form (PLAYER-12): date of birth from a date picker (not
/// today or later, and not more than [Limits.playerAgeMaxYears] years
/// ago), up to [Limits.emergencyContactsMax] emergency contacts that each
/// need a name and a phone, medical notes with the consent line to check
/// whenever they're entered or changed, and notes. Saving with nothing
/// filled in removes the details.
class PlayerDetailsScreen extends ConsumerStatefulWidget {
  const new({
    required this.player,
    required this.uid,
    required this.stored,
    super.key,
  });

  final Player player;

  /// Who's saving: recorded with the save, and with the consent.
  final UserId uid;

  /// What's saved now, or null when there's nothing yet.
  final PlayerDetails? stored;

  @override
  ConsumerState<PlayerDetailsScreen> createState() =>
      _PlayerDetailsScreenState();
}

/// One emergency contact's fields.
class _ContactFields {
  new([EmergencyContact? c])
    : name = TextEditingController(text: c?.name),
      phone = TextEditingController(text: c?.phone),
      relationship = TextEditingController(text: c?.relationship);

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController relationship;

  /// Nothing typed in: dropped when saving rather than refused.
  bool get blank =>
      blankToNull(name.text) == null &&
      blankToNull(phone.text) == null &&
      blankToNull(relationship.text) == null;

  EmergencyContact get contact => EmergencyContact(
    name: name.text,
    phone: phone.text,
    relationship: relationship.text,
  );

  void dispose() {
    name.dispose();
    phone.dispose();
    relationship.dispose();
  }
}

class _PlayerDetailsScreenState extends ConsumerState<PlayerDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _medical = TextEditingController();
  final _notes = TextEditingController();
  final _contacts = <_ContactFields>[];
  DateTime? _dob;
  bool _consent = false;
  bool _tried = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.stored;
    _dob = switch (s?.dateOfBirth) {
      final dob? => parseDateOfBirth(dob),
      null => null,
    };
    for (final c in s?.emergencyContacts ?? const <EmergencyContact>[]) {
      _contacts.add(_ContactFields(c));
    }
    _medical.text = s?.medicalNotes ?? '';
    _notes.text = s?.notes ?? '';
  }

  @override
  void dispose() {
    _medical.dispose();
    _notes.dispose();
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  /// New or changed medical notes need the consent line (PLAYER-12).
  bool get _needsConsent =>
      needsMedicalConsent(stored: widget.stored, medicalNotes: _medical.text);

  String? get _dobText => switch (_dob) {
    final d? => formatDateOfBirth(d),
    null => null,
  };

  bool get _dobOk =>
      _dobText == null || dateOfBirthAllowed(_dobText!, DateTime.now());

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final range = dateOfBirthRange(now);
    // Without a date, the year list opens near a youth player's age.
    var initial = _dob == null
        ? DateTime(now.year - 10, now.month, now.day)
        : DateTime(_dob!.year, _dob!.month, _dob!.day);
    if (initial.isBefore(range.first)) initial = range.first;
    if (initial.isAfter(range.last)) initial = range.last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: range.first,
      lastDate: range.last,
      initialDatePickerMode: _dob == null
          ? DatePickerMode.year
          : DatePickerMode.day,
      helpText: l10n.dateOfBirthLabel,
    );
    if (picked != null && mounted) {
      setState(
        () => _dob = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tried = true);
    final valid = _form.currentState!.validate();
    if (!valid || !_dobOk || (_needsConsent && !_consent)) return;
    final p = widget.player;
    final details = PlayerDetails(
      playerId: p.id,
      groupId: p.groupId,
      dateOfBirth: _dobText,
      emergencyContacts: [
        for (final c in _contacts)
          if (!c.blank) c.contact,
      ],
      medicalNotes: _medical.text,
      notes: _notes.text,
    ).cleaned;
    final repo = ref.read(playerRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      if (details.isEmpty) {
        // Nothing left to keep: the details go (PLAYER-12).
        if (widget.stored != null) await repo.deletePlayerDetails(p.id);
      } else {
        await repo.savePlayerDetails(
          details,
          by: widget.uid,
          stored: widget.stored,
        );
      }
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.playerDetailsSaved)));
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e is PermissionDenied
              ? l10n.notAllowed
              : l10n.playerDetailsSaveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Refuses text over [max] characters. The fields stop there as you
  /// type; this catches what gets past them, such as a paste.
  FormFieldValidator<String> _upTo(int max) =>
      (v) =>
          (v?.trim().length ?? 0) > max ? l10n.playerDetailsTooLong(max) : null;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dob = _dob;
    final age = _dobText == null ? null : ageOn(_dobText!, DateTime.now());
    final needsConsent = _needsConsent;

    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.cancel,
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.player.displayName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(
              onPressed: _saving ? null : () => unawaited(_save()),
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            autovalidateMode: _tried
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                if (_saving) const LinearProgressIndicator(),
                Text(
                  l10n.editPlayerDetails,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  l10n.playerDetailsWhoSees,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.birthday),
                  title: Text(l10n.dateOfBirthLabel),
                  subtitle: Text(
                    _tried && !_dobOk
                        ? l10n.dateOfBirthOutOfRange(Limits.playerAgeMaxYears)
                        : dob == null
                        ? l10n.dateOfBirthNotSet
                        : [
                            MaterialLocalizations.of(context)
                                .formatShortDate(dob),
                            if (age != null) l10n.playerAge(age),
                          ].join(' · '),
                    style: _tried && !_dobOk
                        ? TextStyle(color: scheme.error)
                        : null,
                  ),
                  trailing: dob == null
                      ? const Icon(AppIcons.edit)
                      : IconButton(
                          tooltip: l10n.clearDateOfBirth,
                          icon: const Icon(AppIcons.close),
                          onPressed: () => setState(() => _dob = null),
                        ),
                  onTap: () => unawaited(_pickDate()),
                ),
                section(l10n.emergencyContactsLabel),
                for (final (i, c) in _contacts.indexed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.emergencyContactNumber(i + 1),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.removeEmergencyContact,
                        icon: const Icon(AppIcons.delete),
                        onPressed: () => setState(() {
                          _contacts.removeAt(i).dispose();
                        }),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: c.name,
                    maxLength: Limits.emergencyContactNameMax,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.emergencyContactNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => !c.blank && blankToNull(v) == null
                        ? l10n.emergencyContactNameRequired
                        : _upTo(Limits.emergencyContactNameMax)(v),
                  ),
                  const SizedBox(height: Space.sm),
                  TextFormField(
                    controller: c.phone,
                    maxLength: Limits.emergencyContactPhoneMax,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.emergencyContactPhoneLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => !c.blank && !hasDialableDigits(v ?? '')
                        ? l10n.emergencyContactPhoneRequired
                        : _upTo(Limits.emergencyContactPhoneMax)(v),
                  ),
                  const SizedBox(height: Space.sm),
                  TextFormField(
                    controller: c.relationship,
                    maxLength: Limits.emergencyContactRelationshipMax,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.emergencyContactRelationshipLabel,
                      hintText: l10n.emergencyContactRelationshipHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _upTo(Limits.emergencyContactRelationshipMax),
                  ),
                ],
                if (_contacts.length < Limits.emergencyContactsMax)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _contacts.add(_ContactFields())),
                      icon: const Icon(AppIcons.add),
                      label: Text(l10n.addEmergencyContact),
                    ),
                  ),
                section(l10n.medicalNotesLabel),
                TextFormField(
                  controller: _medical,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: Limits.medicalNotesMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.medicalNotesLabel,
                    helperText: l10n.medicalNotesHelp,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _upTo(Limits.medicalNotesMax),
                  // The consent line comes and goes with changes.
                  onChanged: (_) => setState(() {}),
                ),
                // Shown when the medical notes are entered or changed; the
                // save records who agreed and when (PLAYER-12).
                if (needsConsent)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                    title: Text(l10n.medicalConsentLine),
                    subtitle: _tried && !_consent
                        ? Text(
                            l10n.medicalConsentRequired,
                            style: TextStyle(color: scheme.error),
                          )
                        : null,
                  ),
                section(l10n.playerNotesLabel),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: Limits.playerNotesMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.playerNotesLabel,
                    helperText: l10n.playerNotesHelp,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _upTo(Limits.playerNotesMax),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
