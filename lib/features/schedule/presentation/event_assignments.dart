import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/assignment.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/schedule_rules.dart';
import 'package:battleplan/features/schedule/presentation/event_actions.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The name of an assignment's kind (SCHED-15).
String assignmentKindName(AppLocalizations l10n, AssignmentKind kind) =>
    switch (kind) {
      AssignmentKind.snacks => l10n.assignmentKindSnacks,
      AssignmentKind.drinks => l10n.assignmentKindDrinks,
      AssignmentKind.scorekeeper => l10n.assignmentKindScorekeeper,
      AssignmentKind.other => l10n.assignmentKindOther,
    };

/// What an assignment is called: its kind, with its details after
/// ("Snacks · Halftime oranges"), or its own name for "other".
String assignmentTitle(AppLocalizations l10n, Assignment a) {
  final label = a.label;
  if (a.kind == AssignmentKind.other) return label ?? l10n.assignmentKindOther;
  final kind = assignmentKindName(l10n, a.kind);
  return label == null ? kind : '$kind · $label';
}

IconData _kindIcon(AssignmentKind kind) => switch (kind) {
  AssignmentKind.snacks => AppIcons.snacks,
  AssignmentKind.drinks => AppIcons.drinks,
  AssignmentKind.scorekeeper => AppIcons.scorekeeper,
  AssignmentKind.other => AppIcons.assignmentOther,
};

GumdropAccent _kindAccent(GumdropColors c, AssignmentKind kind) =>
    switch (kind) {
      AssignmentKind.snacks => c.tangerine,
      AssignmentKind.drinks => c.blueRaspberry,
      AssignmentKind.scorekeeper => c.grape,
      AssignmentKind.other => c.mint,
    };

/// The Assignments row near the bottom of an event's page (SCHED-15): a
/// secondary part of the event, so it's one line that opens the list.
/// Members see it once the event has assignments; admins always, to add
/// the first.
class AssignmentsRow extends ConsumerWidget {
  const new({
    required this.event,
    required this.group,
    required this.me,
    super.key,
  });

  final Event event;
  final Group group;
  final Membership? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canManage = canManageAssignments(group, me, superAdmin: superAdmin);
    final list =
        ref.watch(eventAssignmentsProvider(event.groupId, event.id)).value ??
        const <Assignment>[];
    if (list.isEmpty && !canManage) return const SizedBox.shrink();

    final myUid = me?.uid.value;
    final mine = [
      for (final a in list)
        if (myUid != null && a.isHeldBy(myUid)) assignmentTitle(l10n, a),
    ];
    final taken = list.where((a) => !a.isOpen).length;
    final summary = list.isEmpty
        ? l10n.assignmentsRowAdd
        : mine.isNotEmpty
        ? l10n.assignmentsRowMine(mine.join(', '))
        : taken == 0
        ? l10n.assignmentsRowAllOpen(list.length)
        : l10n.assignmentsRowSummary(taken, list.length);

    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    return GumdropCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => unawaited(
            context.push(
              '/g/${event.groupId.value}/schedule/e/${event.id.value}/assignments',
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                _Disc(icon: AppIcons.assignments, color: c.card.well),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.assignmentsTitle,
                        style: text.titleSmall?.copyWith(
                          color: c.card.textPrimary,
                        ),
                      ),
                      Text(
                        summary,
                        style: text.bodySmall?.copyWith(
                          color: c.card.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, color: c.card.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An event's assignments (SCHED-15): each task, who has it, Volunteer or
/// Drop out, and for admins adding, assigning, editing, and removing.
class EventAssignmentsScreen extends ConsumerWidget {
  const new({required this.groupId, required this.eventId, super.key});

  final GroupId groupId;
  final EventId eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventProvider(eventId));
    final event = async.value;
    final group = ref.watch(groupProvider(groupId)).value;
    if (event == null || group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading || group == null
            ? const SkeletonList()
            : EmptyState(icon: AppIcons.event, message: l10n.eventNotFound),
      );
    }
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canManage = canManageAssignments(group, me, superAdmin: superAdmin);
    final volunteer = canVolunteer(group, me);
    final list =
        ref.watch(eventAssignmentsProvider(groupId, eventId)).value ??
        const <Assignment>[];
    final roster =
        ref.watch(rosterProvider(groupId)).value ?? const <Membership>[];
    final names = {for (final m in roster) m.uid.value: m.displayName};
    final myUid = me?.uid.value;
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    final full = list.length >= Limits.assignmentsPerEventMax;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assignmentsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxl),
            children: [
              Text(
                event.title,
                style: text.titleMedium?.copyWith(color: c.textOnPage),
              ),
              const SizedBox(height: Space.xs),
              Text(
                list.isEmpty
                    ? (canManage
                          ? l10n.assignmentsEmptyAdmin
                          : l10n.assignmentsEmpty)
                    : l10n.assignmentsIntro,
                style: text.bodyMedium?.copyWith(color: c.textMutedOnPage),
              ),
              const SizedBox(height: Space.lg),
              for (final a in list) ...[
                _AssignmentTile(
                  assignment: a,
                  holder: a.assigneeUid == null
                      ? null
                      : a.isHeldBy(myUid ?? '')
                      ? l10n.assignmentYou
                      : names[a.assigneeUid] ?? '',
                  mine: myUid != null && a.isHeldBy(myUid),
                  canVolunteer: volunteer && a.isOpen,
                  canManage: canManage,
                  me: myUid == null ? null : UserId(myUid),
                  roster: roster,
                ),
                const SizedBox(height: Space.sm),
              ],
              if (canManage) ...[
                const SizedBox(height: Space.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: full || myUid == null && !superAdmin
                        ? null
                        : () => unawaited(
                            _addAssignment(context, ref, event, roster),
                          ),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.assignmentAdd),
                  ),
                ),
                if (full) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    l10n.assignmentsFull(Limits.assignmentsPerEventMax),
                    style: text.bodySmall?.copyWith(color: c.textMutedOnPage),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addAssignment(
    BuildContext context,
    WidgetRef ref,
    Event event,
    List<Membership> roster,
  ) async {
    final draft = await showAdaptiveSheet<_Draft>(
      context,
      builder: (_) => _AssignmentEditor(roster: roster),
    );
    if (draft == null || !context.mounted) return;
    final by = ref.read(authUserProvider).value?.uid;
    if (by == null) return;
    await _run(
      context,
      () => ref
          .read(assignmentRepositoryProvider)
          .add(
            event,
            kind: draft.kind,
            label: draft.label,
            assignee: draft.assignee,
            by: UserId(by),
          ),
    );
  }
}

/// Runs an assignment write, and says so if it's refused or fails.
Future<void> _run(
  BuildContext context,
  Future<void> Function() write, {
  String? refused,
}) async {
  try {
    await write();
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    if (refused != null && e is PermissionDenied) {
      showAppSnackBar(context, refused);
    } else {
      showSaveFailure(context, e);
    }
  }
}

class _Disc extends StatelessWidget {
  const new({required this.icon, required this.color, this.iconColor});

  final IconData icon;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(
      icon,
      size: 21,
      color: iconColor ?? GumdropColors.of(context).card.textPrimary,
    ),
  );
}

/// One task: what it is, who has it, and what I can do with it.
class _AssignmentTile extends ConsumerWidget {
  const new({
    required this.assignment,
    required this.holder,
    required this.mine,
    required this.canVolunteer,
    required this.canManage,
    required this.me,
    required this.roster,
  });

  final Assignment assignment;

  /// "You", the person's name, or null while it's open.
  final String? holder;
  final bool mine;
  final bool canVolunteer;
  final bool canManage;
  final UserId? me;
  final List<Membership> roster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final card = c.card;
    final text = Theme.of(context).textTheme;
    final a = assignment;
    final repo = ref.read(assignmentRepositoryProvider);
    final title = assignmentTitle(l10n, a);
    final who = holder;
    final status = who == null
        ? l10n.assignmentOpen
        : who.isEmpty
        ? ''
        : a.volunteered || mine
        ? (mine ? who : l10n.assignmentVolunteered(who))
        : l10n.assignmentAssigned(who);
    final accent = _kindAccent(c, a.kind);
    final buttons = GumdropButtons.of(context);

    return GumdropCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          _Disc(icon: _kindIcon(a.kind), color: accent.face, iconColor: c.ink),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(color: card.textPrimary),
                ),
                if (status.isNotEmpty)
                  Text(
                    status,
                    style: text.bodySmall?.copyWith(
                      color: who == null ? card.textMuted : card.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          if (canVolunteer && me != null)
            FilledButton(
              style: buttons.accent(
                c.mint,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => unawaited(
                _run(
                  context,
                  () => repo.volunteer(a, me!),
                  refused: l10n.assignmentTaken,
                ),
              ),
              child: Text(l10n.assignmentVolunteer),
            )
          else if (mine)
            OutlinedButton(
              style: buttons.secondary(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => unawaited(_run(context, () => repo.giveUp(a))),
              child: Text(l10n.assignmentDropOut),
            ),
          if (canManage)
            PopupMenuButton<_Action>(
              tooltip: l10n.assignmentMenu(title),
              icon: Icon(AppIcons.more, color: card.textMuted),
              onSelected: (action) =>
                  unawaited(_onAction(context, ref, action)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _Action.assign,
                  child: Text(l10n.assignmentAssignSomeone),
                ),
                if (!a.isOpen)
                  PopupMenuItem(
                    value: _Action.open,
                    child: Text(l10n.assignmentMakeOpen),
                  ),
                PopupMenuItem(
                  value: _Action.edit,
                  child: Text(l10n.assignmentEdit),
                ),
                PopupMenuItem(
                  value: _Action.remove,
                  child: Text(l10n.assignmentRemove),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(assignmentRepositoryProvider);
    final by = ref.read(authUserProvider).value?.uid;
    final a = assignment;
    switch (action) {
      case _Action.assign:
        final picked = await showAdaptiveSheet<_Pick>(
          context,
          builder: (_) => _PersonPicker(
            roster: roster,
            selected: a.assigneeUid,
            title: l10n.assignmentAssignSomeone,
          ),
        );
        if (picked == null || by == null || !context.mounted) return;
        await _run(
          context,
          () => repo.assign(
            a,
            picked.uid == null ? null : UserId(picked.uid!),
            by: UserId(by),
          ),
        );
      case _Action.open:
        if (by == null) return;
        await _run(context, () => repo.assign(a, null, by: UserId(by)));
      case _Action.edit:
        final draft = await showAdaptiveSheet<_Draft>(
          context,
          builder: (_) => _AssignmentEditor(editing: a),
        );
        if (draft == null || !context.mounted) return;
        await _run(
          context,
          () => repo.edit(a, kind: draft.kind, label: draft.label),
        );
      case _Action.remove:
        final ok = await showConfirmDialog(
          context,
          title: l10n.assignmentRemoveTitle,
          message: assignmentTitle(l10n, a),
          confirmLabel: l10n.assignmentRemove,
          cancelLabel: l10n.cancel,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await _run(context, () => repo.remove(a));
    }
  }
}

enum _Action { assign, open, edit, remove }

/// A person picked for a task, or nobody (a null uid: open).
typedef _Pick = ({String? uid});

/// A new or changed task, from [_AssignmentEditor].
typedef _Draft = ({AssignmentKind kind, String? label, UserId? assignee});

/// Adding a task (with whom, optionally) or changing one's kind and
/// details (SCHED-15).
class _AssignmentEditor extends StatefulWidget {
  const new({this.editing, this.roster = const []});

  /// The task being changed, or null for a new one.
  final Assignment? editing;

  /// The team, for "Assign to" on a new task.
  final List<Membership> roster;

  @override
  State<_AssignmentEditor> createState() => _AssignmentEditorState();
}

class _AssignmentEditorState extends State<_AssignmentEditor> {
  late AssignmentKind _kind = widget.editing?.kind ?? AssignmentKind.snacks;
  late final _label = TextEditingController(text: widget.editing?.label);
  String? _assignee;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  bool get _valid =>
      _kind != AssignmentKind.other || _label.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final other = _kind == AssignmentKind.other;
    final adding = widget.editing == null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.xl,
          Space.sm,
          Space.xl,
          Space.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              adding ? l10n.assignmentAddTitle : l10n.assignmentEditTitle,
              style: text.titleLarge,
            ),
            const SizedBox(height: Space.lg),
            Text(l10n.assignmentKindLabel, style: text.labelLarge),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final k in AssignmentKind.values)
                  ChoiceChip(
                    label: Text(assignmentKindName(l10n, k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _label,
              maxLength: Limits.assignmentLabelMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: other
                    ? l10n.assignmentNameLabel
                    : l10n.assignmentDetailsLabel,
                hintText: other
                    ? l10n.assignmentNameHint
                    : l10n.assignmentDetailsHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (adding && widget.roster.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String?>(
                initialValue: _assignee,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.assignmentAssignTo),
                items: [
                  DropdownMenuItem(child: Text(l10n.assignmentNobody)),
                  for (final m in widget.roster)
                    DropdownMenuItem(
                      value: m.uid.value,
                      child: Text(
                        m.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (uid) => setState(() => _assignee = uid),
              ),
            ],
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _valid
                  ? () => Navigator.of(context).pop<_Draft>((
                      kind: _kind,
                      label: _label.text.trim().isEmpty
                          ? null
                          : _label.text.trim(),
                      assignee: _assignee == null ? null : UserId(_assignee!),
                    ))
                  : null,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks who has a task: anyone on the team, or nobody (open).
class _PersonPicker extends StatelessWidget {
  const new({
    required this.roster,
    required this.selected,
    required this.title,
  });

  final List<Membership> roster;
  final String? selected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget row(String? uid, String name) => ListTile(
      title: Text(name),
      trailing: uid == selected ? const Icon(AppIcons.check) : null,
      selected: uid == selected,
      onTap: () => Navigator.of(context).pop<_Pick>((uid: uid)),
    );
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: Space.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.sm,
              Space.xl,
              Space.sm,
            ),
            child: Text(title, style: text.titleLarge),
          ),
          row(null, l10n.assignmentNobody),
          for (final m in roster) row(m.uid.value, m.displayName),
        ],
      ),
    );
  }
}
