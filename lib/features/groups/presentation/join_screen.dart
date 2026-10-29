import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
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

/// Invite landing page, `/join/<CODE>` (INV-5, INV-7). Works signed out:
/// it shows the team, and Join signs the person in first, then joins
/// automatically (`?join=1` on the way back). People already on the team
/// go straight to it. In a browser it also offers Open in app, with Join
/// as Continue in browser. The code is shown large so it can be typed into
/// the app after installing it.
class JoinScreen extends ConsumerStatefulWidget {
  const new({
    required this.code,
    this.autoJoin = false,
    this.inBrowser = kIsWeb,
    super.key,
  });

  final String code;

  /// Join as soon as the preview loads (after returning from sign-in).
  final bool autoJoin;

  /// Running in a browser, so Open in app is offered (INV-7).
  final bool inBrowser;

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
      // Every team asks "Who are you here for?" next (PLAYER-3); people an
      // admin already linked to a player skip it there. A basic group has
      // no players (TEAM-14): its chat.
      final group = _preview?.kind == GroupKind.group;
      if (mounted) {
        context.go(
          !result.alreadyMember && !group
              ? '/g/${result.groupId}/who'
              : '/g/${result.groupId}/chat',
        );
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;
    final error = _error;
    final signedIn = ref.watch(authUserProvider).value != null;

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
          if (widget.inBrowser) ...[
            FilledButton.tonal(
              onPressed: () => unawaited(
                ref
                    .read(linkOpenerProvider)
                    .open(
                      JoinScreen.openInAppLink(
                        Uri.base,
                        widget.code,
                        android:
                            defaultTargetPlatform == TargetPlatform.android,
                      ),
                    ),
              ),
              child: Text(l10n.openInApp),
            ),
            const SizedBox(height: Space.sm),
          ],
          FilledButton(
            onPressed: _joining ? null : () => unawaited(_join()),
            child: Text(
              signedIn
                  ? l10n.joinTeamButton
                  : widget.inBrowser
                  ? l10n.continueInBrowser
                  : l10n.signInToJoin,
            ),
          ),
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
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(),
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
