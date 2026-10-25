import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
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
  /// How long Create waits for the server before saying it couldn't. A
  /// request can sit on a phone for minutes before it's sent, and would
  /// otherwise leave Create spinning.
  static const _saveTimeout = Duration(seconds: 30);

  /// This screen's attempt, the same on every retry, so a first request
  /// that arrives late and a retry make one team between them (TEAM-1).
  final String _requestId = newRequestId();

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
            requestId: _requestId,
          )
          .timeout(_saveTimeout);
      final logo = _logo;
      if (logo != null) {
        try {
          await ref
              .read(groupRepositoryProvider)
              .uploadLogo(id, logo)
              .timeout(_saveTimeout);
        } on Object catch (e) {
          if (e is! AppFailure && e is! TimeoutException) rethrow;
          // The team is made; the logo can be added in Team settings.
          if (mounted) showAppSnackBar(context, l10n.createTeamLogoFailed);
        }
      }
      // TEAM-1: the next screen is "Invite your team".
      if (mounted) context.go('/g/${id.value}/invite');
    } on TimeoutException catch (error, stack) {
      // Said, and reported, like first-run setup's: it keeps someone from
      // making a team. Trying again is safe (_requestId).
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'create team',
          context: ErrorDescription('while creating the team'),
        ),
      );
      if (mounted) setState(() => _error = l10n.errorCreateTeam);
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
    final c = GumdropColors.of(context);
    return Scaffold(
      appBar: gumdropAppBar(context, title: l10n.createTeam),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
              children: [
                SettingsPanel(
                  radius: Corners.panel,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  child: Builder(
                    builder: (context) {
                      final card = GumdropColors.of(context);
                      final field = gumdropFieldText(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LabeledField(
                            label: l10n.teamNameLabel,
                            child: TextFormField(
                              controller: _name,
                              maxLength: Limits.groupNameMax,
                              textCapitalization: TextCapitalization.words,
                              style: field,
                              decoration: gumdropField(),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? l10n.teamNameRequired
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 9),
                          LabeledField(
                            label: l10n.sportLabel,
                            child: DropdownButtonFormField<Sport>(
                              initialValue: _sport,
                              style: field?.copyWith(color: card.textPrimary),
                              decoration: gumdropField(),
                              icon: Icon(
                                AppIcons.expand,
                                size: 24,
                                color: card.textMuted,
                              ),
                              borderRadius: BorderRadius.circular(
                                Corners.input,
                              ),
                              items: [
                                for (final s in Sport.values)
                                  DropdownMenuItem(
                                    value: s,
                                    child: Text(sportName(l10n, s)),
                                  ),
                              ],
                              onChanged: (s) =>
                                  setState(() => _sport = s ?? _sport),
                            ),
                          ),
                          const SizedBox(height: 9),
                          LabeledField(
                            label: l10n.timeZoneLabel,
                            child: DropdownButtonFormField<String>(
                              initialValue: _timeZone,
                              isExpanded: true,
                              style: field?.copyWith(color: card.textPrimary),
                              decoration: gumdropField(),
                              icon: Icon(
                                AppIcons.expand,
                                size: 24,
                                color: card.textMuted,
                              ),
                              borderRadius: BorderRadius.circular(
                                Corners.input,
                              ),
                              items: [
                                for (final z in _zones)
                                  DropdownMenuItem(value: z, child: Text(z)),
                              ],
                              onChanged: (z) => setState(() => _timeZone = z),
                            ),
                          ),
                          const SizedBox(height: 9),
                          LabeledField(
                            label: l10n.teamDescriptionLabel,
                            child: TextFormField(
                              controller: _description,
                              maxLength: 500,
                              maxLines: 3,
                              minLines: 1,
                              style: field,
                              decoration: gumdropField(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                PageHeading(l10n.teamLogoLabel),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (_logo != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: c.divider, spreadRadius: 2),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _logo!,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            semanticLabel: l10n.teamLogoLabel,
                          ),
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
                const SizedBox(height: 12),
                PageHeading(l10n.teamColorLabel),
                const SizedBox(height: 10),
                // Optional (TEAM-1): "No color" first.
                TeamColorGrid(
                  selected: _color,
                  allowNone: true,
                  onPick: (argb) => setState(() => _color = argb),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.teamColorTintNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textMutedOnPage,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
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
