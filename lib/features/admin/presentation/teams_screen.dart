import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
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

/// ADMIN-2 at `/admin/teams`: every team, searchable by name, filtered by
/// status, and sorted by any column either way (owner's request
/// 2026-11-14; newest first by default). A table on wide screens, whose
/// column headings sort it; a list on phones, with a Sort by menu.
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

  /// Sorts by [sort]: the same column again flips the direction; a new one
  /// starts A to Z for text, or newest or largest first.
  void _sortBy(AdminTeamSort sort) => setState(
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
        if (!wide)
          AdminSortMenu<AdminTeamSort>(
            value: _query.sort,
            values: AdminTeamSort.values,
            label: (s) => _sortLabel(l10n, s),
            ascending: _query.ascending,
            onSort: _sortBy,
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
            // A page that comes back empty with a cursor still has more
            // to look through: then it's Load more, not "No teams"
            // (ADMIN-2).
            AsyncValue(:final AdminList<AdminTeamRow> value)
                when value.items.isEmpty && value.reachedEnd =>
              EmptyState(icon: AppIcons.group, message: l10n.adminNoTeams),
            AsyncValue(:final AdminList<AdminTeamRow> value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide && value.items.isNotEmpty)
                  _TeamsTable(
                    rows: value.items,
                    sort: _query.sort,
                    ascending: _query.ascending,
                    onSort: _sortBy,
                    onOpen: open,
                  )
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
            _ => const SkeletonList(),
          },
        ],
      ),
    );
  }
}

/// A sort's name: its column's heading.
String _sortLabel(AppLocalizations l10n, AdminTeamSort s) => switch (s) {
  AdminTeamSort.name => l10n.adminColName,
  AdminTeamSort.sport => l10n.sportLabel,
  AdminTeamSort.owner => l10n.adminColOwner,
  AdminTeamSort.members => l10n.rosterMembers,
  AdminTeamSort.activity => l10n.adminColLastActivity,
  AdminTeamSort.storage => l10n.storageSection,
  AdminTeamSort.status => l10n.adminColStatus,
  AdminTeamSort.created => l10n.adminColCreated,
};

/// Wide screens: name, sport, owner, members, last activity, storage,
/// status, and created (ADMIN-2). Tapping a heading sorts by it, and
/// tapping it again flips the direction.
class _TeamsTable extends StatelessWidget {
  const new({
    required this.rows,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onOpen,
  });

  final List<AdminTeamRow> rows;
  final AdminTeamSort sort;
  final bool ascending;
  final ValueChanged<AdminTeamSort> onSort;
  final ValueChanged<AdminTeamRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        // The columns are in AdminTeamSort's order.
        sortColumnIndex: sort.index,
        sortAscending: ascending,
        columns: [
          for (final s in AdminTeamSort.values)
            DataColumn(
              label: Text(_sortLabel(l10n, s)),
              numeric: s == AdminTeamSort.members || s == AdminTeamSort.storage,
              onSort: (_, _) => onSort(s),
            ),
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
                DataCell(
                  Text(
                    adminDate(
                      l10n,
                      t.lastMessageAt,
                      zone: ViewerZone.of(context),
                    ),
                  ),
                ),
                DataCell(Text(formatBytes(t.storageBytes))),
                DataCell(TeamStatusChip(status: t.status)),
                DataCell(
                  Text(
                    adminDate(l10n, t.createdAt, zone: ViewerZone.of(context)),
                  ),
                ),
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
          l10n.adminLastActive(
            adminDate(l10n, team.lastMessageAt, zone: ViewerZone.of(context)),
          ),
        ].join(' · '),
      ),
      trailing: TeamStatusChip(status: team.status),
      onTap: onTap,
    );
  }
}
