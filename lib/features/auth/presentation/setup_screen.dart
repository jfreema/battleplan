import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/legal_links.dart';
import 'package:battleplan/features/auth/presentation/profile_photo.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// First-run setup (AUTH-5, SAFE-3, SAFE-6) at `/setup`: confirm the name
/// and photo prefilled from the sign-in provider (or pick one), confirm
/// being 18 or older, and accept the Terms (linked). Only the confirmations and their dates are stored. The
/// router sends people here until it's done, then on to their teams.
class SetupScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _name = TextEditingController();
  bool _adult = false;
  bool _terms = false;
  bool _saving = false;
  bool _failed = false;
  bool _prefilled = false;
  bool _uploading = false;

  Future<void> _changePhoto(String uid) async {
    setState(() => _uploading = true);
    try {
      await changeProfilePhoto(context, ref, uid);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .ensureProfile(displayName: _name.text.trim(), finishSetup: true);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider).value;
    // The provider's photo, copied in at first sign-in (AUTH-12).
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    if (!_prefilled && profile != null) {
      _name.text = profile.displayName;
      _prefilled = true;
    }
    final canContinue =
        _adult && _terms && _name.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.setupTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Space.xl),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Avatar(
                          name: _name.text,
                          colorKey: profile?.uid,
                          imageUrl: photoUrl,
                          size: 72,
                        ),
                        if (_uploading) const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: profile == null || _uploading
                          ? null
                          : () => unawaited(_changePhoto(profile.uid)),
                      child: Text(
                        profile?.photoPath == null
                            ? l10n.addPhoto
                            : l10n.changePhoto,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  TextField(
                    controller: _name,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.nameLabel,
                      helperText: l10n.setupNameHelp,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  CheckboxListTile(
                    value: _adult,
                    onChanged: (v) => setState(() => _adult = v ?? false),
                    title: Text(l10n.setupAdult),
                    subtitle: Text(l10n.setupAdultHelp),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _terms,
                    onChanged: (v) => setState(() => _terms = v ?? false),
                    title: Text(l10n.setupTerms),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const LegalLinks(),
                  if (_failed) ...[
                    const SizedBox(height: Space.md),
                    Text(
                      l10n.setupFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: Space.xl),
                  FilledButton(
                    onPressed: canContinue
                        ? () => unawaited(_continue())
                        : null,
                    child: Text(l10n.activateContinue),
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
