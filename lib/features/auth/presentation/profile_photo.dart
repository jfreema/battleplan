import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/crop_photo_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a profile photo, lets the person crop it to the circle, and
/// uploads it (SET-1, AUTH-5). Returns true once the new photo is saved;
/// false if they cancelled or it failed (the snackbar says why).
Future<bool> changeProfilePhoto(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  final l10n = AppLocalizations.of(context);
  final picked = await ref.read(photoPickerProvider).pickProfilePhoto();
  if (picked == null || !context.mounted) return false;
  final cropped = await cropProfilePhoto(context, picked);
  if (cropped == null || !context.mounted) return false;
  if (!fitsUploadLimit(context, ref, cropped.length)) return false;
  try {
    await ref.read(userRepositoryProvider).uploadPhoto(uid, cropped);
    return true;
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    return false;
  }
}
