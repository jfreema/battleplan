import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/app_store_badge.dart';
import 'package:battleplan/core/widgets/camp_app_bar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The message for an invite that can't be used (INV-8).
String inviteProblemMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      InviteUnusable(reason: 'expired') => l10n.inviteExpired,
      InviteUnusable(reason: 'revoked') => l10n.inviteRevoked,
      InviteUnusable(reason: 'used-up') => l10n.inviteUsedUp,
      InviteUnusable(reason: 'wrong-email') => l10n.inviteWrongEmail,
      InviteUnusable(reason: 'link-off') => l10n.linkIsOff,
      InviteUnusable() => l10n.inviteUnknown,
      RateLimited() => l10n.inviteTooManyTries,
      TooManyTeams() => l10n.tooManyTeams,
      Offline() => l10n.signInOffline,
      _ => l10n.errorUseInvite,
    };

/// What the invite code box opens the preview with (INV-6, #20): its back
/// label, and that the preview's "Not this team?" goes back to it.
class FromCodeBox extends BackLabel {
  const new(super.label);
}

/// Invite landing page, `/join/<CODE>` (INV-5, INV-7), with one main button
/// whoever opens it (#20, owner's go 2026-11-16):
///
/// - **Signed in** (the apps, or the web app): a short confirmation on the
///   app's frame, "Join Hornets?" over the team's card, one coral Join
///   team, and from the code box a quiet "Not this team? Enter another
///   code" back to it; from a link in a phone's browser, a quiet Open in
///   app. Nothing about installing the app.
/// - **Signed out in a browser**: Continue in browser, coral, then Open in
///   app outlined on phones only, and the code shown large so it can be
///   typed into the app after installing it, with the App Store badge in
///   browsers not on Android (task 353).
/// - **Signed out in an app** (a link that opened it): Sign in to join.
///
/// Joining signed out signs the person in first, then joins automatically
/// (`?join=1` on the way back). People already on the team go straight to
/// it.
class JoinScreen extends ConsumerStatefulWidget {
  const new({
    required this.code,
    this.autoJoin = false,
    this.inBrowser,
    this.onPhone,
    this.fromCodeBox = false,
    super.key,
  });

  final String code;

  /// Join as soon as the preview loads (after returning from sign-in).
  final bool autoJoin;

  /// Running in a browser, so Continue in browser and the code show
  /// signed out (INV-7); null asks [browserInfoProvider].
  final bool? inBrowser;

  /// A phone or tablet's browser, where Open in app is offered; null asks
  /// [browserInfoProvider].
  final bool? onPhone;

  /// Pushed over the code box, so "Not this team?" goes back to it.
  final bool fromCodeBox;

  /// The link that opens the app on [code] where it's installed (Universal
  /// Links and App Links, INV-9), from the web app at [page]. Android
  /// browsers get an intent link that falls back to this page.
  static Uri openInAppLink(Uri page, String code, {required bool android}) {
    final link = Uri(
      scheme: 'https',
      host: page.host,
      port: page.hasPort ? page.port : null,
      path: '/join/$code',
    );
    if (!android) return link;
    final fallback = Uri.encodeComponent(page.toString());
    return Uri.parse(
      'intent://${link.authority}${link.path}'
      '#Intent;scheme=https;S.browser_fallback_url=$fallback;end',
    );
  }

  /// Shows a raw 8-character code as `K7XP-M2QR`.
  static String formatCode(String code) {
    final c = code.replaceAll('-', '').toUpperCase();
    return c.length == 8 ? '${c.substring(0, 4)}-${c.substring(4)}' : c;
  }

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  InvitePreview? _preview;
  AppFailure? _error;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final preview = await ref
          .read(inviteRepositoryProvider)
          .preview(widget.code);
      if (!mounted) return;
      final signedIn = ref.read(authUserProvider).value != null;
      // People already on the team just go to it (INV-5).
      if (signedIn) {
        final mine = await ref.read(myMembershipsProvider.future);
        if (!mounted) return;
        if (mine.any((m) => m.groupId.value == preview.groupId)) {
          // Leaving while this page is still sliding in would put the
          // team's shell in the tree twice.
          await _transitionDone();
          if (mounted) context.go('/g/${preview.groupId}/chat');
          return;
        }
      }
      setState(() {
        _preview = preview;
        _loading = false;
      });
      if (widget.autoJoin && signedIn) await _join();
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  /// Completes once this page has finished coming in.
  Future<void> _transitionDone() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return;
    final done = Completer<void>();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      done.complete();
    }

    animation.addStatusListener(listener);
    await done.future;
  }

  Future<void> _join() async {
    final signedIn = ref.read(authUserProvider).value != null;
    if (!signedIn) {
      final back = Uri(
        path: '/join/${widget.code}',
        queryParameters: {'join': '1'},
      );
      context.go(
        Uri(path: '/sign-in', queryParameters: {'from': '$back'}).toString(),
      );
      return;
    }
    setState(() => _joining = true);
    try {
      final result = await ref
          .read(inviteRepositoryProvider)
          .redeem(widget.code);
      // Straight into the team's chat (owner's request 2026-11-10). Claiming
      // or adding a player waits until they want to: the Team tab, an
      // event, and Dues offer "Who are you here for?" to anyone on a team
      // who isn't linked to a player yet (PLAYER-3).
      if (mounted) context.go('/g/${result.groupId}/chat');
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  /// The team: its badge, name, sport (none for a group) and size, and who
  /// invited them.
  Widget _team(BuildContext context, InvitePreview preview) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SettingsPanel(
      padding: const EdgeInsets.all(14),
      child: Builder(
        // Inside the panel, for the card's colors.
        builder: (context) {
          final c = GumdropColors.of(context);
          final muted = theme.textTheme.bodyMedium?.copyWith(
            color: c.card.textMuted,
          );
          final badge = TeamBadge(
            name: preview.name,
            color: preview.color == null ? null : Color(preview.color!),
            imageUrl: preview.logoUrl,
            size: 80,
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The page's title is the heading; this is the card's
              // name, in the card heading's type.
              Text(
                preview.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  height: 1.1,
                  color: c.card.headingTextOnCard,
                  shadows: const [],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  // A group has no sport (TEAM-14).
                  if (preview.kind != GroupKind.group)
                    sportName(l10n, preview.sport),
                  l10n.membersCount(preview.memberCount),
                ].join(' · '),
                style: muted,
              ),
              if (preview.invitedBy case final by?)
                Text(l10n.invitedBy(by), style: muted),
            ],
          );
          // Side by side while the name has room; with large text on a
          // small phone, the badge goes above.
          return LayoutBuilder(
            builder: (context, box) {
              final room =
                  80 +
                  Space.md +
                  160 * MediaQuery.textScalerOf(context).scale(14) / 14;
              if (box.maxWidth >= room) {
                return Row(
                  children: [
                    badge,
                    const SizedBox(width: Space.md),
                    Expanded(child: text),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(height: Space.md),
                  text,
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Opens the app on this invite, where it's installed (INV-9).
  void _openInApp() => unawaited(
    ref
        .read(linkOpenerProvider)
        .open(
          JoinScreen.openInAppLink(
            Uri.base,
            widget.code,
            android: defaultTargetPlatform == TargetPlatform.android,
          ),
        ),
  );

  /// Signed in: the short confirmation on the app's frame (#20), with
  /// "‹ Join a Team or Group" from the code box, or a chevron up to Teams
  /// from a link.
  Widget _confirm(
    BuildContext context, {
    required bool inBrowser,
    required bool onPhone,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;
    final error = _error;
    final group = preview?.kind == GroupKind.group;
    final children = <Widget>[];
    if (_loading) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(Space.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (preview == null) {
      children.addAll([
        Text(
          error == null
              ? l10n.inviteUnknown
              : inviteProblemMessage(l10n, error),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Space.xl),
        FilledButton(
          onPressed: () => context.go('/teams'),
          child: Text(l10n.goToMyTeams),
        ),
        if (widget.fromCodeBox) ...[
          const SizedBox(height: Space.sm),
          Center(
            child: TextButton(
              style: GumdropButtons.of(context).link(),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(
                l10n.joinEnterAnotherCode,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ]);
    } else {
      children.addAll([
        _team(context, preview),
        const SizedBox(height: Space.xl),
        if (error != null) ...[
          Text(
            inviteProblemMessage(l10n, error),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: Space.md),
        ],
        // The one main button.
        FilledButton(
          onPressed: _joining ? null : () => unawaited(_join()),
          child: Text(group ? l10n.joinGroupButton : l10n.joinTeamButton),
        ),
        const SizedBox(height: Space.sm),
        if (widget.fromCodeBox)
          // Back to the box, the code still in it.
          Center(
            child: TextButton(
              style: GumdropButtons.of(context).link(),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(
                group ? l10n.joinOtherCodeGroup : l10n.joinOtherCode,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (inBrowser && onPhone)
          OutlinedButton(onPressed: _openInApp, child: Text(l10n.openInApp)),
      ]);
    }
    return GumdropScaffold(
      maxWidth: 460,
      title: preview != null
          ? l10n.joinTeamQuestion(preview.name)
          : !_loading
          ? l10n.joinProblemTitle
          : l10n.joinTeam,
      backLabel: backLabelFrom(context, l10n.joinTeam),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            14,
            Space.page,
            Space.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;
    final error = _error;
    final signedIn = ref.watch(authUserProvider).value != null;
    final browser = ref.watch(browserInfoProvider);
    final inBrowser = widget.inBrowser ?? browser.isWeb;
    final onPhone = widget.onPhone ?? browser.onPhone;
    if (signedIn) {
      return _confirm(context, inBrowser: inBrowser, onPhone: onPhone);
    }

    // Signed out, from a link: a browser's page, or an app's.
    Widget body;
    if (_loading) {
      body = const CircularProgressIndicator();
    } else if (preview == null) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.error, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: Space.lg),
          Text(
            error == null
                ? l10n.inviteUnknown
                : inviteProblemMessage(l10n, error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () => context.go(signedIn ? '/teams' : '/sign-in'),
            child: Text(signedIn ? l10n.goToMyTeams : l10n.signIn),
          ),
        ],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamBadge(
            name: preview.name,
            color: preview.color == null ? null : Color(preview.color!),
            imageUrl: preview.logoUrl,
            size: 80,
          ),
          const SizedBox(height: Space.lg),
          Text(preview.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: Space.xs),
          Text(
            [
              // A group has no sport (TEAM-14).
              if (preview.kind != GroupKind.group)
                sportName(l10n, preview.sport),
              l10n.membersCount(preview.memberCount),
            ].join(' · '),
            style: theme.textTheme.bodyLarge,
          ),
          if (preview.invitedBy != null) ...[
            const SizedBox(height: Space.xs),
            Text(l10n.invitedBy(preview.invitedBy!)),
          ],
          const SizedBox(height: Space.xl),
          if (error != null) ...[
            Text(
              inviteProblemMessage(l10n, error),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: Space.md),
          ],
          // The one coral button: Continue in browser, or Sign in to join
          // in an app. Open in app is a quiet second, and only where the
          // app can be installed (#20); it had been coral too.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _joining ? null : () => unawaited(_join()),
              child: Text(
                inBrowser ? l10n.continueInBrowser : l10n.signInToJoin,
              ),
            ),
          ),
          if (inBrowser && onPhone) ...[
            const SizedBox(height: Space.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openInApp,
                child: Text(l10n.openInApp),
              ),
            ),
          ],
          // For typing into the app after installing it: a browser only.
          if (inBrowser) ...[
            const SizedBox(height: Space.xxl),
            Text(l10n.inviteCodeLabel, style: theme.textTheme.titleSmall),
            SelectableText(
              JoinScreen.formatCode(widget.code),
              style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 2),
            ),
            Text(
              l10n.inviteCodeHelp,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            // Android waits for Google Play (task 214).
            if (defaultTargetPlatform != TargetPlatform.android) ...[
              const SizedBox(height: Space.lg),
              AppStoreBadge(
                onPressed: () => unawaited(
                  ref
                      .read(linkOpenerProvider)
                      .open(LinkService.appStoreListing),
                ),
              ),
            ],
          ],
        ],
      );
    }

    return Scaffold(
      appBar: const CampAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: body,
          ),
        ),
      ),
    );
  }
}
