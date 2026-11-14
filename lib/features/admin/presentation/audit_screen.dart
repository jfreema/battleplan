import 'dart:async';
import 'dart:convert';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-6 at `/admin/audit`: every admin or destructive action, filtered
/// by person, action, team, or dates, and sorted by any column either way
/// (owner's request 2026-11-14; newest first by default). Read-only. Each
/// entry opens its before and after values. `?actor=` and `?group=` start
/// it filtered (a person's or a team's admin page links here). The table's
/// headings sort it on wide screens; a Sort by menu does on phones.
class AdminAuditScreen extends ConsumerStatefulWidget {
  const new({this.actorId, this.groupId, super.key});

  final String? actorId;
  final String? groupId;

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  late final _actor = TextEditingController(text: widget.actorId);
  late final _action = TextEditingController();
  late final _group = TextEditingController(text: widget.groupId);
  DateTimeRange? _dates;
  AuditSort _sort = AuditSort.when;
  bool _ascending = false;
  late AuditFilter _filter = _read();

  @override
  void dispose() {
    _actor.dispose();
    _action.dispose();
    _group.dispose();
    super.dispose();
  }

  /// The filter the fields describe; a blank field matches all.
  AuditFilter _read() {
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final group = text(_group);
    final range = switch (_dates) {
      final dates? => auditRange(dates, ViewerZone.read(context)),
      null => null,
    };
    return AuditFilter(
      actorId: text(_actor),
      action: text(_action),
      groupId: group == null ? null : GroupId(group),
      from: range?.from,
      until: range?.until,
      sort: _sort,
      ascending: _ascending,
    );
  }

  void _apply() => setState(() => _filter = _read());

  /// Sorts by [sort]: the same column again flips the direction; a new one
  /// starts A to Z, or newest first for When. It keeps the filters as last
  /// applied, not as half typed.
  void _sortBy(AuditSort sort) {
    _ascending = sort == _sort ? !_ascending : sort.ascendingFirst;
    _sort = sort;
    setState(
      () => _filter = _filter.copyWith(sort: _sort, ascending: _ascending),
    );
  }

  void _clear() {
    _actor.clear();
    _action.clear();
    _group.clear();
    _dates = null;
    _apply();
  }

  Future<void> _pickDates() async {
    // Days in the viewer's zone (SET-7), up to its today.
    final now = wallClockIn(ViewerZone.read(context), DateTime.now());
    final today = DateTime(now.year, now.month, now.day);
    // Entries are kept for a year (ADMIN-6).
    final first = DateTime(today.year - 1, today.month, today.day);
    final dates = _dates;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      currentDate: today,
      // A range picked before today moved (past midnight, or a new zone)
      // can fall outside it, which the picker doesn't allow.
      initialDateRange:
          dates == null ||
              dates.start.isBefore(first) ||
              dates.end.isAfter(today)
          ? null
          : dates,
    );
    if (picked == null) return;
    _dates = picked;
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final log = ref.watch(adminAuditProvider(_filter));
    final wide = isWide(context);

    Widget field(TextEditingController c, String label) => SizedBox(
      width: 220,
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, isDense: true),
        onSubmitted: (_) => _apply(),
      ),
    );

    final filters = Wrap(
      spacing: Space.md,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        field(_actor, l10n.adminFilterPerson),
        field(_action, l10n.adminFilterAction),
        field(_group, l10n.adminFilterTeam),
        OutlinedButton.icon(
          onPressed: () => unawaited(_pickDates()),
          icon: const Icon(AppIcons.schedule),
          label: Text(
            _dates == null
                ? l10n.adminFilterDates
                : '${adminDate(l10n, _dates!.start)} – ${adminDate(l10n, _dates!.end)}',
          ),
        ),
        FilledButton(onPressed: _apply, child: Text(l10n.adminApplyFilters)),
        if (!_filter.isEmpty)
          TextButton(onPressed: _clear, child: Text(l10n.adminClearFilters)),
        if (!wide)
          AdminSortMenu<AuditSort>(
            value: _sort,
            values: AuditSort.values,
            label: (s) => _sortLabel(l10n, s),
            ascending: _ascending,
            onSort: _sortBy,
          ),
      ],
    );

    return AdminScaffold(
      section: AdminSection.audit,
      title: l10n.adminAuditLog,
      // A person's or a team's entries, opened from their page, go back
      // there.
      detail: widget.actorId != null || widget.groupId != null,
      body: AdminBody(
        children: [
          filters,
          const SizedBox(height: Space.lg),
          switch (log) {
            AsyncValue(:final AdminList<AuditEntry> value)
                when value.items.isEmpty =>
              EmptyState(icon: AppIcons.history, message: l10n.adminNoAudit),
            AsyncValue(:final AdminList<AuditEntry> value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  _AuditTable(
                    entries: value.items,
                    sort: _sort,
                    ascending: _ascending,
                    onSort: _sortBy,
                  )
                else
                  for (final e in value.items) _AuditTile(entry: e),
                if (!value.reachedEnd)
                  LoadMoreButton(
                    loading: value.loadingMore,
                    onPressed: () => ref
                        .read(adminAuditProvider(_filter).notifier)
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

/// Who did it: their name once their profile loads, their uid before.
class _Actor extends ConsumerWidget {
  const new({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = uid.isEmpty
        ? null
        : ref.watch(adminPersonNameProvider(uid)).value;
    return Text(name == null || name.isEmpty ? uid : name);
  }
}

Future<void> _showEntry(BuildContext context, AuditEntry e) =>
    showAdaptiveSheet<void>(context, builder: (_) => _EntryDetails(entry: e));

/// The instants a filter by the picked [dates] runs between: the start of
/// the first day and the start of the day after the last, in [zone] (the
/// viewer's, SET-7), or on this device while that's unknown.
({DateTime from, DateTime until}) auditRange(
  DateTimeRange dates,
  String? zone,
) {
  DateTime start(int year, int month, int day) => zone == null
      ? DateTime(year, month, day)
      : ZonedTime.instantOf(zone, DateTime.utc(year, month, day), 0);
  final DateTimeRange(start: first, end: last) = dates;
  return (
    from: start(first.year, first.month, first.day),
    until: start(last.year, last.month, last.day + 1),
  );
}

/// A sort's name: its column's heading.
String _sortLabel(AppLocalizations l10n, AuditSort s) => switch (s) {
  AuditSort.when => l10n.adminColWhen,
  AuditSort.who => l10n.adminColWho,
  AuditSort.action => l10n.adminColAction,
  AuditSort.team => l10n.adminColTeam,
  AuditSort.target => l10n.adminColTarget,
};

/// The log as a table; tapping a column's heading sorts by it, and tapping
/// it again flips the direction.
class _AuditTable extends StatelessWidget {
  const new({
    required this.entries,
    required this.sort,
    required this.ascending,
    required this.onSort,
  });

  final List<AuditEntry> entries;
  final AuditSort sort;
  final bool ascending;
  final ValueChanged<AuditSort> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        // The columns are in AuditSort's order.
        sortColumnIndex: sort.index,
        sortAscending: ascending,
        columns: [
          for (final s in AuditSort.values)
            DataColumn(
              label: Text(_sortLabel(l10n, s)),
              onSort: (_, _) => onSort(s),
            ),
        ],
        rows: [
          for (final e in entries)
            DataRow(
              onSelectChanged: (_) => unawaited(_showEntry(context, e)),
              cells: [
                DataCell(
                  Text(
                    adminDateTime(
                      l10n,
                      e.createdAt,
                      zone: ViewerZone.of(context),
                    ),
                  ),
                ),
                DataCell(_Actor(uid: e.actorId)),
                DataCell(Text(e.action)),
                DataCell(Text(e.groupId?.value ?? '—')),
                DataCell(Text('${e.targetType} ${e.targetId}'.trim())),
              ],
            ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const new({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.action),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Actor(uid: entry.actorId),
          Text(
            [
              adminDateTime(
                l10n,
                entry.createdAt,
                zone: ViewerZone.of(context),
              ),
              ?entry.groupId?.value,
            ].join(' · '),
          ),
        ],
      ),
      onTap: () => unawaited(_showEntry(context, entry)),
    );
  }
}

/// One entry in full, with its before and after values (ADMIN-6).
class _EntryDetails extends StatelessWidget {
  const new({required this.entry});

  final AuditEntry entry;

  static String _pretty(Map<String, Object?>? values) =>
      values == null ? '—' : const JsonEncoder.withIndent('  ').convert(values);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final e = entry;
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          value,
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.action, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            row(
              l10n.adminColWhen,
              Text(
                adminDateTime(l10n, e.createdAt, zone: ViewerZone.of(context)),
              ),
            ),
            row(
              l10n.adminColWho,
              Row(
                children: [
                  Flexible(child: _Actor(uid: e.actorId)),
                  TextButton(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      unawaited(router.push('/admin/users/${e.actorId}'));
                    },
                    child: Text(l10n.adminOpenUser),
                  ),
                ],
              ),
            ),
            if (e.groupId case final g?)
              row(
                l10n.adminColTeam,
                Row(
                  children: [
                    Flexible(child: SelectableText(g.value)),
                    TextButton(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        unawaited(router.push('/admin/teams/${g.value}'));
                      },
                      child: Text(l10n.adminOpenTeam),
                    ),
                  ],
                ),
              ),
            row(
              l10n.adminColTarget,
              SelectableText('${e.targetType} ${e.targetId}'.trim()),
            ),
            row(
              l10n.adminBefore,
              SelectableText(_pretty(e.before), style: mono),
            ),
            row(l10n.adminAfter, SelectableText(_pretty(e.after), style: mono)),
          ],
        ),
      ),
    );
  }
}
