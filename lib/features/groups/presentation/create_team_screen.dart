import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// TEAM-1 at `/g/new`: name, sport, an optional logo, an
/// optional color, time zone, and an optional description. The creator
/// becomes the owner and goes on to "Invite your team". There's one kind
/// of team, so there's no type to pick: every team has players (§6.3).
class CreateTeamScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  // Baseball is the default; any sport can be picked.
  Sport _sport = Sport.baseball;
  // Optional (TEAM-1): null is no color.
  int? _color = teamColorValues.first;
  Uint8List? _logo;
  String? _timeZone;
  List<String> _zones = const [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadZones());
  }

  Future<void> _loadZones() async {
    final tz = ref.read(timeZonesProvider);
    final device = await tz.deviceTimeZone();
    final zones = await tz.available();
    if (!mounted) return;
    setState(() {
      _timeZone = device;
      _zones = zones.contains(device) ? zones : [device, ...zones];
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final bytes = await ref.read(photoPickerProvider).pickProfilePhoto();
    if (bytes == null || !mounted) return;
    if (!fitsUploadLimit(context, ref, bytes.length)) return;
    setState(() => _logo = bytes);
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _create() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(groupRepositoryProvider)
          .createGroup(
            name: _name.text.trim(),
            sport: _sport,
            timeZone: _timeZone ?? 'America/Chicago',
            color: _color == null ? null : _hex(_color!),
            description: _description.text.trim(),
          );
      final logo = _logo;
      if (logo != null) {
        try {
          await ref.read(groupRepositoryProvider).uploadLogo(id, logo);
        } on AppFailure {
          // The team is made; the logo can be added in Team settings.
          if (mounted) showAppSnackBar(context, l10n.createTeamLogoFailed);
        }
      }
      // TEAM-1: the next screen is "Invite your team".
      if (mounted) context.go('/g/${id.value}/invite');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e) {
          EmailNotVerified() => l10n.createTeamNeedsVerifiedEmail,
          RateLimited() => l10n.createTeamRateLimited,
          TooManyTeams() => l10n.tooManyTeams,
          PermissionDenied() => l10n.createTeamTurnedOff,
          Offline() => l10n.signInOffline,
          _ => l10n.errorCreateTeam,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createTeam)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: Limits.groupNameMax,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.teamNameLabel,
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.teamNameRequired : null,
                ),
                const SizedBox(height: Space.lg),
                DropdownButtonFormField<Sport>(
                  initialValue: _sport,
                  decoration: InputDecoration(labelText: l10n.sportLabel),
                  items: [
                    for (final s in Sport.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(sportName(l10n, s)),
                      ),
                  ],
                  onChanged: (s) => setState(() => _sport = s ?? _sport),
                ),
                const SizedBox(height: Space.xl),
                Text(l10n.teamLogoLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.sm),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (_logo != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Corners.card),
                        child: Image.memory(
                          _logo!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.teamLogoLabel,
                        ),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => unawaited(_pickLogo()),
                      icon: const Icon(AppIcons.photo),
                      label: Text(
                        _logo == null ? l10n.addLogo : l10n.changeLogo,
                      ),
                    ),
                    if (_logo != null)
                      TextButton(
                        onPressed: () => setState(() => _logo = null),
                        child: Text(l10n.removeLogo),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xl),
                Text(l10n.teamColorLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    // No color (TEAM-1: optional).
                    Semantics(
                      button: true,
                      selected: _color == null,
                      label: l10n.noTeamColor,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = null),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _color == null ? AppIcons.check : AppIcons.close,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    for (final c in teamColorValues)
                      Semantics(
                        button: true,
                        selected: c == _color,
                        label: _hex(c),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = c),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(c),
                            child: c == _color
                                ? const Icon(
                                    AppIcons.check,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xl),
                DropdownButtonFormField<String>(
                  initialValue: _timeZone,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.timeZoneLabel),
                  items: [
                    for (final z in _zones)
                      DropdownMenuItem(value: z, child: Text(z)),
                  ],
                  onChanged: (z) => setState(() => _timeZone = z),
                ),
                const SizedBox(height: Space.lg),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: l10n.teamDescriptionLabel,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: Space.md),
                  Text(error, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: _saving || _timeZone == null
                      ? null
                      : () => unawaited(_create()),
                  child: Text(l10n.createTeam),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The display name of a sport.
String sportName(AppLocalizations l10n, Sport sport) => switch (sport) {
  Sport.baseball => l10n.sportBaseball,
  Sport.basketball => l10n.sportBasketball,
  Sport.football => l10n.sportFootball,
  Sport.hockey => l10n.sportHockey,
  Sport.lacrosse => l10n.sportLacrosse,
  Sport.soccer => l10n.sportSoccer,
  Sport.softball => l10n.sportSoftball,
  Sport.volleyball => l10n.sportVolleyball,
  Sport.other => l10n.sportOther,
};
