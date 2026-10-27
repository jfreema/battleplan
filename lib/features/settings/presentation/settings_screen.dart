import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/settings/presentation/new_owners_dialog.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings (SPEC §6.10), from Profile: notifications, sign-in methods,
/// blocked people, about, and the account actions. The photo and name,
/// the themes, and the Admin panel are on Profile itself.
class SettingsScreen extends ConsumerWidget {
  const new({required this.appBuild, this.showDevTools = false, super.key});

  /// Shown under About: the version, build number, and commit (ARCH §9).
  final AppBuild appBuild;

  /// Shows developer-only tools (dev builds only).
  final bool showDevTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = ref.read(linkOpenerProvider);
    // The legal pages are on the website, at the root of the domain (D40).
    final site = ref.read(linkServiceProvider);
    final support = ref.watch(supportEmailProvider);

    const gap = SizedBox(height: 12);
    const headingGap = SizedBox(height: 10);

    return Scaffold(
      appBar: gumdropAppBar(context, title: l10n.settings),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
            children: [
              PageHeading(l10n.account),
              headingGap,
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: AppIcons.notifications,
                    highlighted: true,
                    title: l10n.notificationSettings,
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  SettingsRow(
                    icon: AppIcons.key,
                    title: l10n.signInMethods,
                    onTap: () => context.push('/settings/sign-in-methods'),
                  ),
                  SettingsRow(
                    icon: AppIcons.block,
                    title: l10n.blockedPeople,
                    onTap: () => context.push('/settings/blocked'),
                  ),
                  if (showDevTools)
                    SettingsRow(
                      icon: AppIcons.notifications,
                      // Dev-only, never shipped, so not translated.
                      title: 'Push test (dev only)',
                      onTap: () => context.push('/settings/push-test'),
                    ),
                ],
              ),
              gap,
              PageHeading(l10n.about),
              headingGap,
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: AppIcons.info,
                    title: appBuild.number.isEmpty
                        ? l10n.versionLabel(appBuild.version)
                        : l10n.versionBuildLabel(
                            appBuild.version,
                            appBuild.number,
                          ),
                    // The commit it was built from, to match it with GitHub.
                    subtitle: appBuild.commit.isEmpty ? null : appBuild.commit,
                  ),
                  SettingsRow(
                    icon: AppIcons.document,
                    title: l10n.termsOfUse,
                    onTap: () => links.open(site.site('/terms')),
                  ),
                  SettingsRow(
                    icon: AppIcons.visibility,
                    title: l10n.privacyPolicy,
                    onTap: () => links.open(site.site('/privacy')),
                  ),
                  SettingsRow(
                    icon: AppIcons.file,
                    title: l10n.openSourceLicenses,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appName,
                      applicationVersion: appBuild.full,
                    ),
                  ),
                  // The address from platform settings (ADMIN-7).
                  SettingsRow(
                    icon: AppIcons.email,
                    title: l10n.contactSupport,
                    subtitle: support,
                    onTap: () =>
                        links.open(Uri(scheme: 'mailto', path: support)),
                  ),
                ],
              ),
              gap,
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: AppIcons.signOut,
                    title: l10n.signOut,
                    chevron: false,
                    onTap: () => ref.read(sessionServiceProvider).signOut(),
                  ),
                  SettingsRow(
                    icon: AppIcons.signOut,
                    title: l10n.signOutEverywhere,
                    subtitle: l10n.signOutEverywhereHelp,
                    subtitleLines: 3,
                    chevron: false,
                    onTap: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: l10n.signOutEverywhereConfirmTitle,
                        message: l10n.signOutEverywhereHelp,
                        confirmLabel: l10n.signOutEverywhere,
                        cancelLabel: l10n.cancel,
                      );
                      if (ok) {
                        await ref
                            .read(sessionServiceProvider)
                            .signOutEverywhere();
                      }
                    },
                  ),
                  Builder(
                    builder: (context) => SettingsRow(
                      icon: AppIcons.error,
                      accent: GumdropColors.of(context).cherry,
                      title: l10n.deleteAccount,
                      titleColor: GumdropColors.of(context).cherry.text,
                      chevron: false,
                      onTap: () => _deleteAccount(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccount,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    // AUTH-10: owners pick who takes over each team they own.
    final owned = ownedTeams(ref.read(myTeamsProvider).value ?? []);
    var newOwners = const <String, String>{};
    if (owned.isNotEmpty) {
      final picks = await pickNewOwners(context, owned);
      if (picks == null || !context.mounted) return;
      newOwners = picks;
    }
    try {
      await withFreshSignIn(
        context,
        ref,
        () => ref
            .read(sessionServiceProvider)
            .deleteAccount(newOwners: newOwners),
      );
    } on SignInCanceled {
      // They closed Apple's sheet: nothing was deleted.
    } on AppFailure {
      if (context.mounted) {
        showAppSnackBar(context, l10n.deleteAccountFailed);
      }
    }
  }
}
