import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/admin/presentation/teams_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-4 at `/admin/users`: everyone, searchable by name or email,
/// filtered by Added, Active, Disabled, or Super admin, and sorted by any
/// column either way (owner's request 2026-11-14), with Create user. A
/// table on wide screens, whose column headers sort it; a list on phones,
/// with a Sort by menu.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  AdminUserQuery _query = const AdminUserQuery();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Sorts by [sort]: the same column again flips the direction; a new one
  /// starts A to Z, or newest first for dates.
  void _sortBy(AdminUserSort sort) => setState(
    () => _query = _query.copyWith(
      sort: sort,
      ascending: sort == _query.sort ? !_query.ascending : sort.ascendingFirst,
    ),
  );

  void _search(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDelay, () {
      if (mounted) setState(() => _query = _query.copyWith(query: text));
    });
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final input = await showCardDialog<_NewUser>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (input == null || !mounted) return;
    UserId? created;
    final ok = await runAdminAction(
      context,
      () async => created = await ref
          .read(adminRepositoryProvider)
          .createUser(
            email: input.email,
            displayName: input.name,
            groupId: input.team?.id,
            role: input.team == null ? null : input.role,
          ),
      done: l10n.adminUserCreated(input.email),
    );
    if (!ok || !mounted) return;
    ref
      ..invalidate(adminUsersProvider)
      ..invalidate(adminTotalsProvider);
    final uid = created?.value ?? '';
    if (uid.isNotEmpty) unawaited(context.push('/admin/users/$uid'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final users = ref.watch(adminUsersProvider(_query));
    final wide = isWide(context);
    void open(AdminUserRow u) =>
        unawaited(context.push('/admin/users/${u.uid.value}'));

    final controls = Wrap(
      spacing: Space.md,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.adminSearchUsers,
              prefixIcon: const Icon(AppIcons.search),
              isDense: true,
            ),
            onChanged: _search,
            onSubmitted: (v) {
              _debounce?.cancel();
              setState(() => _query = _query.copyWith(query: v));
            },
          ),
        ),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final f in <AdminUserFilter?>[null, ...AdminUserFilter.values])
              ChoiceChip(
                label: Text(_filterLabel(l10n, f)),
                selected: _query.filter == f,
                onSelected: (_) =>
                    setState(() => _query = _query.copyWith(filter: f)),
              ),
          ],
        ),
        // Its own Wrap, so the direction button drops to the next line on
        // a narrow phone instead of overflowing.
        if (!wide)
          Wrap(
            spacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.adminSortUsersBy),
              DropdownButton<AdminUserSort>(
                value: _query.sort,
                onChanged: (s) {
                  if (s != null && s != _query.sort) _sortBy(s);
                },
                items: [
                  for (final s in AdminUserSort.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(_sortLabel(l10n, s)),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _sortBy(_query.sort),
                icon: Icon(
                  _query.ascending ? AppIcons.arrowUp : AppIcons.arrowDown,
                ),
                label: Text(
                  _query.ascending
                      ? l10n.adminSortAscending
                      : l10n.adminSortDescending,
                ),
              ),
            ],
          ),
      ],
    );

    return AdminScaffold(
      section: AdminSection.users,
      title: l10n.adminUsers,
      actions: [
        if (wide)
          TextButton.icon(
            onPressed: () => unawaited(_create()),
            icon: const Icon(AppIcons.add),
            label: Text(l10n.adminCreateUser),
          ),
      ],
      floatingActionButton: wide
          ? null
          : FloatingActionButton(
              tooltip: l10n.adminCreateUser,
              onPressed: () => unawaited(_create()),
              child: const Icon(AppIcons.add),
            ),
      body: AdminBody(
        children: [
          controls,
          const SizedBox(height: Space.lg),
          switch (users) {
            AsyncValue(:final AdminList<AdminUserRow> value)
                when value.items.isEmpty =>
              EmptyState(icon: AppIcons.person, message: l10n.adminNoUsers),
            AsyncValue(:final AdminList<AdminUserRow> value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  _UsersTable(
                    rows: value.items,
                    sort: _query.sort,
                    ascending: _query.ascending,
                    onSort: _sortBy,
                    onOpen: open,
                  )
                else
                  for (final u in value.items)
                    _UserTile(user: u, onTap: () => open(u)),
                if (!value.reachedEnd)
                  LoadMoreButton(
                    loading: value.loadingMore,
                    onPressed: () => ref
                        .read(adminUsersProvider(_query).notifier)
                        .loadMore(),
                  ),
              ],
            ),
            AsyncError() => Center(child: Text(l10n.loadError)),
            _ => const SkeletonList(),
          },
        ],
      ),
    );
  }
}

/// A sort's name: its column's heading.
String _sortLabel(AppLocalizations l10n, AdminUserSort s) => switch (s) {
  AdminUserSort.name => l10n.adminColName,
  AdminUserSort.email => l10n.emailLabel,
  AdminUserSort.status => l10n.adminColStatus,
  AdminUserSort.joined => l10n.adminColJoined,
  AdminUserSort.lastActive => l10n.adminColLastActive,
};

String _filterLabel(AppLocalizations l10n, AdminUserFilter? f) => switch (f) {
  null => l10n.adminFilterAll,
  AdminUserFilter.added => l10n.adminStatusAdded,
  AdminUserFilter.active => l10n.adminStatusActive,
  AdminUserFilter.disabled => l10n.adminStatusDisabled,
  AdminUserFilter.superAdmin => l10n.adminSuperAdmin,
};

/// The users as a table; tapping a column's heading sorts by it, and
/// tapping it again flips the direction.
class _UsersTable extends StatelessWidget {
  const new({
    required this.rows,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onOpen,
  });

  final List<AdminUserRow> rows;
  final AdminUserSort sort;
  final bool ascending;
  final ValueChanged<AdminUserSort> onSort;
  final ValueChanged<AdminUserRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        // The columns are in AdminUserSort's order.
        sortColumnIndex: sort.index,
        sortAscending: ascending,
        columns: [
          for (final s in AdminUserSort.values)
            DataColumn(
              label: Text(_sortLabel(l10n, s)),
              onSort: (_, _) => onSort(s),
            ),
        ],
        rows: [
          for (final u in rows)
            DataRow(
              onSelectChanged: (_) => onOpen(u),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(u.displayName),
                      if (u.superAdmin) ...[
                        const SizedBox(width: Space.xs),
                        Icon(
                          AppIcons.admin,
                          size: 18,
                          semanticLabel: l10n.adminSuperAdmin,
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(Text(u.email ?? '')),
                DataCell(UserStatusChip(status: u.status)),
                DataCell(
                  Text(
                    adminDate(l10n, u.createdAt, zone: ViewerZone.of(context)),
                  ),
                ),
                DataCell(
                  Text(
                    adminDate(
                      l10n,
                      u.lastActiveAt,
                      zone: ViewerZone.of(context),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const new({required this.user, required this.onTap});

  final AdminUserRow user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Avatar(name: user.displayName, colorKey: user.uid.value),
      title: Row(
        children: [
          Flexible(child: Text(user.displayName)),
          if (user.superAdmin) ...[
            const SizedBox(width: Space.xs),
            Icon(AppIcons.admin, size: 18, semanticLabel: l10n.adminSuperAdmin),
          ],
        ],
      ),
      subtitle: Text(user.email ?? ''),
      trailing: UserStatusChip(status: user.status),
      onTap: onTap,
    );
  }
}

/// What Create user collects (ADMIN-4).
typedef _NewUser = ({
  String name,
  String email,
  AdminTeamRow? team,
  MemberRole role,
});

/// Name, email, and optionally a team and role. The account gets a setup
/// email; nobody sets its password (AUTH-6).
class _CreateUserDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  AdminTeamRow? _team;
  MemberRole _role = MemberRole.member;
  bool _tried = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _tried = true);
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !_emailPattern.hasMatch(email)) return;
    Navigator.of(context)
        .pop<_NewUser>((name: name, email: email, team: _team, role: _role));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameBad = _tried && _name.text.trim().isEmpty;
    final emailBad = _tried && !_emailPattern.hasMatch(_email.text.trim());
    return AlertDialog(
      title: Text(l10n.adminCreateUser),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCreateUserHelp),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: Limits.groupNameMax,
              decoration: InputDecoration(
                labelText: l10n.adminColName,
                errorText: nameBad ? l10n.nameRequired : null,
                counterText: '',
              ),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                errorText: emailBad ? l10n.emailInvalid : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Space.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminAddToTeamOptional),
              subtitle: Text(_team?.name ?? l10n.adminNoTeamChosen),
              trailing: _team == null
                  ? const Icon(AppIcons.chevronRight)
                  : IconButton(
                      tooltip: l10n.adminClearTeam,
                      icon: const Icon(AppIcons.close),
                      onPressed: () => setState(() => _team = null),
                    ),
              onTap: () async {
                final team = await pickTeam(context);
                if (team != null) setState(() => _team = team);
              },
            ),
            if (_team != null)
              RolePicker(
                value: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.adminCreateUser)),
      ],
    );
  }
}

/// Member or Admin, for adding someone to a team. Ownership moves only by
/// transfer.
class RolePicker extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  final MemberRole value;
  final ValueChanged<MemberRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<MemberRole>(
      segments: [
        ButtonSegment(
          value: MemberRole.member,
          label: Text(l10n.adminRoleMember),
        ),
        ButtonSegment(value: MemberRole.admin, label: Text(l10n.roleAdmin)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Finds a team by name for adding someone to it (ADMIN-4).
Future<AdminTeamRow?> pickTeam(BuildContext context) =>
    showCardDialog<AdminTeamRow>(
      context: context,
      builder: (_) => const _TeamPickerDialog(),
    );

class _TeamPickerDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_TeamPickerDialog> createState() => _TeamPickerDialogState();
}

class _TeamPickerDialogState extends ConsumerState<_TeamPickerDialog> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(
      adminTeamsProvider(
        AdminTeamQuery(query: _query, sort: AdminTeamSort.activity),
      ),
    );
    return AlertDialog(
      title: Text(l10n.adminChooseTeam),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.adminSearchTeams,
                prefixIcon: const Icon(AppIcons.search),
                isDense: true,
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(searchDelay, () {
                  if (mounted) setState(() => _query = v);
                });
              },
              onSubmitted: (v) {
                _debounce?.cancel();
                setState(() => _query = v);
              },
            ),
            const SizedBox(height: Space.sm),
            Expanded(
              child: switch (teams) {
                AsyncValue(:final AdminList<AdminTeamRow> value) =>
                  value.items.isEmpty
                      ? Center(child: Text(l10n.adminNoTeams))
                      : ListView(
                          children: [
                            for (final t in value.items)
                              ListTile(
                                leading: Icon(AppIcons.sport(t.sport)),
                                title: Text(t.name),
                                subtitle: Text(
                                  l10n.membersCount(t.memberCount),
                                ),
                                onTap: () => Navigator.of(context).pop(t),
                              ),
                          ],
                        ),
                AsyncError() => Center(child: Text(l10n.loadError)),
                _ => const SkeletonList(rows: 4),
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
