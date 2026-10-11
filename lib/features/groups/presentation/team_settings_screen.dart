import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/plan_section.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Reminder choices for events, in minutes (SCHED-3).
const reminderChoices = [15, 60, 120, 1440, 2880, 10080];

/// TEAM-5 at `/g/:groupId/settings` (admins): name, sport, logo, color,
/// description, time zone, member permissions, default reminders, and
/// storage used. The invite link joins with the invite screen.
class TeamSettingsScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save(
    Future<void> Function() action, {
    bool announce = true,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      if (mounted && announce) showAppSnackBar(context, l10n.profileSaved);
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e is PermissionDenied ? l10n.notAllowed : l10n.profileSaveFailed,
        );
      }
    }
  }

  Future<void> _transfer(Group group) async {
    final l10n = AppLocalizations.of(context);
    final members = await ref.read(rosterProvider(group.id).future);
    final others = members.where((m) => m.role != MemberRole.owner).toList();
    if (!mounted) return;
    final picked = await showDialog<Membership>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.transferTo),
        children: [
          for (final m in others)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(m),
              child: Text(m.displayName),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: '${l10n.transferOwnership}: ${picked.displayName}?',
      confirmLabel: l10n.transferOwnership,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    await _save(
      () => ref
          .read(groupRepositoryProvider)
          .transferOwnership(group.id, picked.uid),
    );
  }

  Future<void> _archive(Group group) async {
    final l10n = AppLocalizations.of(context);
    if (!group.isArchived) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.archiveTeam,
        message: l10n.archiveTeamBody,
        confirmLabel: l10n.archiveTeam,
        cancelLabel: l10n.cancel,
      );
      if (!ok) return;
    }
    await _save(
      () => ref
          .read(groupRepositoryProvider)
          .setArchived(group.id, archived: !group.isArchived),
    );
  }

  Future<void> _delete(Group group) async {
    final l10n = AppLocalizations.of(context);
    final typed = await askText(
      context,
      title: l10n.deleteTeam,
      label: group.name,
      helper: l10n.deleteTeamBody,
    );
    if (typed == null || !mounted) return;
    if (typed.trim() != group.name.trim()) {
      showAppSnackBar(context, l10n.methodInvalid);
      return;
    }
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group.id, typed);
      if (mounted) context.go('/');
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.signInUnknownError);
    }
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _size(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  String _reminderLabel(AppLocalizations l10n, int minutes) =>
      switch (minutes) {
        15 => l10n.reminder15m,
        60 => l10n.reminder1h,
        120 => l10n.reminder2h,
        1440 => l10n.reminder1d,
        2880 => l10n.reminder2d,
        _ => l10n.reminder1w,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final repo = ref.read(groupRepositoryProvider);
    if (group == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.teamSettingsMenu)));
    }
    if (!_loaded) {
      _name.text = group.name;
      _description.text = group.description ?? '';
      _loaded = true;
    }
    final s = group.settings;
    final isOwner =
        ref.watch(myMembershipProvider(group.id))?.role == MemberRole.owner;
    void setSettings(GroupSettings next) => unawaited(
      _save(() => repo.updateGroup(group.id, settings: next), announce: false),
    );
    final logoUrl = group.photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(group.photoPath!)).value;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm),
      child: Text(title, style: theme.textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamSettingsMenu)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              Center(
                child: TeamBadge(
                  name: group.name,
                  color: group.color == null ? null : Color(group.color!),
                  imageUrl: logoUrl,
                  size: 72,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final bytes = await ref
                        .read(photoPickerProvider)
                        .pickProfilePhoto();
                    if (bytes == null) return;
                    await _save(() => repo.uploadLogo(group.id, bytes));
                  },
                  child: Text(l10n.changeLogo),
                ),
              ),
              TextField(
                controller: _name,
                maxLength: Limits.groupNameMax,
                decoration: InputDecoration(
                  labelText: l10n.teamNameLabel,
                  counterText: '',
                ),
                onSubmitted: (v) => v.trim().isEmpty
                    ? null
                    : _save(() => repo.updateGroup(group.id, name: v)),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _description,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: l10n.teamDescriptionLabel,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _save(
                    () => repo.updateGroup(
                      group.id,
                      name: _name.text.trim().isEmpty ? null : _name.text,
                      description: _description.text,
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ),
              const SizedBox(height: Space.lg),
              DropdownButtonFormField<Sport>(
                initialValue: group.sport,
                decoration: InputDecoration(labelText: l10n.sportLabel),
                items: [
                  for (final sp in Sport.values)
                    DropdownMenuItem(
                      value: sp,
                      child: Text(sportName(l10n, sp)),
                    ),
                ],
                onChanged: (sp) => sp == null
                    ? null
                    : _save(() => repo.updateGroup(group.id, sport: sp)),
              ),
              section(l10n.teamColorLabel),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final c in teamColorValues)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _save(
                        () => repo.updateGroup(group.id, color: _hex(c)),
                        announce: false,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(c),
                        child: c == group.color
                            ? const Icon(AppIcons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.timeZoneLabel),
                subtitle: Text(group.timeZone),
              ),
              section(l10n.memberPermissions),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permCreateEvents),
                value: s.membersCanCreateEvents,
                onChanged: (v) =>
                    setSettings(s.copyWith(membersCanCreateEvents: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permCreatePolls),
                value: s.membersCanCreatePolls,
                onChanged: (v) =>
                    setSettings(s.copyWith(membersCanCreatePolls: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permUploadDocs),
                value: s.membersCanUploadDocs,
                onChanged: (v) =>
                    setSettings(s.copyWith(membersCanUploadDocs: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permInvite),
                value: s.membersCanInvite,
                onChanged: (v) => setSettings(s.copyWith(membersCanInvite: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permAllowMaybe),
                value: s.allowMaybe,
                onChanged: (v) => setSettings(s.copyWith(allowMaybe: v)),
              ),
              section(l10n.defaultReminders),
              Wrap(
                spacing: Space.sm,
                children: [
                  for (final m in reminderChoices)
                    FilterChip(
                      label: Text(_reminderLabel(l10n, m)),
                      selected: s.defaultReminderOffsets.contains(m),
                      onSelected: (on) {
                        final next = {...s.defaultReminderOffsets};
                        on ? next.add(m) : next.remove(m);
                        setSettings(
                          s.copyWith(
                            defaultReminderOffsets: next.toList()..sort(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              // Free or Plus, and the license (PLAN-4).
              section(l10n.planSection),
              PlanSection(group: group),
              // Storage used against the team's quota (D16).
              section(l10n.storageSection),
              if (group.storageQuotaBytes > 0) ...[
                LinearProgressIndicator(
                  value: (group.storageBytes / group.storageQuotaBytes).clamp(
                    0,
                    1,
                  ),
                ),
                const SizedBox(height: Space.xs),
              ],
              Text(
                l10n.storageUsed(
                  formatBytes(group.storageBytes),
                  formatBytes(group.storageQuotaBytes),
                ),
              ),
              if (isOwner) ...[
                section(l10n.ownerActions),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.transferOwnership),
                  onTap: () => _transfer(group),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    group.isArchived ? l10n.restoreTeam : l10n.archiveTeam,
                  ),
                  onTap: () => _archive(group),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.deleteTeam,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () => _delete(group),
                ),
              ],
              section(l10n.storage),
              Text(
                l10n.storageUsed(
                  _size(group.storageBytes),
                  _size(group.storageQuotaBytes),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "0 B", "512 KB", "1.2 GB": sizes for the storage meter.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 || value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
