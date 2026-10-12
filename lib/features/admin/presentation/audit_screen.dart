import 'dart:async';
import 'dart:convert';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-6 at `/admin/audit`: every admin or destructive action, newest
/// first, filtered by person, action, team, or dates. Read-only. Each
/// entry opens its before and after values. `?actor=` and `?group=` start
/// it filtered (a person's or a team's admin page links here).
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
    return AuditFilter(
      actorId: text(_actor),
      action: text(_action),
      groupId: group == null ? null : GroupId(group),
      from: _dates?.start,
      until: _dates?.end,
    );
  }

  void _apply() => setState(() => _filter = _read());

  void _clear() {
    _actor.clear();
    _action.clear();
    _group.clear();
    _dates = null;
    _apply();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      // Entries are kept for a year (ADMIN-6).
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      initialDateRange: _dates,
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
      ],
    );

    return AdminScaffold(
      section: AdminSection.audit,
      title: l10n.adminAuditLog,
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
                  _AuditTable(entries: value.items)
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
            _ => const Center(child: CircularProgressIndicator()),
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

class _AuditTable extends StatelessWidget {
  const new({required this.entries});

  final List<AuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(label: Text(l10n.adminColWhen)),
          DataColumn(label: Text(l10n.adminColWho)),
          DataColumn(label: Text(l10n.adminColAction)),
          DataColumn(label: Text(l10n.adminColTeam)),
          DataColumn(label: Text(l10n.adminColTarget)),
        ],
        rows: [
          for (final e in entries)
            DataRow(
              onSelectChanged: (_) => unawaited(_showEntry(context, e)),
              cells: [
                DataCell(Text(adminDateTime(l10n, e.createdAt))),
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
              adminDateTime(l10n, entry.createdAt),
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
            row(l10n.adminColWhen, Text(adminDateTime(l10n, e.createdAt))),
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
