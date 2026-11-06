import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/time_zone_picker.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/presentation/your_icon_screen.dart'
    show candyName;
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/schedule/application/providers.dart'
    show deviceTimeZoneProvider;
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Profile at `/profile`, the top of the app beside Teams (SPEC §5.1,
/// SET-1): plain rows for Your icon, Name, Time zone, Settings, the Admin
/// panel for super admins, and Sign out.
class ProfileScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// The name my teams see (SET-1), in a dialog: up to 50 characters,
  /// saved when it changed.
  Future<void> _editName(UserProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final name = await showCardDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: profile.displayName),
    );
    if (name == null || !mounted) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateDisplayName(profile.uid, name);
      if (mounted) showAppSnackBar(context, l10n.profileSaved);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }

  /// Picks the zone times show in (SET-7): Automatic, the device's, or
  /// one that stays put while traveling.
  Future<void> _pickTimeZone(UserProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final device = await ref.read(deviceTimeZoneProvider.future);
    final zones = await ref.read(timeZonesProvider).available();
    if (!mounted) return;
    final picked = await showCardDialog<String>(
      context: context,
      builder: (context) => TimeZonePicker(
        zones: TimeZoneNames.ordered(zones, keep: [device, ?profile.timeZone]),
        current: profile.timeZone,
        automatic: l10n.timeZoneAutomatic(TimeZoneNames.label(device)),
        help: l10n.timeZoneMineHelp,
      ),
    );
    if (picked == null || !mounted) return;
    final zone = picked == TimeZonePicker.automaticChoice ? null : picked;
    if (zone == profile.timeZone) return;
    try {
      await ref.read(userRepositoryProvider).setTimeZone(profile.uid, zone);
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.timeZoneSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopLevelBar(title: l10n.profile),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, Space.xl),
                    children: [
                      PageRows(
                        children: [
                          if (profile != null) ...[
                            PageRow(
                              leading: Avatar(
                                name: profile.displayName,
                                colorKey: profile.uid,
                                color: profile.avatarColor,
                                imageUrl: photoUrl,
                              ),
                              title: l10n.yourIcon,
                              subtitle: profile.photoPath != null
                                  ? l10n.iconSubtitlePhoto
                                  : switch (profile.avatarColor) {
                                      final color? => candyName(l10n, color),
                                      null => null,
                                    },
                              onTap: () =>
                                  unawaited(context.push('/profile/icon')),
                            ),
                            PageRow(
                              icon: AppIcons.person,
                              title: l10n.nameLabel,
                              subtitle: profile.displayName,
                              onTap: () => unawaited(_editName(profile)),
                            ),
                          ],
                          // The zone every time shows in, wherever I am
                          // (SET-7).
                          PageRow(
                            icon: AppIcons.timeZone,
                            title: l10n.timeZoneLabel,
                            subtitle: switch (profile?.timeZone) {
                              final zone? => TimeZoneNames.label(zone),
                              null => l10n.timeZoneAutomatic(
                                TimeZoneNames.label(
                                  ref.watch(deviceTimeZoneProvider).value ?? '',
                                ),
                              ),
                            },
                            onTap: profile == null
                                ? null
                                : () => unawaited(_pickTimeZone(profile)),
                          ),
                          PageRow(
                            icon: AppIcons.settings,
                            title: l10n.settings,
                            onTap: () => unawaited(context.push('/settings')),
                          ),
                          // The God admin panel (ADMIN), for super admins.
                          if (superAdmin)
                            PageRow(
                              icon: AppIcons.admin,
                              title: l10n.adminPanel,
                              onTap: () => unawaited(context.push('/admin')),
                            ),
                          PageRow(
                            icon: AppIcons.signOut,
                            title: l10n.signOut,
                            subtitle: switch (profile?.email) {
                              final email? when email.isNotEmpty =>
                                l10n.signedInAs(email),
                              _ => null,
                            },
                            chevron: false,
                            onTap: () => unawaited(
                              ref.read(sessionServiceProvider).signOut(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name's dialog: the field (up to 50, words capitalized) with the help
/// under it, and Cancel and Save, which waits for a change.
class _NameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim().isNotEmpty && _name.text.trim() != widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    void save() {
      if (_changed) Navigator.of(context).pop(_name.text);
    }

    return AlertDialog(
      title: Text(l10n.nameLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            style: gumdropFieldText(context),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => save(),
            decoration: gumdropField(),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.setupNameHelp,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: c.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _changed ? save : null, child: Text(l10n.save)),
      ],
    );
  }
}
