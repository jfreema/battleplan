import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/profile_photo.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// SET-1 at `/settings/profile`: photo (cropped to a circle) and display name,
/// used on every team. The email is shown read-only; it changes in
/// Sign-in methods.
class ProfileScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName(String uid) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateDisplayName(uid, _name.text);
      if (mounted) showAppSnackBar(context, l10n.profileSaved);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Pick, crop to the circle, then upload (SET-1).
  Future<void> _changePhoto(String uid) async {
    setState(() => _uploading = true);
    try {
      await changeProfilePhoto(context, ref, uid);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    if (profile == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.profile)));
    }
    if (!_loaded) {
      _name.text = profile.displayName;
      _loaded = true;
    }
    final changed =
        _name.text.trim() != profile.displayName &&
        _name.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Avatar(
                  name: profile.displayName,
                  colorKey: profile.uid,
                  imageUrl: photoUrl,
                  size: 96,
                ),
                if (_uploading) const CircularProgressIndicator(),
              ],
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _uploading
                  ? null
                  : () => unawaited(_changePhoto(profile.uid)),
              child: Text(l10n.changePhoto),
            ),
          ),
          const SizedBox(height: Space.lg),
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
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: changed && !_saving
                  ? () => unawaited(_saveName(profile.uid))
                  : null,
              child: Text(l10n.save),
            ),
          ),
          const SizedBox(height: Space.xl),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.emailLabel),
            subtitle: Text(profile.email ?? ''),
          ),
        ],
      ),
    );
  }
}
