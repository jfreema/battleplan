import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/about_battleplan.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/application/team_editor.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/chat_bubble_colors.dart';
import 'package:battleplan/features/groups/presentation/chat_look_section.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Reminder choices for events, in minutes (SCHED-3).
const reminderChoices = [15, 60, 120, 1440, 2880, 10080];

/// TEAM-5 at `/g/:groupId/settings` (admins): name, sport, logo, color,
/// description, time zone, member permissions, default
/// reminders, the invite link (managed on the invite screen), the chat look,
/// and storage used with Media.
class TeamSettingsScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.appBuild, super.key});

  final GroupId groupId;

  /// For About: the version and build (ARCH §9).
  final AppBuild appBuild;

  @override
  ConsumerState<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final GlobalKey _chatLookKey = GlobalKey();
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

  /// Picks a time zone from the device's list (TEAM-5), with search.
  Future<void> _changeTimeZone(Group group, TeamEditor repo) async {
    final zones = await ref.read(timeZonesProvider).available();
    if (!mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => _TimeZonePicker(
        zones: TimeZoneNames.ordered(zones, keep: [group.timeZone]),
        current: group.timeZone,
      ),
    );
    if (picked == null || picked == group.timeZone || !mounted) return;
    await _save(() => repo.update(group.id, timeZone: picked));
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

  /// Makes this basic group a team (TEAM-14), with the sport picked here.
  /// It can't be undone, so it says what changes first.
  Future<void> _convert(Group group) async {
    final l10n = AppLocalizations.of(context);
    var sport = Sport.baseball;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialog) => AlertDialog(
          title: Text(l10n.convertToTeamTitle(group.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.convertToTeamBody),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<Sport>(
                initialValue: sport,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.sportLabel),
                items: [
                  for (final s in Sport.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        sportName(l10n, s),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (s) => setDialog(() => sport = s ?? sport),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.convertToTeam),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(groupRepositoryProvider).convertToTeam(group.id, sport);
      if (mounted) showAppSnackBar(context, l10n.convertedToTeam(group.name));
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e is PermissionDenied ? l10n.notAllowed : l10n.convertToTeamFailed,
      );
    }
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
      if (mounted) showAppSnackBar(context, l10n.errorDeleteTeam);
    }
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Picks and uploads a new team logo (TEAM-5).
  Future<void> _changeLogo(GroupId id) async {
    final bytes = await ref.read(photoPickerProvider).pickProfilePhoto();
    if (bytes == null || !mounted) return;
    if (!fitsUploadLimit(context, ref, bytes.length)) return;
    // Storage filled while the picker was open: say so rather than upload
    // into a refusal (STORE-4).
    if (ref.read(groupProvider(id)).value?.storageFull ?? false) {
      showStorageFull(context);
      return;
    }
    await _save(() => ref.read(teamEditorProvider(id)).uploadLogo(id, bytes));
  }

  /// Super admins set this team's limit in MB (STORE-6).
  Future<void> _changeQuota(Group group) async {
    await changeStorageQuota(context, ref, group);
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
    if (group == null) {
      return Scaffold(appBar: gumdropAppBar(context, title: l10n.teamAdmin));
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
    // A super admin who isn't one of its admins saves through the audited
    // admin callable (ADMIN-3).
    final repo = ref.watch(teamEditorProvider(group.id));
    // Full storage turns off a new logo too, with the one message (STORE-4).
    final full = group.storageFull;
    void setSettings(GroupSettings next) => unawaited(
      _save(() => repo.update(group.id, settings: next), announce: false),
    );
    final logoUrl = group.photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(group.photoPath!)).value;

    final c = GumdropColors.of(context);
    final text = theme.textTheme;
    const gap = SizedBox(height: 12);
    const headingGap = SizedBox(height: 10);
    final look = group.chatTheme ?? const ChatTheme();
    final candy = look.bubbleColor == null
        ? chatCandyOrder(c.flavor).first
        : ChatCandy.fromStored(look.bubbleColor);
    final lookColor = candy == null
        ? l10n.teamColorOption
        : chatCandyName(l10n, candy);
    final lookBackground = switch (look.background) {
      ChatBackground.plain => l10n.backgroundPlain,
      ChatBackground.pattern => l10n.backgroundPattern,
      ChatBackground.photo => l10n.backgroundPhoto,
    };

    Widget switchRow({
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged,
      String? subtitle,
    }) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 44,
      title: Text(title, style: switchRowTitle(context)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: c.card.textMuted),
            ),
      value: value,
      onChanged: onChanged,
    );

    // A card with a heading and switch rows (design §3.5 "permissions").
    Widget switchCard(String heading, List<Widget> rows) => SettingsCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      divided: false,
      children: [
        CardHeading(heading),
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) Divider(height: 2, color: c.card.divider),
          row,
        ],
      ],
    );

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: group.isGroup ? l10n.groupAdmin : l10n.teamAdmin,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          // Built whole, not lazily: a settings page, short enough, and
          // every row is there to scroll to (the Chat look row).
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The team: logo, name, sport (design §3.5 "Team section").
                SettingsPanel(
                  radius: Corners.panel,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  child: Builder(
                    builder: (context) {
                      final card = GumdropColors.of(context);
                      final field = gumdropFieldText(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The logo button goes under the name when the
                          // panel is too narrow for one row (Slide Over, or
                          // large text).
                          LayoutBuilder(
                            builder: (context, box) {
                              final scale =
                                  MediaQuery.textScalerOf(context).scale(14) /
                                  14;
                              final wide = box.maxWidth >= 300 * scale;
                              final badge = DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: card.divider,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: TeamBadge(
                                  name: group.name,
                                  color: group.color == null
                                      ? null
                                      : Color(group.color!),
                                  imageUrl: logoUrl,
                                  size: 58,
                                ),
                              );
                              final name = Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleMedium?.copyWith(
                                        fontSize: 23,
                                        height: 1.15,
                                        color: card.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      group.hasPlayers
                                          ? sportName(l10n, group.sport)
                                          : l10n.kindGroup,
                                      style: text.bodyMedium?.copyWith(
                                        color: card.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              final button = OutlinedButton.icon(
                                style: GumdropButtons.of(context)
                                    .secondary(
                                      height: 37,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      textStyle: text.labelMedium,
                                    )
                                    .copyWith(
                                      foregroundColor: full
                                          ? WidgetStatePropertyAll(
                                              card.textMuted,
                                            )
                                          : null,
                                    ),
                                onPressed: full
                                    ? () => showStorageFull(context)
                                    : () => unawaited(_changeLogo(group.id)),
                                icon: const Icon(AppIcons.edit, size: 15),
                                label: Text(l10n.changeLogo),
                              );
                              final top = Row(
                                children: [
                                  badge,
                                  const SizedBox(width: 12),
                                  name,
                                  if (wide) ...[
                                    const SizedBox(width: 8),
                                    button,
                                  ],
                                ],
                              );
                              if (wide) return top;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  top,
                                  const SizedBox(height: 9),
                                  button,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 9),
                          LabeledField(
                            label: l10n.teamNameLabel,
                            child: TextField(
                              controller: _name,
                              maxLength: Limits.groupNameMax,
                              style: field,
                              decoration: gumdropField(),
                              onSubmitted: (v) => v.trim().isEmpty
                                  ? null
                                  : _save(() => repo.update(group.id, name: v)),
                            ),
                          ),
                          // A basic group has no sport (TEAM-14).
                          if (group.hasPlayers) ...[
                            const SizedBox(height: 9),
                            LabeledField(
                              label: l10n.sportLabel,
                              child: DropdownButtonFormField<Sport>(
                                initialValue: group.sport,
                                // The sport's name gets the room, and shortens
                                // at large text sizes.
                                isExpanded: true,
                                style: field?.copyWith(color: card.textPrimary),
                                decoration: gumdropField(),
                                icon: Icon(
                                  AppIcons.expand,
                                  size: 24,
                                  color: card.textMuted,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Corners.input,
                                ),
                                items: [
                                  for (final sp in Sport.values)
                                    DropdownMenuItem(
                                      value: sp,
                                      child: Text(
                                        sportName(l10n, sp),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (sp) => sp == null
                                    ? null
                                    : _save(
                                        () => repo.update(group.id, sport: sp),
                                      ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 9),
                          LabeledField(
                            label: l10n.teamDescriptionLabel,
                            child: TextField(
                              controller: _description,
                              maxLength: 500,
                              maxLines: 3,
                              minLines: 1,
                              style: field,
                              decoration: gumdropField(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () => _save(
                                () => repo.update(
                                  group.id,
                                  name: _name.text.trim().isEmpty
                                      ? null
                                      : _name.text,
                                  description: _description.text,
                                ),
                              ),
                              child: Text(l10n.save),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gap,
                // The team color, which tints every screen in the team
                // (TEAM-1, design §3.18).
                PageHeading(l10n.teamColorLabel),
                headingGap,
                TeamColorGrid(
                  selected: group.color,
                  onPick: (argb) => argb == null
                      ? null
                      : _save(
                          () => repo.update(group.id, color: _hex(argb)),
                          announce: false,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.teamColorTintNote,
                  style: text.bodySmall?.copyWith(color: c.textMutedOnPage),
                ),
                gap,
                SettingsCard(
                  children: [
                    SettingsRow(
                      icon: AppIcons.chat,
                      highlighted: true,
                      title: l10n.chatLook,
                      subtitle: l10n.chatLookSummary(
                        lookColor,
                        lookBackground.toLowerCase(),
                      ),
                      onTap: () {
                        final target = _chatLookKey.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            duration: Motion.of(context, Motion.normal),
                            curve: Motion.curve,
                          );
                        }
                      },
                    ),
                    SettingsRow(
                      icon: AppIcons.timeZone,
                      title: l10n.timeZoneLabel,
                      subtitle: TimeZoneNames.label(group.timeZone),
                      onTap: () => unawaited(_changeTimeZone(group, repo)),
                    ),
                    // The invite link: expiry, uses, reset, and turn off
                    // (INV-2).
                    SettingsRow(
                      icon: AppIcons.link,
                      title: l10n.manageInviteLink,
                      subtitle: l10n.manageInviteLinkSubtitle,
                      onTap: () => unawaited(
                        context.push('/g/${group.id.value}/invite'),
                      ),
                    ),
                  ],
                ),
                gap,
                switchCard(l10n.memberPermissions, [
                  switchRow(
                    title: l10n.permCreateEvents,
                    value: s.membersCanCreateEvents,
                    onChanged: (v) =>
                        setSettings(s.copyWith(membersCanCreateEvents: v)),
                  ),
                  switchRow(
                    title: l10n.permCreatePolls,
                    value: s.membersCanCreatePolls,
                    onChanged: (v) =>
                        setSettings(s.copyWith(membersCanCreatePolls: v)),
                  ),
                  switchRow(
                    title: l10n.permUploadDocs,
                    value: s.membersCanUploadDocs,
                    onChanged: (v) =>
                        setSettings(s.copyWith(membersCanUploadDocs: v)),
                  ),
                  switchRow(
                    title: l10n.permInvite,
                    value: s.membersCanInvite,
                    onChanged: (v) =>
                        setSettings(s.copyWith(membersCanInvite: v)),
                  ),
                  switchRow(
                    title: l10n.permAllowMaybe,
                    value: s.allowMaybe,
                    onChanged: (v) => setSettings(s.copyWith(allowMaybe: v)),
                  ),
                  // Who sees the roster's people (TEAM-3).
                  switchRow(
                    title: l10n.permSeePeople,
                    subtitle: l10n.permSeePeopleHelp,
                    value: s.membersCanSeePeople,
                    onChanged: (v) =>
                        setSettings(s.copyWith(membersCanSeePeople: v)),
                  ),
                ]),
                gap,
                // The language filter for chat and polls (SAFE-7).
                switchCard(l10n.languageSection, [
                  switchRow(
                    title: l10n.filterLanguage,
                    subtitle: l10n.filterLanguageHelp,
                    value: s.filterLanguage,
                    onChanged: (v) =>
                        setSettings(s.copyWith(filterLanguage: v)),
                  ),
                ]),
                gap,
                PageHeading(l10n.defaultReminders),
                headingGap,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
                const SizedBox(height: 18),
                // The chat's look for everyone on the team (CHAT-18).
                PageHeading(key: _chatLookKey, l10n.chatLook),
                headingGap,
                ChatLookSection(group: group),
                const SizedBox(height: 18),
                // Storage used against the team's limit (STORE-2), with Media
                // to free space (STORE-5).
                PageHeading(l10n.storageSection),
                headingGap,
                SettingsPanel(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StorageMeter(
                        usedBytes: group.storageBytes,
                        quotaBytes: group.storageQuotaBytes,
                      ),
                      if (isAdmin || superAdmin) ...[
                        const SizedBox(height: Space.sm),
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: [
                            if (isAdmin)
                              OutlinedButton.icon(
                                onPressed: () => unawaited(
                                  context.push('/g/${group.id.value}/media'),
                                ),
                                icon: const Icon(AppIcons.media),
                                label: Text(l10n.mediaMenu),
                              ),
                            // Raising one team's limit isn't advertised
                            // (STORE-6): only super admins ever see it, until
                            // the admin panel (M8) takes it over.
                            if (superAdmin)
                              TextButton(
                                onPressed: () => unawaited(_changeQuota(group)),
                                child: Text(l10n.changeStorageLimit),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // The owner's, and a super admin's on any team (§3).
                if (isOwner || superAdmin) ...[
                  const SizedBox(height: 18),
                  PageHeading(l10n.ownerActions),
                  headingGap,
                  SettingsCard(
                    children: [
                      // A basic group can become a team (TEAM-14); not
                      // back.
                      if (group.isGroup && !group.isArchived)
                        SettingsRow(
                          icon: AppIcons.roster,
                          title: l10n.convertToTeam,
                          subtitle: l10n.convertToTeamHelp,
                          subtitleLines: 2,
                          onTap: () => unawaited(_convert(group)),
                        ),
                      SettingsRow(
                        icon: AppIcons.key,
                        title: l10n.transferOwnership,
                        onTap: () => _transfer(group),
                      ),
                      SettingsRow(
                        icon: group.isArchived
                            ? AppIcons.unarchive
                            : AppIcons.archive,
                        title: group.isArchived
                            ? l10n.restoreTeam
                            : l10n.archiveTeam,
                        onTap: () => _archive(group),
                      ),
                      Builder(
                        builder: (context) => SettingsRow(
                          icon: AppIcons.delete,
                          accent: GumdropColors.of(context).cherry,
                          title: l10n.deleteTeam,
                          titleColor: GumdropColors.of(context).cherry.text,
                          onTap: () => _delete(group),
                        ),
                      ),
                    ],
                  ),
                ],
                // About Battleplan, at the owner's request: the version, who
                // made it, and Buy Jared a coffee.
                const SizedBox(height: 18),
                PageHeading(l10n.about),
                headingGap,
                SettingsPanel(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: AboutBattleplan(appBuild: widget.appBuild),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A searchable list of time zones (TEAM-5).
class _TimeZonePicker extends StatefulWidget {
  const new({required this.zones, required this.current});

  final List<String> zones;
  final String current;

  @override
  State<_TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<_TimeZonePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = [
      for (final z in widget.zones)
        if (TimeZoneNames.matches(z, _query)) z,
    ];
    return AlertDialog(
      title: Text(l10n.timeZoneLabel),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(AppIcons.search),
                hintText: l10n.timeZoneSearch,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(TimeZoneNames.label(shown[i])),
                  selected: shown[i] == widget.current,
                  onTap: () => Navigator.of(context).pop(shown[i]),
                ),
              ),
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
