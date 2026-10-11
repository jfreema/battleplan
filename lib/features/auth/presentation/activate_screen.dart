import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Finishes sign-in from an emailed link (ARCH §6.6). The link opens the app
/// through App Links (`/__/auth/links`) or the web app (`/activate`). If the
/// address it was sent to isn't remembered on this device, it asks for it.
/// Once signed in, the router moves on by itself.
class ActivateScreen extends ConsumerStatefulWidget {
  const new({required this.link, super.key});

  /// The path and query the app was opened with.
  final Uri link;

  @override
  ConsumerState<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends ConsumerState<ActivateScreen> {
  final _email = TextEditingController();
  bool _working = false;
  bool _invalid = false;
  bool _needEmail = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authRepositoryProvider);
    if (!auth.isSignInLink(widget.link)) {
      _invalid = true;
      return;
    }
    final pending = ref.read(localPrefsRepositoryProvider).pendingSignInEmail;
    if (pending == null) {
      _needEmail = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(pending));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _finish(String email) async {
    setState(() => _working = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithLink(email: email.trim(), link: widget.link);
      await ref.read(localPrefsRepositoryProvider).setPendingSignInEmail(null);
    } on Exception {
      if (mounted) setState(() => _invalid = true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (_invalid) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.activateInvalid, textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () => context.go('/sign-in'),
            child: Text(l10n.backToSignIn),
          ),
        ],
      );
    } else if (_needEmail && !_working) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.activateNeedEmail, textAlign: TextAlign.center),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.emailLabel),
            onSubmitted: _finish,
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => _finish(_email.text),
            child: Text(l10n.activateContinue),
          ),
        ],
      );
    } else {
      body = Text(l10n.activateSigningIn);
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: body,
          ),
        ),
      ),
    );
  }
}
