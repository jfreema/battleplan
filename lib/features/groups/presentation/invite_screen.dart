import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/camp_app_bar.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// What Create opens Invite with (TEAM-1, #16), as GoRouter `extra`: the
/// team was just made, so the title says it's ready. Only Create passes
/// it; a web reload or a link, which also have nothing under the screen,
/// don't, and say "Invite to Hornets".
@immutable
class InviteAfterCreate {
  const new();
}

/// INV-1 at `/g/:groupId/invite`, which says what to do with one main
/// button (#16, owner's go 2026-11-17): a title and a line ("Hornets is
/// ready!" right after Create, else "Invite to Hornets"), the QR code,
/// which opens full screen to hold up at practice, the code and the link,
/// then Share, the one coral button (Copy link where the browser can't
/// share), and Copy link, and with nothing under the screen (right after
/// Create) a third, Continue to the team (#69). Email invites (INV-4) and, for admins, Add
/// people by email (TEAM-7) each say what they do, and admins find the
/// link's expiry, uses, Reset and Turn off behind Link settings (INV-2),
/// which Admin settings opens too (TEAM-5).
class InviteScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invite = ref.watch(teamInviteProvider(groupId));
    final isAdmin =
        (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    final group = ref.watch(groupProvider(groupId)).value;
    final name = group?.name ?? '';
    final isGroup = group?.isGroup ?? false;
    final created = _openedByCreate(context);
    // With nothing under the screen (right after Create, or a reload), a
    // clear way into the team: its chat, where the setup card waits (#3).
    final dead = !context.canPop();
    void continueToTeam() => context.go('/g/${groupId.value}/chat');
    final continueLabel = name.isEmpty
        ? l10n.inviteContinue
        : l10n.inviteContinueTo(name);
    return GumdropScaffold(
      title: name.isEmpty
          ? l10n.inviteMenu
          : created
          ? l10n.inviteReadyTitle(name)
          : l10n.inviteToTitle(name),
      // Opened from the Team tab's card (SPEC §5.3), or the setup card and
      // the empty chat ("‹ Chat", #3).
      backLabel: backLabelFrom(
        context,
        isGroup ? l10n.groupPeople : l10n.tabTeam,
      ),
      // Its column, so the title lines up with it on a wide screen.
      maxWidth: _columnMaxWidth,
      // Continue is the third button, under Share and Copy link (#69); this
      // bar is the way into the team only while there's no invite to show
      // (loading, refused, or the link turned off).
      bottomNavigationBar: dead && !invite.hasValue
          ? DecoratedBox(
              // A hairline over it, so the list ends there instead of
              // looking cut off.
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: GumdropColors.of(context).divider),
                ),
              ),
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.sm,
                  Space.page,
                  Space.sm,
                ),
                child: Center(
                  heightFactor: 1,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(AppIcons.chevronRight),
                    onPressed: continueToTeam,
                    label: Text(
                      continueLabel,
                      textAlign: TextAlign.center,
                      // A long name with large text: two lines at most.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: invite.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is InviteUnusable && e.reason == 'link-off'
            ? _LinkOff(groupId: groupId, isAdmin: isAdmin, isGroup: isGroup)
            : e is PermissionDenied
            ? EmptyState(icon: AppIcons.invite, message: l10n.invitesAdminsOnly)
            : LoadError(
                onRetry: () => ref.invalidate(teamInviteProvider(groupId)),
              ),
        data: (inv) => _InviteBody(
          invite: inv,
          groupId: groupId,
          teamName: name,
          isAdmin: isAdmin,
          line: created
              ? (isGroup ? l10n.inviteReadyLineGroup : l10n.inviteReadyLine)
              : l10n.inviteAnyoneLine,
          isGroup: isGroup,
          onContinue: dead ? continueToTeam : null,
          continueLabel: continueLabel,
        ),
      ),
    );
  }

  /// Whether Create opened the screen ([InviteAfterCreate]).
  static bool _openedByCreate(BuildContext context) {
    // A screen outside a GoRouter page (a test pumping it alone) has none.
    if (ModalRoute.of(context)?.settings is! Page<Object?>) return false;
    return GoRouterState.of(context).extra is InviteAfterCreate;
  }
}

/// The page's column on a wide screen or in the side panel, as Settings'
/// (SPEC §7.3), and the widest the two buttons get within it, centered.
const double _columnMaxWidth = 560;
const double _buttonsMaxWidth = 400;

/// [children] as the page's list, in its centered column.
Widget _column(List<Widget> children, {double top = 2}) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _columnMaxWidth),
    child: ListView(
      padding: EdgeInsets.fromLTRB(Space.page, top, Space.page, Space.xl),
      children: children,
    ),
  ),
);

class _InviteBody extends ConsumerWidget {
  const new({
    required this.invite,
    required this.groupId,
    required this.teamName,
    required this.isAdmin,
    required this.line,
    required this.isGroup,
    this.onContinue,
    this.continueLabel = '',
  });

  final TeamInvite invite;
  final GroupId groupId;
  final String teamName;
  final bool isAdmin;

  /// What to do, under the title.
  final String line;
  final bool isGroup;

  /// Into the team, when there's nothing under the screen (right after
  /// Create, or a reload): the third button, "Continue to Thunder" (#69).
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final link = invite.url.toString();
    final sharer = ref.watch(sharerProvider);
    // Most computer browsers can't share a link; there, Share would only
    // copy, so Copy link is the one main button and Share isn't shown.
    final canShare = sharer.canShareLink(invite.url);

    Future<void> share() async {
      final shared = await sharer.shareLink(
        invite.url,
        subject: l10n.inviteShareSubject(teamName),
      );
      if (shared) return;
      // It said it could and then couldn't: copy, and say so, since the
      // Share button itself shows nothing.
      await Clipboard.setData(ClipboardData(text: link));
      if (context.mounted) showAppSnackBar(context, l10n.linkCopied);
    }

    return _column([
      // The page's first line: what to do with it.
      Text(
        line,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: c.textMutedOnPage,
          fontWeight: AppFonts.reading,
        ),
      ),
      const SizedBox(height: Space.lg),
      Center(
        child: _QrCard(
          link: link,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => _FullScreenQr(invite: invite, teamName: teamName),
            ),
          ),
        ),
      ),
      const SizedBox(height: Space.lg),
      Text(
        l10n.inviteCodeLabel.toUpperCase(),
        semanticsLabel: l10n.inviteCodeLabel,
        textAlign: TextAlign.center,
        // A small capital label (Team Shirt, #104).
        style: GumdropStyle.caps(
          TextStyle(fontSize: 11, height: 16 / 11, color: c.textMutedOnPage),
        ),
      ),
      const SizedBox(height: 4),
      // Selectable, to copy the code alone; plain text to screen readers,
      // not a small field to tap.
      SelectionArea(
        child: Column(
          children: [
            Text(
              invite.display,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: Space.sm),
            Text(
              link,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c.textMutedOnPage,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.xl),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _buttonsMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canShare) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => unawaited(share()),
                  icon: const Icon(AppIcons.share),
                  label: Text(l10n.share),
                ),
                const SizedBox(height: Space.sm),
              ],
              _CopyLinkButton(link: link, main: !canShare),
              // The third button, as easy to see as the other two, and
              // outlined, so Share stays the one coral button (#69, owner's
              // report 2026-11-19: "the continue to group/team button is not
              // as obvious").
              if (onContinue case final go?) ...[
                const SizedBox(height: Space.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  iconAlignment: IconAlignment.end,
                  onPressed: go,
                  icon: const Icon(AppIcons.chevronRight),
                  label: Text(
                    continueLabel,
                    textAlign: TextAlign.center,
                    // A long name with large text: two lines at most.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: Space.xl),
      _EmailRows(groupId: groupId, isAdmin: isAdmin, isGroup: isGroup),
      if (isAdmin) ...[
        const SizedBox(height: 18),
        SettingsCard(
          children: [
            SettingsRow(
              icon: AppIcons.tune,
              title: l10n.linkSettingsRow,
              subtitle: linkSummary(context, invite),
              onTap: () => unawaited(showLinkSettings(context, ref, groupId)),
            ),
          ],
        ),
      ],
    ]);
  }
}

/// The white QR card (INV-1): black on white in every scheme, so any
/// camera reads it. A tap opens it full screen, which the badge on its
/// corner says; the badge sits half off the card, clear of the code's
/// white margin.
class _QrCard extends StatelessWidget {
  const new({required this.link, required this.onOpen});

  final String link;
  final VoidCallback onOpen;

  /// The badge's size, and how far it hangs off the card's corner.
  static const double _badge = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final radius = BorderRadius.circular(Corners.panel);
    return Semantics(
      container: true,
      button: true,
      label: l10n.qrCodeLabel,
      hint: l10n.qrShowFullScreen,
      onTap: onOpen,
      child: ExcludeSemantics(
        child: Tooltip(
          message: l10n.qrShowFullScreen,
          excludeFromSemantics: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [BoxShadow(color: c.divider, spreadRadius: 2)],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: QrImageView(data: link, size: 200),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -_badge / 2,
                bottom: -_badge / 2,
                child: GestureDetector(
                  onTap: onOpen,
                  child: Container(
                    width: _badge,
                    height: _badge,
                    decoration: BoxDecoration(
                      color: c.textOnPage,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.page, width: 2),
                    ),
                    child: Icon(
                      AppIcons.enlarge,
                      size: 17,
                      weight: 700,
                      color: c.page,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Copy link (#16): no check until it's tapped; then its icon is a check
/// and it says Copied for 2 seconds, and screen readers hear "Link
/// copied." It's the coral main button where the browser can't share
/// ([main]), else outlined under Share.
class _CopyLinkButton extends StatefulWidget {
  const new({required this.link, required this.main});

  final String link;
  final bool main;

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  /// How long it says Copied.
  static const _shown = Duration(seconds: 2);

  Timer? _back;
  bool _copied = false;

  @override
  void dispose() {
    _back?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    _back?.cancel();
    setState(() => _copied = true);
    _back = Timer(_shown, () {
      if (mounted) setState(() => _copied = false);
    });
    // The button says it, so there's no snackbar; screen readers hear it.
    unawaited(
      SemanticsService.sendAnnouncement(view, l10n.linkCopied, direction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = Icon(_copied ? AppIcons.check : AppIcons.link);
    final label = Text(_copied ? l10n.linkCopiedButton : l10n.copyLink);
    const size = Size.fromHeight(48);
    return widget.main
        ? FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: size),
            onPressed: () => unawaited(_copy()),
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: size),
            onPressed: () => unawaited(_copy()),
            icon: icon,
            label: label,
          );
  }
}

/// Email invites (INV-4) and, for admins, Add people by email (TEAM-7),
/// each saying what it does, so the two read as different things (#16).
/// Neither is bold: the page's one main action is its coral button.
class _EmailRows extends StatelessWidget {
  const new({
    required this.groupId,
    required this.isAdmin,
    required this.isGroup,
  });

  final GroupId groupId;
  final bool isAdmin;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsCard(
      children: [
        SettingsRow(
          icon: AppIcons.email,
          title: l10n.emailInvites,
          subtitle: l10n.emailInvitesSubtitle,
          // Wraps, so large text reads whole.
          subtitleLines: null,
          onTap: () => context.push('/g/${groupId.value}/invite/email'),
        ),
        if (isAdmin)
          SettingsRow(
            icon: AppIcons.invite,
            title: l10n.addByEmail,
            subtitle: isGroup
                ? l10n.addByEmailSubtitleGroup
                : l10n.addByEmailSubtitle,
            // Wraps, so large text reads whole.
            subtitleLines: null,
            onTap: () => context.push('/g/${groupId.value}/members/add'),
          ),
      ],
    );
  }
}

/// "Never expires · Used 3 times", or "Expires Nov 30 · Used 3 of 20
/// times" (INV-2).
String linkSummary(BuildContext context, TeamInvite invite) {
  final l10n = AppLocalizations.of(context);
  final expires = invite.expiresAt == null
      ? l10n.linkNeverExpires
      : l10n.linkExpires(
          MaterialLocalizations.of(
            context,
          ).formatShortDate(ViewerZone.wallClock(context, invite.expiresAt!)),
        );
  final uses = invite.maxUses == null
      ? l10n.linkUses(invite.useCount)
      : l10n.linkUsesOf(invite.useCount, invite.maxUses!);
  return '$expires · $uses';
}

/// Link settings (INV-2, #16): the team link's expiry and uses, Reset, and
/// Turn off, in a sheet (a dialog on wide screens) over the Invite screen
/// or Admin settings (TEAM-5). Each row closes the sheet, then does what it
/// does, saying so at [context]. While the link is off, the sheet offers a
/// new one. Admins only (§3).
Future<void> showLinkSettings(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) => showAdaptiveSheet<void>(
  context,
  builder: (sheet) => _LinkSettingsSheet(
    groupId: groupId,
    // Each row runs at the opener, once the sheet has closed.
    run: (action) {
      Navigator.of(sheet).pop();
      if (context.mounted) unawaited(action(context, ref));
    },
  ),
);

/// What a Link settings row does, at the opener's [context].
typedef _LinkAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
);

class _LinkSettingsSheet extends ConsumerWidget {
  const new({required this.groupId, required this.run});

  final GroupId groupId;
  final void Function(_LinkAction action) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final invite = ref.watch(teamInviteProvider(groupId));
    final off = invite.error is InviteUnusable;
    final failed = invite.hasError && !off;
    final current = invite.value;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: c.textMuted,
      fontWeight: AppFonts.reading,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.md,
          Space.xl,
          Space.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CardHeading(l10n.linkSettingsRow),
            const SizedBox(height: 6),
            if (off) ...[
              Text(l10n.linkIsOff, style: muted),
              const SizedBox(height: Space.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => run(
                  (context, ref) => turnOnTeamLink(context, ref, groupId),
                ),
                child: Text(l10n.linkTurnOn),
              ),
            ] else if (failed)
              LoadError(
                inline: true,
                onRetry: () => ref.invalidate(teamInviteProvider(groupId)),
              )
            else if (current == null)
              const Padding(
                padding: EdgeInsets.all(Space.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(linkSummary(context, current), style: muted),
              const SizedBox(height: Space.sm),
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: AppIcons.linkExpiry,
                    title: l10n.linkChangeOptions,
                    subtitle: l10n.linkChangeOptionsHelp,
                    // Wraps, so large text reads whole.
                    subtitleLines: null,
                    onTap: () => run(
                      (context, ref) =>
                          _changeLink(context, ref, groupId, current),
                    ),
                  ),
                  SettingsRow(
                    icon: AppIcons.retry,
                    title: l10n.resetLink,
                    subtitle: l10n.resetLinkHelp,
                    // Wraps, so large text reads whole.
                    subtitleLines: null,
                    onTap: () => run(
                      (context, ref) => _resetLink(context, ref, groupId),
                    ),
                  ),
                  // In the warning red, as Delete rows are (#12).
                  SettingsRow(
                    icon: AppIcons.linkOff,
                    accent: c.cherry,
                    titleColor: c.cherry.text,
                    title: l10n.linkTurnOff,
                    subtitle: l10n.linkTurnOffHelp,
                    // Wraps, so large text reads whole.
                    subtitleLines: null,
                    chevron: false,
                    onTap: () => run(
                      (context, ref) => _turnOffLink(context, ref, groupId),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sets the expiry and use limit on the link people already have (INV-2).
Future<void> _changeLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
  TeamInvite invite,
) async {
  final l10n = AppLocalizations.of(context);
  final options = await askLinkOptions(
    context,
    title: l10n.linkChangeOptions,
    body: l10n.linkChangeOptionsBody,
    confirm: l10n.save,
    maxUses: invite.maxUses,
  );
  if (options == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(inviteRepositoryProvider)
        .updateTeamInvite(
          groupId,
          expiry: options.expiry,
          maxUses: options.maxUses,
        );
    ref.invalidate(teamInviteProvider(groupId));
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  } on AppFailure {
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorResetLink)));
  }
}

/// A new link and QR code; the old ones stop working (INV-2).
Future<void> _resetLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final options = await askLinkOptions(
    context,
    title: l10n.resetLink,
    body: l10n.resetLinkBody,
    confirm: l10n.resetLink,
  );
  if (options == null || !context.mounted) return;
  await resetTeamLink(context, ref, groupId, options);
}

/// Turns the link off with no new one (§3 "revoke").
Future<void> _turnOffLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showConfirmDialog(
    context,
    title: l10n.linkTurnOff,
    message: l10n.linkTurnOffBody,
    confirmLabel: l10n.linkTurnOff,
    cancelLabel: l10n.cancel,
  );
  if (!ok || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(inviteRepositoryProvider).revokeTeamInvite(groupId);
    ref.invalidate(teamInviteProvider(groupId));
    messenger.showSnackBar(SnackBar(content: Text(l10n.linkTurnedOff)));
  } on AppFailure {
    messenger.showSnackBar(SnackBar(content: Text(l10n.signInUnknownError)));
  }
}

/// A new link after it was turned off (§3): asks its expiry and uses, then
/// resets.
Future<void> turnOnTeamLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
) async {
  final l10n = AppLocalizations.of(context);
  final options = await askLinkOptions(
    context,
    title: l10n.linkTurnOn,
    body: l10n.linkTurnOnBody,
    confirm: l10n.linkTurnOn,
  );
  if (options == null || !context.mounted) return;
  await resetTeamLink(context, ref, groupId, options);
}

/// Replaces the team's link with a new one with [options] (INV-2), which
/// also turns a link that was turned off back on.
Future<void> resetTeamLink(
  BuildContext context,
  WidgetRef ref,
  GroupId groupId,
  ({InviteExpiry expiry, int? maxUses}) options,
) async {
  final l10n = AppLocalizations.of(context);
  // The screen reloads after the reset, so keep the messenger now.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(inviteRepositoryProvider)
        .resetTeamInvite(
          groupId,
          expiry: options.expiry,
          maxUses: options.maxUses,
        );
    ref.invalidate(teamInviteProvider(groupId));
    messenger.showSnackBar(SnackBar(content: Text(l10n.linkReset)));
  } on AppFailure {
    messenger.showSnackBar(SnackBar(content: Text(l10n.signInUnknownError)));
  }
}

/// Asks for a link's expiry and use limit (INV-2). Null when cancelled.
Future<({InviteExpiry expiry, int? maxUses})?> askLinkOptions(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  int? maxUses,
}) async {
  final l10n = AppLocalizations.of(context);
  var expiry = InviteExpiry.never;
  final usesController = TextEditingController(text: maxUses?.toString());
  final ok = await showCardDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: Space.lg),
            DropdownButtonFormField<InviteExpiry>(
              initialValue: expiry,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.linkExpiryLabel),
              items: [
                for (final e in InviteExpiry.values)
                  DropdownMenuItem(
                    value: e,
                    child: Text(switch (e) {
                      InviteExpiry.never => l10n.expiryNever,
                      InviteExpiry.oneDay => l10n.expiry1d,
                      InviteExpiry.sevenDays => l10n.expiry7d,
                      InviteExpiry.thirtyDays => l10n.expiry30d,
                    }),
                  ),
              ],
              onChanged: (e) => setState(() => expiry = e ?? expiry),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: usesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.linkMaxUsesLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    ),
  );
  // Not disposed here: the dialog still uses it while it animates away.
  final uses = int.tryParse(usesController.text.trim());
  if (ok != true) return null;
  return (expiry: expiry, maxUses: uses != null && uses > 0 ? uses : null);
}

/// The team's link is turned off (§3): admins can turn a new one on. The
/// email rows stay, as neither needs the link.
class _LinkOff extends ConsumerWidget {
  const new({
    required this.groupId,
    required this.isAdmin,
    required this.isGroup,
  });

  final GroupId groupId;
  final bool isAdmin;
  final bool isGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _column(top: 14, [
      EmptyState(icon: AppIcons.invite, message: l10n.linkIsOff),
      if (isAdmin)
        Center(
          child: FilledButton(
            onPressed: () => unawaited(turnOnTeamLink(context, ref, groupId)),
            child: Text(l10n.linkTurnOn),
          ),
        ),
      const SizedBox(height: Space.xl),
      _EmailRows(groupId: groupId, isAdmin: isAdmin, isGroup: isGroup),
    ]);
  }
}

/// The QR code filling the screen, to hold up at practice (INV-1).
class _FullScreenQr extends StatelessWidget {
  const new({required this.invite, required this.teamName});

  final TeamInvite invite;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context).shortestSide * 0.8;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CampAppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(teamName),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: invite.url.toString(),
              size: size,
              semanticsLabel: l10n.qrCodeLabel,
            ),
            const SizedBox(height: Space.lg),
            Text(
              invite.display,
              style: const TextStyle(
                color: Colors.black,
                fontSize: TypeScale.headline,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
