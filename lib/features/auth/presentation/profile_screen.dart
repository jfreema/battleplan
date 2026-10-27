import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/theme_choices.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/presentation/profile_photo.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Profile at `/profile`, the top of the app beside Teams (SPEC §5.1,
/// SET-1): my photo (cropped to a circle) and the name my teams see, then
/// Themes, Settings, the Admin panel for super admins, and Sign out, each
/// its own card.
class ProfileScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();

  /// The saved name the field last took, so a change from elsewhere shows.
  String? _loadedName;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName(String uid) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateDisplayName(uid, _name.text);
      if (mounted) showAppSnackBar(context, l10n.profileSaved);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Pick, crop to the circle, then upload (SET-1).
  Future<void> _changePhoto(String uid) async {
    setState(() => _uploading = true);
    try {
      await changeProfilePhoto(context, ref, uid);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final theme = AppTheme.flavorOf(
      ref.watch(themePreferenceControllerProvider),
    );
    final themeName = themeChoices(l10n)
        .where((t) => t.$2 == theme)
        .map((t) => t.$3)
        .firstOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final c = GumdropColors.of(context);

    final saved = profile?.displayName;
    if (saved != null && saved != _loadedName) {
      _name.text = saved;
      _loadedName = saved;
    }
    final changed =
        saved != null &&
        _name.text.trim().isNotEmpty &&
        _name.text.trim() != saved;

    /// A menu as its own rounded card.
    Widget box(Widget row) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsCard(children: [row]),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter(width),
                Space.xs,
                Space.gutter(width),
                Space.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: Text(
                      l10n.profile,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, Space.xl),
                    children: [
                      if (profile != null) ...[
                        SettingsPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Avatar(
                                      name: profile.displayName,
                                      colorKey: profile.uid,
                                      imageUrl: photoUrl,
                                      size: 96,
                                    ),
                                    if (_uploading)
                                      const CircularProgressIndicator(),
                                  ],
                                ),
                              ),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _uploading
                                      ? null
                                      : () => unawaited(
                                          _changePhoto(profile.uid),
                                        ),
                                  icon: const Icon(AppIcons.camera, size: 18),
                                  label: Text(l10n.changePhoto),
                                ),
                              ),
                              const SizedBox(height: Space.sm),
                              LabeledField(
                                label: l10n.nameLabel,
                                // In the card's colors, as the card has them.
                                child: Builder(
                                  builder: (context) => TextField(
                                    controller: _name,
                                    maxLength: 50,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: gumdropFieldText(context),
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) {
                                      if (changed && !_saving) {
                                        unawaited(_saveName(profile.uid));
                                      }
                                    },
                                    decoration: gumdropField(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.setupNameHelp,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: c.card.textMuted),
                              ),
                              const SizedBox(height: Space.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: changed && !_saving
                                      ? () => unawaited(_saveName(profile.uid))
                                      : null,
                                  child: Text(l10n.save),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      box(
                        SettingsRow(
                          icon: AppIcons.themes,
                          title: l10n.themes,
                          subtitle: themeName,
                          onTap: () => unawaited(context.push('/themes')),
                        ),
                      ),
                      box(
                        SettingsRow(
                          icon: AppIcons.settings,
                          title: l10n.settings,
                          onTap: () => unawaited(context.push('/settings')),
                        ),
                      ),
                      // The God admin panel (ADMIN), for super admins.
                      if (superAdmin)
                        box(
                          SettingsRow(
                            icon: AppIcons.admin,
                            title: l10n.adminPanel,
                            onTap: () => unawaited(context.push('/admin')),
                          ),
                        ),
                      box(
                        SettingsRow(
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
