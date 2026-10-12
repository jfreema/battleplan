import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Whether a file of [bytes] fits the upload limit in platform settings
/// (ADMIN-7). When it doesn't, says so with the limit, so nobody waits on
/// an upload the server refuses.
bool fitsUploadLimit(BuildContext context, WidgetRef ref, int bytes) {
  final max = ref.read(maxUploadBytesProvider);
  if (bytes <= max) return true;
  showAppSnackBar(
    context,
    AppLocalizations.of(context)
        .documentTooBig(formatBytes(bytes), max ~/ (1024 * 1024)),
  );
  return false;
}
