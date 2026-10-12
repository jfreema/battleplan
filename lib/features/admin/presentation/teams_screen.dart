import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// How long typing pauses before a search goes to the server.
const searchDelay = Duration(milliseconds: 400);

/// ADMIN-2 at `/admin/teams`: every team, searchable by name, sorted by
/// created date, last activity, members, or storage, and filtered by
/// status. A table on wide screens, a list on phones.
class AdminTeamsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends ConsumerState<AdminTeamsScreen> {
  AdminTeamQuery _query = const AdminTeamQuery();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDelay, () {
      if (mounted) setState(() => _query = _query.copyWith(query: text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(adminTeamsProvider(_query));
    final wide = isWide(context);
    void open(AdminTeamRow t) =>
        unawaited(context.push('/admin/teams/${t.id.value}'));

    final controls = Wrap(
      spacing: Space.md,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.adminSearchTeams,
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
        DropdownButton<AdminTeamSort>(
          value: _query.sort,
          onChanged: (s) => s == null
              ? null
              : setState(() => _query = _query.copyWith(sort: s)),
          items: [
            for (final s in AdminTeamSort.values)
              DropdownMenuItem(value: s, child: Text(_sortLabel(l10n, s))),
          ],
        ),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final status in <TeamStatus?>[null, ...TeamStatus.values])
              ChoiceChip(
                label: Text(
                  status == null
                      ? l10n.adminFilterAll
                      : teamStatusLabel(l10n, status),
                ),
                selected: _query.status == status,
                onSelected: (_) =>
                    setState(() => _query = _query.copyWith(status: status)),
              ),
          ],
        ),
      ],
    );

    return AdminScaffold(
      section: AdminSection.teams,
      title: l10n.adminTeams,
      body: AdminBody(
        children: [
          controls,
          const SizedBox(height: Space.lg),
          switch (teams) {
            AsyncValue(:final AdminList<AdminTeamRow> value)
                when value.items.isEmpty =>
              EmptyState(icon: AppIcons.group, message: l10n.adminNoTeams),
            AsyncValue(:final AdminList<AdminTeamRow> value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  _TeamsTable(rows: value.items, onOpen: open)
                else
                  for (final t in value.items)
                    _TeamTile(team: t, onTap: () => open(t)),
                if (!value.reachedEnd)
                  LoadMoreButton(
                    loading: value.loadingMore,
                    onPressed: () => ref
                        .read(adminTeamsProvider(_query).notifier)
                        .loadMore(),
                  ),
              ],
            ),
            AsyncError() => Center(child: Text(l10n.loadError)),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

String _sortLabel(AppLocalizations l10n, AdminTeamSort s) => switch (s) {
  AdminTeamSort.created => l10n.adminSortCreated,
  AdminTeamSort.activity => l10n.adminSortActivity,
  AdminTeamSort.members => l10n.adminSortMembers,
  AdminTeamSort.storage => l10n.adminSortStorage,
};

/// Wide screens: name, sport, owner, members, last activity, storage,
/// status (ADMIN-2).
class _TeamsTable extends StatelessWidget {
  const new({required this.rows, required this.onOpen});

  final List<AdminTeamRow> rows;
  final ValueChanged<AdminTeamRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(label: Text(l10n.adminColName)),
          DataColumn(label: Text(l10n.sportLabel)),
          DataColumn(label: Text(l10n.adminColOwner)),
          DataColumn(label: Text(l10n.rosterMembers), numeric: true),
          DataColumn(label: Text(l10n.adminColLastActivity)),
          DataColumn(label: Text(l10n.storageSection), numeric: true),
          DataColumn(label: Text(l10n.adminColStatus)),
        ],
        rows: [
          for (final t in rows)
            DataRow(
              onSelectChanged: (_) => onOpen(t),
              cells: [
                DataCell(Text(t.name)),
                DataCell(Text(sportName(l10n, t.sport))),
                DataCell(Text(t.ownerName)),
                DataCell(Text('${t.memberCount}')),
                DataCell(Text(adminDate(l10n, t.lastMessageAt))),
                DataCell(Text(formatBytes(t.storageBytes))),
                DataCell(TeamStatusChip(status: t.status)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Phones: the same facts as a list row.
class _TeamTile extends StatelessWidget {
  const new({required this.team, required this.onTap});

  final AdminTeamRow team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(AppIcons.sport(team.sport)),
      title: Text(team.name),
      subtitle: Text(
        [
          if (team.ownerName.isNotEmpty) team.ownerName,
          l10n.membersCount(team.memberCount),
          formatBytes(team.storageBytes),
          l10n.adminLastActive(adminDate(l10n, team.lastMessageAt)),
        ].join(' · '),
      ),
      trailing: TeamStatusChip(status: team.status),
      onTap: onTap,
    );
  }
}
