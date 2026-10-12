import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The one message for everything full storage turns off: uploads,
/// attachments, and new events (STORE-4, ARCH §6.11).
void showStorageFull(BuildContext context) =>
    showAppSnackBar(context, AppLocalizations.of(context).storageFullMessage);

/// "212 MB of 500 MB used" under a meter that turns amber at 90% and red
/// when full, with a short line once it's either (STORE-2, STORE-3).
class StorageMeter extends StatelessWidget {
  const new({required this.usedBytes, required this.quotaBytes, super.key});

  final int usedBytes;
  final int quotaBytes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final level = storageLevelOf(usedBytes, quotaBytes);
    final color = switch (level) {
      StorageLevel.ok => theme.colorScheme.primary,
      // The amber semantic color, contrast-checked in both themes.
      StorageLevel.nearlyFull => AppColors.of(context).maybe,
      StorageLevel.full => theme.colorScheme.error,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quotaBytes > 0) ...[
          LinearProgressIndicator(
            value: (usedBytes / quotaBytes).clamp(0, 1),
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(Corners.pill),
          ),
          const SizedBox(height: Space.xs),
        ],
        Text(l10n.storageUsed(formatBytes(usedBytes), formatBytes(quotaBytes))),
        if (level != StorageLevel.ok)
          Text(
            level == StorageLevel.full
                ? l10n.storageFullLine
                : l10n.storageNearlyFullLine,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
      ],
    );
  }
}

/// "0 B", "512 KB", "1.2 GB": sizes for the storage meter and Media.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 || value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
