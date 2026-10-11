import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// TEAM-1 at `/g/new`: team type, name, sport, color, time zone, and an
/// optional description. The creator becomes the owner and lands in the
/// new team. (The logo is added in Team settings.)
class CreateTeamScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  TeamType _type = TeamType.adult;
  Sport _sport = Sport.soccer;
  int _color = teamColorValues.first;
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
            teamType: _type,
            timeZone: _timeZone ?? 'America/Chicago',
            color: _hex(_color),
            description: _description.text.trim(),
          );
      if (mounted) context.go('/g/${id.value}/chat');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e) {
          EmailNotVerified() => l10n.createTeamNeedsVerifiedEmail,
          RateLimited() => l10n.createTeamRateLimited,
          TooManyTeams() => l10n.tooManyTeams,
          PermissionDenied() => l10n.createTeamTurnedOff,
          Offline() => l10n.signInOffline,
          _ => l10n.signInUnknownError,
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
                Text(l10n.teamTypeLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.sm),
                SegmentedButton<TeamType>(
                  segments: [
                    ButtonSegment(
                      value: TeamType.adult,
                      label: Text(l10n.teamTypeAdult),
                    ),
                    ButtonSegment(
                      value: TeamType.youth,
                      label: Text(l10n.teamTypeYouth),
                    ),
                  ],
                  selected: {_type},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  _type == TeamType.adult
                      ? l10n.teamTypeAdultHelp
                      : l10n.teamTypeYouthHelp,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.xl),
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
                Text(l10n.teamColorLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
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
