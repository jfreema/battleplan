import 'dart:async';

import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The invite code in the `from` that sign-in and setup carry back to an
/// invite (INV-5 step 2), such as `/join/K7XPM2QR?join=1`, or null when
/// `from` goes anywhere else. `/join` alone is the code box, not an
/// invite.
String? inviteCodeFromReturn(String? from) {
  if (from == null) return null;
  final segments = Uri.tryParse(from)?.pathSegments ?? const <String>[];
  if (segments.length != 2 || segments.first != 'join') return null;
  final code = segments[1].trim();
  return code.isEmpty ? null : code;
}

/// Which screen an [InviteBanner] is on, for its line.
enum InviteBannerOn {
  /// Sign-in and sign-up: "Join Hornets: sign in or create a free
  /// account".
  signIn,

  /// First-run setup, just after a new account signed in: "Finish setting
  /// up, then you'll join Hornets".
  setup,
}

/// The team someone is on their way to join (#24, SPEC AUTH-1, AUTH-5):
/// its badge beside one line saying what happens next, on a card. Signing
/// in from an invite (Continue in browser, Sign in to join) already joins
/// afterward; this shows it, so a new guardian can see they're in the right
/// place. It reads the same preview the invite page shows; while that
/// loads, or if the invite can't be used, it shows nothing, and the screen
/// is the plain one (the invite page says what was wrong).
class InviteBanner extends ConsumerStatefulWidget {
  const new({required this.code, required this.on, super.key});

  /// The invite's code, from [inviteCodeFromReturn].
  final String code;

  /// The screen it's on, for its line.
  final InviteBannerOn on;

  @override
  ConsumerState<InviteBanner> createState() => _InviteBannerState();
}

class _InviteBannerState extends ConsumerState<InviteBanner> {
  InvitePreview? _preview;

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
      if (mounted) setState(() => _preview = preview);
    } on AppFailure {
      // An invite that can't be used (INV-8), or no connection: no banner.
      // The invite page says what's wrong once they're back there.
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final line = switch (widget.on) {
      InviteBannerOn.signIn => l10n.inviteSignInLine(preview.name),
      InviteBannerOn.setup => l10n.inviteSetupLine(preview.name),
    };
    return SettingsPanel(
      child: Builder(
        // Inside the panel, for the card's colors.
        builder: (context) {
          final c = GumdropColors.of(context);
          return Row(
            children: [
              // The badge only names the team, which the line says, so
              // screen readers hear the line alone.
              ExcludeSemantics(
                child: TeamBadge(
                  name: preview.name,
                  color: preview.color == null ? null : Color(preview.color!),
                  imageUrl: preview.logoUrl,
                  size: 48,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  line,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: c.card.headingTextOnCard,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
