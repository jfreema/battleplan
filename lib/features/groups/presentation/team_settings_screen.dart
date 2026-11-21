import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/about_battleplan.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/core/widgets/time_zone_picker.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/application/team_editor.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/presentation/chat_bubble_colors.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Reminder choices for events, in minutes (SCHED-3).
const reminderChoices = [15, 60, 120, 1440, 2880, 10080];

/// TEAM-5 at `/g/:groupId/settings` (admins), a page shorter by its two
/// longest sections (#32, owner's go 2026-11-17): the team's name, sport,
/// logo and description, saved together by one Save; its time zone and
/// invite link (Link settings, #16); Look, with the team color and the
/// Chat look and Team color scheme pages; member permissions, language,
/// default reminders, new members' notifications, storage with Media, the
/// owner's actions, and About.
///
/// Leaving with the name or description changed and not saved asks first,
/// whichever way: the back chevron, Android's Back, or (through the
/// route's `onExit`, [mayLeave]) a `go` from the rail or the team header.
class TeamSettingsScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.appBuild, super.key});

  final GroupId groupId;

  /// For About: the version and build (ARCH §9).
  final AppBuild appBuild;

  /// Whether the page may go (the route's `onExit`): yes with nothing typed
  /// and unsaved; otherwise it asks "Save your changes?", and Save saves
  /// first.
  static Future<bool> mayLeave() async {
    final page = _TeamSettingsScreenState._open;
    if (page == null || !page.mounted || page._leaving || !page._dirty) {
      return true;
    }
    final ok = await page._confirmLeave();
    if (ok) page._leaving = true;
    return ok;
  }

  @override
  ConsumerState<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  /// The page on screen, for [TeamSettingsScreen.mayLeave].
  static _TeamSettingsScreenState? _open;

  final _name = TextEditingController();
  final _description = TextEditingController();

  /// The name and description as saved: as the team last had them, or as
  /// this page last saved them. The fields differ from them while there's
  /// typing to save.
  String? _savedName;
  String? _savedDescription;

  /// Filling the fields from the team, not typing.
  bool _syncing = false;

  /// Asked, and allowed to go.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _open = this;
    // Save comes on and off as the fields change.
    void typed() {
      if (!_syncing && mounted) setState(() {});
    }

    _name.addListener(typed);
    _description.addListener(typed);
  }

  @override
  void dispose() {
    if (_open == this) _open = null;
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Typing in the name or description that isn't saved.
  bool get _dirty =>
      _savedName != null &&
      (_name.text.trim() != _savedName!.trim() ||
          _description.text.trim() != (_savedDescription ?? '').trim());

  /// Save is on with a change to save and a name.
  bool get _canSave => _dirty && _name.text.trim().isNotEmpty;

  /// Fills the fields from the team: once, then whenever it changes
  /// elsewhere (another admin renames it), unless I've typed over them.
  void _follow(Group group) {
    final name = group.name;
    final description = group.description ?? '';
    _syncing = true;
    if (_savedName == null || _name.text.trim() == _savedName!.trim()) {
      _name.text = name;
    }
    if (_savedName == null ||
        _description.text.trim() == (_savedDescription ?? '').trim()) {
      _description.text = description;
    }
    _syncing = false;
    _savedName = name;
    _savedDescription = description;
  }

  /// Saves the name and description together (TEAM-5, #32): Save, and
  /// Enter in the name. True once saved.
  Future<bool> _saveText() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.isEmpty) return false;
    try {
      await ref
          .read(teamEditorProvider(widget.groupId))
          .update(widget.groupId, name: name, description: description);
      if (!mounted) return true;
      setState(() {
        _savedName = name;
        _savedDescription = description;
      });
      showAppSnackBar(context, l10n.profileSaved);
      return true;
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e is PermissionDenied ? l10n.notAllowed : l10n.profileSaveFailed,
        );
      }
      return false;
    }
  }

  /// "Save your changes?": Discard leaves them, Save saves them first
  /// (staying if that fails), and closing it stays with the text as typed.
  /// True to go.
  Future<bool> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final isGroup =
        ref.read(groupProvider(widget.groupId)).value?.isGroup ?? false;
    final choice = await showCardDialog<bool>(
      context: context,
      builder: (context) {
        final c = GumdropColors.of(context);
        return AlertDialog(
          title: Text(l10n.leaveUnsavedTitle),
          content: Text(
            isGroup ? l10n.leaveUnsavedBodyGroup : l10n.leaveUnsavedBody,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: c.cherry.text),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.eventDiscard),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    return switch (choice) {
      null => false,
      false => true,
      true => await _saveText(),
    };
  }

  /// A pop the page held back (the chevron, Android's Back): asks, then
  /// goes.
  Future<void> _leave() async {
    if (!await _confirmLeave() || !mounted) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop();
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
    final picked = await showCardDialog<String>(
      context: context,
      builder: (context) => TimeZonePicker(
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
    final picked = await showCardDialog<Membership>(
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
        title: group.isGroup ? l10n.archiveGroup : l10n.archiveTeam,
        message: group.isGroup ? l10n.archiveGroupBody : l10n.archiveTeamBody,
        confirmLabel: group.isGroup ? l10n.archiveGroup : l10n.archiveTeam,
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
    final ok = await showCardDialog<bool>(
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
      title: group.isGroup ? l10n.deleteGroup : l10n.deleteTeam,
      label: group.name,
      helper: group.isGroup ? l10n.deleteGroupBody : l10n.deleteTeamBody,
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
      if (mounted) {
        showAppSnackBar(
          context,
          group.isGroup ? l10n.errorDeleteGroup : l10n.errorDeleteTeam,
        );
      }
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

  /// A notification level's name, as Notifications for this team shows it
  /// (NOTIF-3).
  String _levelLabel(AppLocalizations l10n, NotificationLevel level) =>
      switch (level) {
        NotificationLevel.all => l10n.levelAll,
        NotificationLevel.important => l10n.levelImportant,
        NotificationLevel.none => l10n.levelOff,
      };

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
      return GumdropScaffold(
        maxWidth: 560,
        title: l10n.teamAdmin,
        body: const SizedBox.shrink(),
      );
    }
    if (group.name != _savedName ||
        (group.description ?? '') != _savedDescription) {
      _follow(group);
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
    final stored = group.bubbleColorOrDefault;
    final candy = stored == null
        ? chatCandyOrder.first
        : ChatCandy.fromStored(stored);
    // A candy by name, "Team color" (#34), or a palette color saved before
    // #34 by its color's name, as Chat look shows them.
    final lookColor = candy != null
        ? chatCandyName(l10n, candy, c: c)
        : stored == chatBubbleTeamColor
        ? (group.isGroup ? l10n.groupColorOption : l10n.teamColorOption)
        : teamColorName(l10n, stored!);
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
              style: text.bodySmall?.copyWith(color: c.textMutedOnPage),
            ),
      value: value,
      onChanged: onChanged,
    );

    // A heading over its switch rows, ruled like every list on the page
    // (SPEC §7.3).
    Widget switchCard(String heading, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(heading),
        headingGap,
        SettingsCard(children: rows),
      ],
    );

    // A pop with typing unsaved asks first (#32); the route's onExit asks
    // for a go elsewhere.
    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: GumdropScaffold(
        maxWidth: 560,
        title: group.isGroup ? l10n.groupAdmin : l10n.teamAdmin,
        backLabel: backLabelFrom(
          context,
          group.isGroup ? l10n.groupSettings : l10n.teamSettings,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            // Built whole, not lazily: a settings page, short enough.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                14,
                Space.page,
                Space.xl,
              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              label: group.isGroup
                                  ? l10n.groupNameLabel
                                  : l10n.teamNameLabel,
                              child: TextField(
                                controller: _name,
                                maxLength: Limits.groupNameMax,
                                style: field,
                                decoration: gumdropField(),
                                // Enter does what Save does (#32).
                                onSubmitted: (_) {
                                  if (_canSave) unawaited(_saveText());
                                },
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
                                  style: field?.copyWith(
                                    color: card.textPrimary,
                                  ),
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
                                          () =>
                                              repo.update(group.id, sport: sp),
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
                            // One Save for the name and description, on only
                            // while there's a change to save (#32).
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _canSave
                                    ? () => unawaited(_saveText())
                                    : null,
                                child: Text(l10n.save),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  gap,
                  // The team's basics, with no heading: its time zone, and
                  // the invite link's expiry, uses, reset, and turn off
                  // (INV-2), in Link settings over this page (#16).
                  SettingsCard(
                    children: [
                      SettingsRow(
                        icon: AppIcons.timeZone,
                        title: l10n.timeZoneLabel,
                        subtitle: TimeZoneNames.label(group.timeZone),
                        onTap: () => unawaited(_changeTimeZone(group, repo)),
                      ),
                      SettingsRow(
                        icon: AppIcons.link,
                        title: l10n.manageInviteLink,
                        subtitle: l10n.manageInviteLinkSubtitle,
                        onTap: () =>
                            unawaited(showLinkSettings(context, ref, group.id)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Look (#32): the three colors together, each saying what
                  // it colors.
                  PageHeading(l10n.adminLookSection),
                  headingGap,
                  // The team color, on its badge and in the switcher (TEAM-1,
                  // design §3.18).
                  SectionLabel(
                    group.isGroup ? l10n.groupColorLabel : l10n.teamColorLabel,
                  ),
                  const SizedBox(height: 8),
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
                    group.isGroup
                        ? l10n.groupColorTintNote
                        : l10n.teamColorTintNote,
                    style: text.bodySmall?.copyWith(color: c.textMutedOnPage),
                  ),
                  gap,
                  SettingsCard(
                    children: [
                      // The chat's look for everyone on the team (CHAT-18),
                      // on its own page.
                      SettingsRow(
                        icon: AppIcons.chat,
                        title: l10n.chatLook,
                        subtitle: l10n.chatLookSummary(
                          lookColor,
                          lookBackground.toLowerCase(),
                        ),
                        onTap: () => unawaited(
                          context.push(
                            '/g/${group.id.value}/settings/chat-look',
                          ),
                        ),
                      ),
                      // The team's default color scheme (SET-2, owner's
                      // request 2026-11-08), on its own page.
                      SettingsRow(
                        icon: AppIcons.colorScheme,
                        title: group.isGroup
                            ? l10n.groupDefaultScheme
                            : l10n.teamDefaultScheme,
                        subtitle:
                            group.colorScheme?.label(l10n) ??
                            l10n.teamSchemeNotSet,
                        onTap: () => unawaited(
                          context.push(
                            '/g/${group.id.value}/settings/color-scheme',
                          ),
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
                      title: group.isGroup
                          ? l10n.permSeePeopleGroup
                          : l10n.permSeePeople,
                      subtitle: group.isGroup
                          ? l10n.permSeePeopleHelpGroup
                          : l10n.permSeePeopleHelp,
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
                      // None is a choice of its own (owner's request
                      // 2026-11-08), picked while no time is.
                      FilterChip(
                        label: Text(l10n.reminderNone),
                        selected: s.defaultReminderOffsets.isEmpty,
                        onSelected: (_) => setSettings(
                          s.copyWith(defaultReminderOffsets: const []),
                        ),
                      ),
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
                  // Where team notifications start for people who join
                  // (TEAM-5, NOTIF-3; owner's request 2026-11-10). Each person
                  // can still change their own, and nobody already on the team
                  // changes.
                  PageHeading(l10n.newMemberNotifications),
                  headingGap,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final level in NotificationLevel.values)
                        ChoiceChip(
                          label: Text(_levelLabel(l10n, level)),
                          selected: group.newMemberNotificationLevel == level,
                          onSelected: (_) => unawaited(
                            _save(
                              () => repo.updateNewMemberNotificationLevel(
                                group.id,
                                level,
                              ),
                              announce: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.isGroup
                        ? l10n.newMemberNotificationsHelpGroup
                        : l10n.newMemberNotificationsHelp,
                    style: text.bodySmall?.copyWith(color: c.textMutedOnPage),
                  ),
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
                                    context.push(
                                      '/g/${group.id.value}/media',
                                      extra: BackLabel(
                                        group.isGroup
                                            ? l10n.groupAdmin
                                            : l10n.teamAdmin,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(AppIcons.media),
                                  label: Text(l10n.mediaMenu),
                                ),
                              // Raising one team's limit isn't advertised
                              // (STORE-6): only super admins ever see it, until
                              // the admin panel (M8) takes it over.
                              if (superAdmin)
                                TextButton(
                                  onPressed: () =>
                                      unawaited(_changeQuota(group)),
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
                        // A new team for the next season (TEAM-16): the
                        // owner's, since the new team is theirs.
                        if (isOwner && !group.isArchived)
                          SettingsRow(
                            icon: AppIcons.newSeason,
                            title: l10n.newSeason,
                            subtitle: group.isGroup
                                ? l10n.newSeasonHelpGroup
                                : l10n.newSeasonHelp,
                            subtitleLines: 2,
                            onTap: () => unawaited(
                              context.push('/g/${group.id.value}/season'),
                            ),
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
                          title: switch ((group.isArchived, group.isGroup)) {
                            (true, true) => l10n.restoreGroup,
                            (true, false) => l10n.restoreTeam,
                            (false, true) => l10n.archiveGroup,
                            (false, false) => l10n.archiveTeam,
                          },
                          onTap: () => _archive(group),
                        ),
                        Builder(
                          builder: (context) => SettingsRow(
                            icon: AppIcons.delete,
                            accent: GumdropColors.of(context).cherry,
                            title: group.isGroup
                                ? l10n.deleteGroup
                                : l10n.deleteTeam,
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
      ),
    );
  }
}
