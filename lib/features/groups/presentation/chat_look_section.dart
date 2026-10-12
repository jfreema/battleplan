import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Team settings → Chat look (CHAT-18): the chat's bubble color and
/// background for everyone on the team, set by its admins.
class ChatLookSection extends ConsumerWidget {
  const new({required this.group, super.key});

  final Group group;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ChatTheme theme,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(groupRepositoryProvider).updateChatTheme(group.id, theme);
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    ChatTheme theme,
  ) async {
    final l10n = AppLocalizations.of(context);
    final photos = await ref.read(photoPickerProvider).pickChatPhotos(limit: 1);
    if (photos.isEmpty || !context.mounted) return;
    try {
      final path = await ref
          .read(groupRepositoryProvider)
          .uploadChatBackground(group.id, photos.first.bytes);
      if (!context.mounted) return;
      await _save(
        context,
        ref,
        theme.copyWith(background: ChatBackground.photo, backgroundPath: path),
      );
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.profileSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = group.chatTheme ?? const ChatTheme();
    // A new background photo is an upload, which full storage stops
    // (STORE-4); colors, the pattern, and a photo already up still work.
    final full = group.storageFull;
    void pickPhoto() => full
        ? showStorageFull(context)
        : unawaited(_pickPhoto(context, ref, theme));
    final teamColor = group.color;
    Widget swatch(int? argb, String label) {
      final selected = theme.bubbleColor == argb;
      final color = Color(
        argb ?? teamColor ?? Theme.of(context).colorScheme.primary.toARGB32(),
      );
      return Tooltip(
        message: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () =>
              unawaited(_save(context, ref, theme.copyWith(bubbleColor: argb))),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                width: selected ? 3 : 1,
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: selected
                ? Icon(
                    AppIcons.check,
                    size: 18,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  )
                : null,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.chatBubbleColor),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            swatch(null, l10n.teamColorOption),
            for (final c in teamColorValues) swatch(c, ''),
          ],
        ),
        const SizedBox(height: Space.md),
        Text(l10n.chatBackground),
        const SizedBox(height: Space.sm),
        SegmentedButton<ChatBackground>(
          segments: [
            ButtonSegment(
              value: ChatBackground.plain,
              label: Text(l10n.backgroundPlain),
            ),
            ButtonSegment(
              value: ChatBackground.pattern,
              label: Text(l10n.backgroundPattern),
            ),
            ButtonSegment(
              value: ChatBackground.photo,
              label: Text(l10n.backgroundPhoto),
            ),
          ],
          selected: {theme.background},
          onSelectionChanged: (s) {
            final next = s.first;
            if (next == ChatBackground.photo && theme.backgroundPath == null) {
              pickPhoto();
            } else {
              unawaited(_save(context, ref, theme.copyWith(background: next)));
            }
          },
        ),
        if (theme.background == ChatBackground.photo)
          TextButton(
            style: full
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).disabledColor,
                  )
                : null,
            onPressed: pickPhoto,
            child: Text(l10n.changeBackgroundPhoto),
          ),
      ],
    );
  }
}
