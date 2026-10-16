import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

/// Super admins give one team its own limit in MB, or put it back on the
/// default (STORE-6), from Team settings or the admin panel (ADMIN-3).
/// Says how it went. Returns true once it's saved.
Future<bool> changeStorageQuota(
  BuildContext context,
  WidgetRef ref,
  Group group,
) async {
  final l10n = AppLocalizations.of(context);
  final max = NumberFormat.decimalPattern(l10n.localeName)
      .format(Limits.storageQuotaMaxMb);
  final defaultMb =
      ref.read(appConfigProvider).value?.defaultStorageQuotaMb ??
      Limits.defaultStorageQuotaMb;
  final choice = await showDialog<_QuotaChoice>(
    context: context,
    builder: (_) => _QuotaDialog(
      initialMb: group.storageQuotaBytes ~/ bytesPerMb,
      maxLabel: max,
      custom: group.storageQuotaCustom,
      defaultLabel: formatBytes(defaultMb * bytesPerMb),
    ),
  );
  if (choice == null || !context.mounted) return false;
  try {
    await ref
        .read(groupRepositoryProvider)
        .setStorageQuota(group.id, choice.mb);
    if (context.mounted) {
      showAppSnackBar(
        context,
        l10n.storageLimitSaved(
          formatBytes((choice.mb ?? defaultMb) * bytesPerMb),
        ),
      );
    }
    return true;
  } on AppFailure catch (e) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        e is PermissionDenied ? l10n.notAllowed : l10n.profileSaveFailed,
      );
    }
    return false;
  }
}

/// What the limit dialog chose: the team's own limit in MB, or with a null
/// `mb` the default (STORE-6).
typedef _QuotaChoice = ({int? mb});

/// Asks for a limit in whole MB, 1 to `Limits.storageQuotaMaxMb`, or the
/// default; pops the choice, or null when cancelled (STORE-6). The server
/// checks the range again.
class _QuotaDialog extends StatefulWidget {
  const new({
    required this.initialMb,
    required this.maxLabel,
    required this.custom,
    required this.defaultLabel,
  });

  final int initialMb;
  final String maxLabel;

  /// Whether the team has its own limit now, rather than the default.
  final bool custom;

  /// The default limit, as it reads: "200 MB".
  final String defaultLabel;

  @override
  State<_QuotaDialog> createState() => _QuotaDialogState();
}

class _QuotaDialogState extends State<_QuotaDialog> {
  late final _mb = TextEditingController(
    text: widget.initialMb > 0 ? '${widget.initialMb}' : '',
  );
  String? _error;

  @override
  void dispose() {
    _mb.dispose();
    super.dispose();
  }

  void _submit() {
    final mb = int.tryParse(_mb.text.trim());
    if (mb == null || mb < 1 || mb > Limits.storageQuotaMaxMb) {
      setState(
        () =>
            _error = AppLocalizations.of(context)
                .storageLimitInvalid(widget.maxLabel),
      );
      return;
    }
    Navigator.of(context).pop<_QuotaChoice>((mb: mb));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.storageLimitTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.custom
                ? l10n.storageLimitOwn
                : l10n.storageLimitIsDefault(widget.defaultLabel),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _mb,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.storageLimitLabel,
              helperText: l10n.storageLimitHelp(widget.maxLabel),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // Back on the default, which follows platform settings (ADMIN-7).
        if (widget.custom)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop<_QuotaChoice>((mb: null)),
            child: Text(l10n.storageUseDefault(widget.defaultLabel)),
          ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
