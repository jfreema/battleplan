import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/features/auth/presentation/sign_in_error_text.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Minimum password length, matching the project's password policy (AUTH-2).
const minPasswordLength = 8;

enum _Mode { signIn, create }

/// AUTH-2 at `/sign-in/email`: sign in, or create an account with name,
/// email, and password, with a show/hide toggle. Also offers an emailed
/// sign-in link instead of a password.
class EmailSignInScreen extends ConsumerStatefulWidget {
  const new({this.showEmulatorHint = false, super.key});

  final bool showEmulatorHint;

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final controller = ref.read(signInControllerProvider.notifier);
    unawaited(
      _mode == _Mode.signIn
          ? controller.signInWithEmail(_email.text, _password.text)
          : controller.createAccount(
              name: _name.text,
              email: _email.text,
              password: _password.text,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(signInControllerProvider);
    final loading = state.isLoading;
    final error = state.hasError ? signInErrorOf(state.error!) : null;
    final linkSentTo = ref.watch(signInLinkSentProvider);
    final creating = _mode == _Mode.create;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<_Mode>(
                        segments: [
                          ButtonSegment(
                            value: _Mode.signIn,
                            label: Text(l10n.signIn),
                          ),
                          ButtonSegment(
                            value: _Mode.create,
                            label: Text(l10n.createAccount),
                          ),
                        ],
                        selected: {_mode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setState(() => _mode = s.first),
                      ),
                      const SizedBox(height: Space.xl),
                      if (creating) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: l10n.nameLabel,
                            counterText: '',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.nameRequired
                              : null,
                        ),
                        const SizedBox(height: Space.md),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                        validator: (v) =>
                            RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim())
                            ? null
                            : l10n.emailInvalid,
                      ),
                      const SizedBox(height: Space.md),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [
                          if (creating)
                            AutofillHints.newPassword
                          else
                            AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          helperText: creating ? l10n.passwordRule : null,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            icon: Icon(
                              _obscure
                                  ? AppIcons.visibility
                                  : AppIcons.visibilityOff,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return l10n.passwordRequired;
                          if (creating && value.length < minPasswordLength) {
                            return l10n.passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Space.lg),
                      if (error != null) ...[
                        SignInErrorText(error: error),
                        const SizedBox(height: Space.md),
                      ],
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: Text(
                          creating ? l10n.createAccount : l10n.signIn,
                        ),
                      ),
                      if (!creating) ...[
                        const SizedBox(height: Space.sm),
                        TextButton(
                          onPressed: () => context.push(
                            Uri(
                              path: '/reset-password',
                              queryParameters: {
                                if (_email.text.trim().isNotEmpty)
                                  'email': _email.text.trim(),
                              },
                            ).toString(),
                          ),
                          child: Text(l10n.forgotPassword),
                        ),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => ref
                                    .read(signInControllerProvider.notifier)
                                    .sendSignInLink(_email.text),
                          child: Text(l10n.emailMeLink),
                        ),
                      ],
                      if (linkSentTo != null)
                        Text(
                          l10n.signInLinkSent(linkSentTo),
                          textAlign: TextAlign.center,
                        ),
                      if (widget.showEmulatorHint) ...[
                        const SizedBox(height: Space.md),
                        Text(
                          l10n.emulatorHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
