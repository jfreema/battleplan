import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// PLAYER-3 at `/g/:groupId/who`, shown after joining a youth team: pick
/// your players (a request to the admins, Q15), add a player who isn't
/// listed, or skip as a coach or another adult. Parents an admin already
/// linked (PLAYER-1) go straight to the team.
class WhoAreYouScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<WhoAreYouScreen> createState() => _WhoAreYouScreenState();
}

class _WhoAreYouScreenState extends ConsumerState<WhoAreYouScreen> {
  final Set<PlayerId> _picked = {};
  bool _saving = false;
  bool _checkedLinks = false;

  String get _teamHome => '/g/${widget.groupId.value}/chat';

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) context.go(_teamHome);
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e is RateLimited
              ? l10n.guardianRequestsRateLimited
              : l10n.errorWhoAreYou,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _request() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      await ref
          .read(playerRepositoryProvider)
          .requestGuardianLink(widget.groupId, _picked.toList());
      if (mounted) showAppSnackBar(context, l10n.guardianRequestSent);
    });
  }

  Future<void> _addMine() async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final number = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addMyPlayer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.playerNameLabel),
            ),
            TextField(
              controller: number,
              maxLength: 4,
              decoration: InputDecoration(labelText: l10n.jerseyNumberLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await _run(
      () => ref
          .read(playerRepositoryProvider)
          .addMyPlayer(
            widget.groupId,
            name: name.text.trim(),
            jerseyNumber: number.text.trim().isEmpty
                ? null
                : number.text.trim(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authUserProvider).value?.uid;
    final players = ref.watch(playersProvider(widget.groupId));
    final links = ref.watch(guardianLinksProvider(widget.groupId));
    final requested = {
      for (final r
          in ref.watch(myGuardianRequestsProvider(widget.groupId)).value ??
              const <GuardianRequest>[])
        if (r.status == GuardianRequestStatus.pending) r.playerId,
    };
    final mine = {
      for (final l in links.value ?? const <GuardianLink>[])
        if (l.uid.value == me) l.playerId,
    };
    // Already linked by an admin (PLAYER-1): nothing to ask.
    if (!_checkedLinks && links.hasValue) {
      _checkedLinks = true;
      if (mine.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(_teamHome);
        });
      }
    }
    final list = (players.value ?? const <Player>[])
        .where((p) => !mine.contains(p.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.whoAreYouHereFor)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Text(l10n.whoAreYouHereForHelp),
              const SizedBox(height: Space.md),
              if (!players.hasValue) const LinearProgressIndicator(),
              for (final p in list)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: requested.contains(p.id) || _picked.contains(p.id),
                  onChanged: requested.contains(p.id)
                      ? null
                      : (v) => setState(
                          () => v == true
                              ? _picked.add(p.id)
                              : _picked.remove(p.id),
                        ),
                  title: Text(p.displayName),
                  subtitle: requested.contains(p.id)
                      ? Text(l10n.guardianRequestPending)
                      : p.jerseyNumber == null
                      ? null
                      : Text('#${p.jerseyNumber}'),
                ),
              const SizedBox(height: Space.md),
              FilledButton(
                onPressed: _saving || _picked.isEmpty
                    ? null
                    : () => unawaited(_request()),
                child: Text(l10n.sendGuardianRequest(_picked.length)),
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                onPressed: _saving ? null : () => unawaited(_addMine()),
                child: Text(l10n.addMyPlayer),
              ),
              const SizedBox(height: Space.sm),
              TextButton(
                onPressed: _saving ? null : () => context.go(_teamHome),
                child: Text(l10n.imACoachOrAdult),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
