import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart'
    show themeOverridesProvider;
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/chat_look_section.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/team_scheme_section.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The two pages Admin settings' Look opens (#32, owner's go 2026-11-17),
/// on the app's frame, going back to "‹ Admin settings": they were its two
/// longest sections, at the bottom of a page five screens long.

/// The page's column, as Admin settings', around [child].
Widget _page(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, 14, Space.page, Space.xl),
      children: [child],
    ),
  ),
);

/// "‹ Admin settings", or whoever opened it.
String? _backLabel(BuildContext context, Group? group) {
  final l10n = AppLocalizations.of(context);
  return backLabelFrom(
    context,
    group?.isGroup ?? false ? l10n.groupAdmin : l10n.teamAdmin,
  );
}

/// `/g/:groupId/settings/chat-look` (CHAT-18): the chat's look for everyone
/// on the team, each pick saved at once, as it was on Admin settings.
class ChatLookScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    return GumdropScaffold(
      maxWidth: 560,
      title: l10n.chatLook,
      backLabel: _backLabel(context, group),
      body: group == null
          ? const SizedBox.shrink()
          : _page(ChatLookSection(group: group)),
    );
  }
}

/// `/g/:groupId/settings/color-scheme` (SET-2): the team's default color
/// scheme, what everyone who hasn't picked their own sees, or System
/// default (none), and Reset for everyone (#73).
class TeamSchemeScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final themes = ref.watch(themeOverridesProvider);
    final mine =
        usableScheme(ref.watch(defaultSchemeControllerProvider), themes) ??
        defaultTeamScheme;

    void failed(AppFailure e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e is PermissionDenied ? l10n.notAllowed : l10n.profileSaveFailed,
        );
      }
    }

    // [scheme] null is System default.
    Future<void> pick(TeamScheme? scheme) async {
      try {
        // Through the audited admin callable for a super admin who isn't
        // one of its admins (ADMIN-3).
        await ref
            .read(teamEditorProvider(groupId))
            .updateColorScheme(groupId, scheme);
      } on AppFailure catch (e) {
        failed(e);
      }
    }

    // Takes back everyone's own pick, once the admin says so (#73).
    Future<void> reset() async {
      final g = group;
      if (g == null) return;
      final teamDefault = g.colorScheme;
      final go = await showConfirmDialog(
        context,
        title: l10n.resetSchemesTitle,
        message: teamDefault == null
            ? l10n.resetSchemesBodySystem(g.name)
            : l10n.resetSchemesBody(g.name, teamDefault.label(l10n)),
        confirmLabel: l10n.resetSchemesConfirm,
        cancelLabel: l10n.cancel,
      );
      if (!go) return;
      try {
        final reset = await ref
            .read(memberRepositoryProvider)
            .resetColorSchemes(groupId);
        if (context.mounted) {
          showAppSnackBar(context, l10n.resetSchemesDone(reset));
        }
      } on AppFailure catch (e) {
        failed(e);
      }
    }

    return GumdropScaffold(
      maxWidth: 560,
      title: group?.isGroup ?? false
          ? l10n.groupDefaultScheme
          : l10n.teamDefaultScheme,
      backLabel: _backLabel(context, group),
      body: group == null
          ? const SizedBox.shrink()
          : _page(
              TeamSchemeSection(
                group: group.copyWith(
                  colorScheme: usableScheme(group.colorScheme, themes),
                ),
                mine: mine,
                schemes: ThemeCatalog.available,
                onPick: pick,
                onReset: reset,
              ),
            ),
    );
  }
}
