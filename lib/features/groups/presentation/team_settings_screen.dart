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
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/chat_look_section.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Reminder choices for events, in minutes (SCHED-3).
const reminderChoices = [15, 60, 120, 1440, 2880, 10080];

/// TEAM-5 at `/g/:groupId/settings` (admins): name, sport, logo, color,
/// description, time zone, member permissions, default reminders, the chat
/// look, and storage used with Media. The invite link joins with the invite
/// screen.
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

  /// Super admins set this team's limit in MB (STORE-6).
  Future<void> _changeQuota(Group group) async {
    final l10n = AppLocalizations.of(context);
    final max = NumberFormat.decimalPattern(l10n.localeName)
        .format(Limits.storageQuotaMaxMb);
    final mb = await showDialog<int>(
      context: context,
      builder: (_) => _QuotaDialog(
        initialMb: group.storageQuotaBytes ~/ bytesPerMb,
        maxLabel: max,
      ),
    );
    if (mb == null || !mounted) return;
    try {
      await ref.read(groupRepositoryProvider).setStorageQuota(group.id, mb);
      if (mounted) {
        showAppSnackBar(
          context,
          l10n.storageLimitSaved(formatBytes(mb * bytesPerMb)),
        );
      }
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e is PermissionDenied ? l10n.notAllowed : l10n.profileSaveFailed,
        );
      }
    }
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
    final membership = ref.watch(myMembershipProvider(group.id));
    final isOwner = membership?.role == MemberRole.owner;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final isAdmin = (membership?.isAdmin ?? false) || superAdmin;
    // Full storage turns off a new logo too, with the one message (STORE-4).
    final full = group.storageFull;
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
                  style: full
                      ? TextButton.styleFrom(
                          foregroundColor: theme.disabledColor,
                        )
                      : null,
                  onPressed: full
                      ? () => showStorageFull(context)
                      : () async {
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
              // The chat's look for everyone on the team (CHAT-18).
              section(l10n.chatLook),
              ChatLookSection(group: group),
              // Storage used against the team's limit (STORE-2), with Media
              // to free space (STORE-5).
              section(l10n.storageSection),
              StorageMeter(
                usedBytes: group.storageBytes,
                quotaBytes: group.storageQuotaBytes,
              ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  if (isAdmin)
                    OutlinedButton.icon(
                      onPressed: () =>
                          unawaited(context.push('/g/${group.id.value}/media')),
                      icon: const Icon(AppIcons.media),
                      label: Text(l10n.mediaMenu),
                    ),
                  // Raising one team's limit isn't advertised (STORE-6):
                  // only super admins ever see it, until the admin panel
                  // (M8) takes it over.
                  if (superAdmin)
                    TextButton(
                      onPressed: () => unawaited(_changeQuota(group)),
                      child: Text(l10n.changeStorageLimit),
                    ),
                ],
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for a limit in whole MB, 1 to [Limits.storageQuotaMaxMb]; pops it
/// or null (STORE-6). The server checks the range again.
class _QuotaDialog extends StatefulWidget {
  const new({required this.initialMb, required this.maxLabel});

  final int initialMb;
  final String maxLabel;

  @override
  State<_QuotaDialog> createState() => _QuotaDialogState();
}

class _QuotaDialogState extends State<_QuotaDialog> {
  late final _mb = TextEditingController(
    text: widget.initialMb > 0 ? '${widget.initialMb}' : '',
  );
  String? _error;

  @override
  void dispose() {
    _mb.dispose();
    super.dispose();
  }

  void _submit() {
    final mb = int.tryParse(_mb.text.trim());
    if (mb == null || mb < 1 || mb > Limits.storageQuotaMaxMb) {
      setState(
        () =>
            _error = AppLocalizations.of(context)
                .storageLimitInvalid(widget.maxLabel),
      );
      return;
    }
    Navigator.of(context).pop(mb);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.storageLimitTitle),
      content: TextField(
        controller: _mb,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.storageLimitLabel,
          helperText: l10n.storageLimitHelp(widget.maxLabel),
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
