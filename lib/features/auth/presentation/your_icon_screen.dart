import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/profile_photo.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Your icon at `/profile/icon` (SPEC §5.3, SET-1): my icon at 96 px, and
/// Add a photo (pick, crop to the circle, upload), or Change photo and
/// Remove photo once there is one.
class YourIconScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<YourIconScreen> createState() => _YourIconScreenState();
}

class _YourIconScreenState extends ConsumerState<YourIconScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() work) async {
    setState(() => _busy = true);
    try {
      await work();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    final hasPhoto = profile?.photoPath != null;

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.yourIcon,
        backLabel: l10n.profile,
      ),
      body: profile == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Avatar(
                              name: profile.displayName,
                              colorKey: profile.uid,
                              imageUrl: photoUrl,
                              size: 96,
                            ),
                            if (_busy) const CircularProgressIndicator(),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    0,
                                    18,
                                    0,
                                  ),
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => unawaited(
                                        _run(
                                          () => changeProfilePhoto(
                                            context,
                                            ref,
                                            profile.uid,
                                          ).then((_) {}),
                                        ),
                                      ),
                                icon: Icon(
                                  AppIcons.camera,
                                  size: 20,
                                  color: c.textOnPage,
                                ),
                                label: Text(
                                  hasPhoto
                                      ? l10n.changePhoto
                                      : l10n.iconAddPhoto,
                                ),
                              ),
                              if (hasPhoto)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => unawaited(
                                          _run(() async {
                                            try {
                                              await ref
                                                  .read(userRepositoryProvider)
                                                  .removePhoto(profile.uid);
                                            } on Object {
                                              if (context.mounted) {
                                                showAppSnackBar(
                                                  context,
                                                  l10n.profileSaveFailed,
                                                );
                                              }
                                            }
                                          }),
                                        ),
                                  child: Text(l10n.iconRemovePhoto),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
