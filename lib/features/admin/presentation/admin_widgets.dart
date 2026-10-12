import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The panel's sections, in the order the rail and drawer list them
/// (ARCH §5.4 `/admin/...`).
enum AdminSection {
  dashboard('/admin'),
  teams('/admin/teams'),
  users('/admin/users'),
  reports('/admin/reports'),
  audit('/admin/audit'),
  settings('/admin/settings');

  new(this.path);

  final String path;
}

/// The admin panel's frame (ADMIN, "designed for a desktop browser but
/// works on phones"): a left rail of sections on wide screens, a drawer on
/// phones. A pushed detail page shows Back instead of the drawer.
class AdminScaffold extends StatelessWidget {
  const new({
    required this.section,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    super.key,
  });

  final AdminSection section;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  static IconData _icon(AdminSection s) => switch (s) {
    AdminSection.dashboard => AppIcons.dashboard,
    AdminSection.teams => AppIcons.group,
    AdminSection.users => AppIcons.person,
    AdminSection.reports => AppIcons.report,
    AdminSection.audit => AppIcons.history,
    AdminSection.settings => AppIcons.tune,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    final canPop = context.canPop();
    void open(AdminSection s) {
      if (s != section || canPop) context.go(s.path);
    }

    final appBar = AppBar(
      title: Text(title),
      actions: [
        ...actions,
        // Out of the panel, back to the person's teams.
        IconButton(
          tooltip: l10n.adminExit,
          icon: const Icon(AppIcons.leave),
          onPressed: () => context.go('/'),
        ),
      ],
    );
    if (wide) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: section.index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => open(AdminSection.values[i]),
              destinations: [
                for (final s in AdminSection.values)
                  NavigationRailDestination(
                    icon: Icon(_icon(s)),
                    selectedIcon: Icon(_icon(s), fill: 1),
                    label: Text(adminSectionLabel(l10n, s)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      drawer: canPop
          ? null
          : NavigationDrawer(
              selectedIndex: section.index,
              onDestinationSelected: (i) {
                Navigator.of(context).pop();
                open(AdminSection.values[i]);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    Space.lg,
                    Space.lg,
                    Space.sm,
                  ),
                  child: Text(
                    l10n.adminPanel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final s in AdminSection.values)
                  NavigationDrawerDestination(
                    icon: Icon(_icon(s)),
                    selectedIcon: Icon(_icon(s), fill: 1),
                    label: Text(adminSectionLabel(l10n, s)),
                  ),
              ],
            ),
      body: body,
    );
  }
}

String adminSectionLabel(AppLocalizations l10n, AdminSection s) => switch (s) {
  AdminSection.dashboard => l10n.adminDashboard,
  AdminSection.teams => l10n.adminTeams,
  AdminSection.users => l10n.adminUsers,
  AdminSection.reports => l10n.reportsTitle,
  AdminSection.audit => l10n.adminAuditLog,
  AdminSection.settings => l10n.adminSettings,
};

/// True at 840 px and up, where lists become tables (ADMIN).
bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.wide;

/// What to tell a super admin when an admin action fails.
String adminFailureText(AppLocalizations l10n, Object failure) =>
    switch (failure) {
      LastSuperAdmin() => l10n.adminLastSuperAdmin,
      PermissionDenied() => l10n.notAllowed,
      Offline() => l10n.signInOffline,
      NotFound() => l10n.adminNotFound,
      InvalidInput() => l10n.methodInvalid,
      EmailAlreadyInUse() => l10n.adminEmailInUse,
      OwnerMustTransfer() => l10n.adminOwnerMustTransfer,
      ActionRefused(:final reason) => switch (reason) {
        'already-member' => l10n.adminAlreadyMember,
        'cannot-delete-self' || 'cannot-disable-self' => l10n.adminNotYourself,
        'name-mismatch' => l10n.adminNameMismatch,
        'owner' => l10n.adminOwnerMustTransfer,
        'nothing-to-delete' => l10n.adminNothingToDelete,
        _ => l10n.errorAdminAction,
      },
      _ => l10n.errorAdminAction,
    };

/// Runs an admin action and says how it went: [done] on success, or what
/// went wrong. Returns true when it worked.
Future<bool> runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  String? done,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    if (done != null && context.mounted) showAppSnackBar(context, done);
    return true;
  } on AppFailure catch (e) {
    if (context.mounted) showAppSnackBar(context, adminFailureText(l10n, e));
    return false;
  }
}

/// Asks before an admin action (ADMIN-8), then runs it as
/// [runAdminAction] does. Returns true when it was confirmed and worked.
Future<bool> confirmAndRun(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Future<void> Function() action,
  String? message,
  String? done,
  bool destructive = false,
}) async {
  final ok = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: AppLocalizations.of(context).cancel,
    destructive: destructive,
  );
  if (!ok || !context.mounted) return false;
  return await runAdminAction(context, action, done: done);
}

/// "Oct 6, 2026", or a dash for no date.
String adminDate(AppLocalizations l10n, DateTime? d) =>
    d == null ? '—' : DateFormat.yMMMd(l10n.localeName).format(d.toLocal());

/// "Oct 6, 2026, 3:04 PM", or a dash.
String adminDateTime(AppLocalizations l10n, DateTime? d) => d == null
    ? '—'
    : DateFormat.yMMMd(l10n.localeName).add_jm().format(d.toLocal());

/// A small colored label: a team's or a person's status.
class StatusChip extends StatelessWidget {
  const new({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.14), scheme.surface),
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}

/// Active, Archived, or Suspended (ADMIN-2).
class TeamStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final TeamStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return StatusChip(
      label: teamStatusLabel(l10n, status),
      color: switch (status) {
        TeamStatus.active => AppColors.of(context).going,
        TeamStatus.archived => scheme.outline,
        TeamStatus.suspended => scheme.error,
      },
    );
  }
}

String teamStatusLabel(AppLocalizations l10n, TeamStatus s) => switch (s) {
  TeamStatus.active => l10n.adminStatusActive,
  TeamStatus.archived => l10n.adminStatusArchived,
  TeamStatus.suspended => l10n.adminStatusSuspended,
};

/// Added (not joined yet), Active, or Disabled (ADMIN-4).
class UserStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return StatusChip(
      label: userStatusLabel(l10n, status),
      color: switch (status) {
        UserStatus.provisioned => AppColors.of(context).maybe,
        UserStatus.active => AppColors.of(context).going,
        UserStatus.disabled => scheme.error,
      },
    );
  }
}

String userStatusLabel(AppLocalizations l10n, UserStatus s) => switch (s) {
  UserStatus.provisioned => l10n.adminStatusAdded,
  UserStatus.active => l10n.adminStatusActive,
  UserStatus.disabled => l10n.adminStatusDisabled,
};

/// A titled block on a detail page.
class AdminSectionCard extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.only(bottom: Space.lg),
    child: Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Space.sm),
          ...children,
        ],
      ),
    ),
  );
}

/// "Load more" under a paged list, while there's more.
class LoadMoreButton extends StatelessWidget {
  const new({required this.loading, required this.onPressed, super.key});

  final bool loading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: () => unawaited(
                  onPressed().catchError((Object e) {
                    if (context.mounted) {
                      showAppSnackBar(context, adminFailureText(l10n, e));
                    }
                  }),
                ),
                child: Text(l10n.adminLoadMore),
              ),
      ),
    );
  }
}

/// A page's content, at a readable width and padded.
class AdminBody extends StatelessWidget {
  const new({required this.children, this.maxWidth = 1100, super.key});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.all(Space.gutter(width)),
          children: children,
        ),
      ),
    );
  }
}

/// Asks for a note before an action (ADMIN-5, ADMIN-8): the dialog says
/// what will happen, and [confirmLabel] stays off until a [required] note
/// is written. Returns the note, '' when an optional one is left blank, or
/// null when canceled.
Future<String?> askNote(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  bool required = false,
  bool destructive = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NoteDialog(
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    required: required,
    destructive: destructive,
  ),
);

class _NoteDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.required,
    required this.destructive,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final bool required;
  final bool destructive;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ready = !widget.required || _note.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message case final m?) ...[
            Text(m),
            const SizedBox(height: Space.md),
          ],
          TextField(
            controller: _note,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            maxLength: reportNoteMax,
            decoration: InputDecoration(
              labelText: widget.required
                  ? l10n.adminNoteRequired
                  : l10n.adminNoteOptional,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: ready
              ? () => Navigator.of(context).pop(_note.text.trim())
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Asks to type [expected] (a team's name) before something that can't be
/// undone (ADMIN-3, ADMIN-8). [confirmLabel] stays off until it matches.
Future<bool> confirmByTyping(
  BuildContext context, {
  required String title,
  required String message,
  required String expected,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _TypeToConfirmDialog(
        title: title,
        message: message,
        expected: expected,
        confirmLabel: confirmLabel,
      ),
    ) ??
    false;

class _TypeToConfirmDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.message,
    required this.expected,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String expected;
  final String confirmLabel;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final matches = _typed.text.trim() == widget.expected.trim();
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: Space.md),
          TextField(
            controller: _typed,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.adminTypeName(widget.expected),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
