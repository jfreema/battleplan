import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/chat_colors.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/presentation/chat_bubble_colors.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
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
      // Through the audited admin callable for a super admin who isn't one
      // of its admins (ADMIN-3).
      await ref
          .read(teamEditorProvider(group.id))
          .updateChatTheme(group.id, theme);
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
    if (!fitsUploadLimit(context, ref, photos.first.bytes.length)) return;
    // Storage filled while the picker was open: say so rather than upload
    // into a refusal (STORE-4).
    if (ref.read(groupProvider(group.id)).value?.storageFull ?? false) {
      showStorageFull(context);
      return;
    }
    try {
      final path = await ref
          .read(teamEditorProvider(group.id))
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
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final theme = group.chatTheme ?? const ChatTheme();
    // A new background photo is an upload, which full storage stops
    // (STORE-4); colors, the pattern, and a photo already up still work.
    final full = group.storageFull;
    void pickPhoto() => full
        ? showStorageFull(context)
        : unawaited(_pickPhoto(context, ref, theme));
    void save(ChatTheme next) => unawaited(_save(context, ref, next));
    final mine = chatBubbleColor(c, theme.bubbleColor) ?? c.you.face;
    final order = chatCandyOrder(c.flavor);
    // Nothing picked is the theme's "you" color, which is the first candy
    // (CHAT-18); a palette color is the team's.
    final stored = theme.bubbleColor;
    final picked = stored == null ? order.first : ChatCandy.fromStored(stored);
    final muted = text.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.4,
      color: c.textMutedOnPage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.chatLookIntro(group.name), style: muted),
        const SizedBox(height: 14),
        _Preview(bubble: mine),
        const SizedBox(height: 16),
        PageHeading(l10n.chatBubbleColor),
        const SizedBox(height: 14),
        Semantics(
          container: true,
          label: l10n.chatBubbleColor,
          child: _Grid(
            columns: 4,
            spacing: 6,
            children: [
              for (final candy in order)
                _ColorTile(
                  label: chatCandyName(l10n, candy),
                  accent: chatCandyAccent(c, candy),
                  selected: picked == candy,
                  onTap: () => save(theme.copyWith(bubbleColor: candy.stored)),
                ),
              // The team's own color, last; also where a color from the
              // old team palette shows as picked. A team with no color
              // has the theme's.
              _ColorTile(
                label: l10n.teamColorOption,
                accent: _teamAccent(c, group.color),
                teamSwatch: true,
                selected: picked == null,
                onTap: () => save(theme.copyWith(bubbleColor: group.color)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                AppIcons.check,
                size: 18,
                weight: 800,
                color: c.successOnPage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.chatLookTip,
                style: muted?.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PageHeading(l10n.chatBackground),
        const SizedBox(height: 14),
        Semantics(
          container: true,
          label: l10n.chatBackground,
          child: _Grid(
            columns: 3,
            spacing: 12,
            children: [
              for (final (value, label) in [
                (ChatBackground.plain, l10n.backgroundPlain),
                (ChatBackground.pattern, l10n.backgroundPattern),
                (ChatBackground.photo, l10n.backgroundPhoto),
              ])
                _BackgroundTile(
                  background: value,
                  label: label,
                  bubble: mine,
                  selected: theme.background == value,
                  onTap: () {
                    if (value == ChatBackground.photo &&
                        theme.backgroundPath == null) {
                      pickPhoto();
                    } else {
                      save(theme.copyWith(background: value));
                    }
                  },
                ),
            ],
          ),
        ),
        if (theme.background == ChatBackground.photo) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: full
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(context).disabledColor,
                    )
                  : null,
              onPressed: pickPhoto,
              icon: const Icon(AppIcons.photo, size: 16),
              label: Text(l10n.changeBackgroundPhoto),
            ),
          ),
        ],
      ],
    );
  }

  /// The team color as a swatch: its face, and a lip a shade darker.
  static GumdropAccent _teamAccent(GumdropColors c, int? argb) {
    if (argb == null) return c.you;
    final face = Color(argb | 0xFF000000);
    final lip = Color.lerp(face, const Color(0xFF000000), 0.45)!;
    return GumdropAccent(face: face, lip: lip, text: face);
  }
}

/// Equal columns with [spacing] between them and between rows; each row as
/// tall as its tallest tile.
class _Grid extends StatelessWidget {
  const new({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final row = children.sublist(i, math.min(i + columns, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: j < row.length ? row[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) SizedBox(height: spacing),
          row,
        ],
      ],
    );
  }
}

/// A picker tile (design §3.17): the surface with a 2.5 px text-colored
/// outline when [selected]; otherwise clear ([outlined] gives it the card
/// outline instead).
class _Tile extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.padding,
    required this.child,
    this.outlined = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final radius = BorderRadius.circular(Corners.tile);
    final filled = selected || outlined;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? c.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: c.textPrimary, width: 2.5)
              : outlined && c.surfaceBorderWidth > 0
              ? BorderSide(color: c.surfaceBorder, width: c.surfaceBorderWidth)
              : const BorderSide(color: Colors.transparent, width: 2.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: filled ? GumdropSurface(child: child) : child,
          ),
        ),
      ),
    );
  }
}

/// A message color: a 44 px candy gumdrop with its name under it.
class _ColorTile extends StatelessWidget {
  const new({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.teamSwatch = false,
  });

  final String label;
  final GumdropAccent accent;
  final bool selected;
  final VoidCallback onTap;

  /// The team color's swatch, which has the swatch ring and a white check.
  final bool teamSwatch;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return _Tile(
      label: label,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 7),
      child: Builder(
        builder: (context) {
          final onTile = GumdropColors.of(context);
          return Column(
            children: [
              Container(
                width: 44,
                height: 48,
                decoration: ShapeDecoration(
                  color: accent.face,
                  shape: GumdropShape(
                    lipColor: accent.lip,
                    side: teamSwatch
                        ? BorderSide(color: c.swatchInsetRing, width: 2)
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 4),
                child: selected
                    ? Icon(
                        AppIcons.check,
                        size: 22,
                        weight: 800,
                        color: teamSwatch ? GumdropColors.switchKnob : c.ink,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 13,
                      height: 1.1,
                      color: selected ? onTile.textPrimary : c.textOnPage,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A background choice: a small chat in that background, and its name.
class _BackgroundTile extends StatelessWidget {
  const new({
    required this.background,
    required this.label,
    required this.bubble,
    required this.selected,
    required this.onTap,
  });

  final ChatBackground background;
  final String label;
  final Color bubble;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Tile(
          label: label,
          selected: selected,
          outlined: true,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 96 / 64,
                  child: CustomPaint(
                    painter: _ThumbnailPainter(
                      background: background,
                      page: c.page,
                      surface: c.surface,
                      divider: c.divider,
                      bubble: bubble,
                      sprinkles: [
                        c.blueRaspberry.face,
                        c.bubblegum.face,
                        c.lemon.face,
                        c.mint.face,
                        c.tangerine.face,
                        c.grape.face,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Builder(
                builder: (context) => Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    height: 1.1,
                    color: GumdropColors.of(context).textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selected)
          Positioned(
            top: -9,
            right: -9,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: c.mint.face,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.check, size: 16, weight: 800, color: c.ink),
            ),
          ),
      ],
    );
  }
}

/// The preview (design §3.17): a coach's message and your answer in the
/// picked color, on the page inside a dashed outline.
class _Preview extends StatelessWidget {
  const new({required this.bubble});

  final Color bubble;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final text = Theme.of(context).textTheme;
    final name = l10n.chatLookPreviewName;
    // Ink, or white on a dark team color, whichever reads better, as the
    // chat itself picks it (CHAT-18).
    final onBubble =
        ColorMath.contrast(c.ink, bubble) >=
            ColorMath.contrast(GumdropColors.switchKnob, bubble)
        ? c.ink
        : GumdropColors.switchKnob;
    return Semantics(
      container: true,
      label: l10n.chatLookPreview,
      child: CustomPaint(
        foregroundPainter: _DashedOutline(
          color: c.divider,
          radius: Corners.panel,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.page,
            borderRadius: BorderRadius.circular(Corners.panel),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.tangerine.face,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: text.labelSmall?.copyWith(color: c.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GumdropSurface(
                      child: Builder(
                        builder: (context) {
                          final card = GumdropColors.of(context);
                          return Container(
                            padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                            decoration: BoxDecoration(
                              color: card.surface,
                              border: card.surfaceBorderWidth == 0
                                  ? null
                                  : Border.all(
                                      color: card.surfaceBorder,
                                      width: card.surfaceBorderWidth,
                                    ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: text.labelMedium?.copyWith(
                                    color: card.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.chatLookPreviewOther,
                                  style: text.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    color: card.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 7, 13, 8),
                  decoration: BoxDecoration(
                    color: bubble,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    l10n.chatLookPreviewMine,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: onBubble,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 2 px dashed outline around a rounded rectangle.
class _DashedOutline extends CustomPainter {
  const new({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius - 1),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) =>
      old.color != color || old.radius != radius;
}

/// The background thumbnails (design §3.17): the page, then sprinkles or a
/// field photo, and two little bubbles on top.
class _ThumbnailPainter extends CustomPainter {
  const new({
    required this.background,
    required this.page,
    required this.surface,
    required this.divider,
    required this.bubble,
    required this.sprinkles,
  });

  final ChatBackground background;
  final Color page;
  final Color surface;
  final Color divider;
  final Color bubble;
  final List<Color> sprinkles;

  // The sprinkles' places in the 96 x 64 thumbnail: x, y, and turn in
  // degrees (from the design).
  static const _spots = [
    (34.1, 13.5, 121.0),
    (59.9, 9.5, 178.0),
    (50.8, 24.7, 170.0),
    (13.1, 32.1, 16.0),
    (11.5, 28.2, 15.0),
    (14.0, 10.4, 179.0),
    (42.0, 48.7, 79.0),
    (18.3, 17.3, 165.0),
    (58.1, 55.0, 147.0),
    (54.1, 26.3, 174.0),
    (85.6, 8.1, 114.0),
    (76.3, 20.8, 72.0),
    (19.9, 11.8, 98.0),
    (32.9, 48.1, 171.0),
    (22.8, 35.9, 88.0),
    (59.0, 25.1, 5.0),
    (51.8, 9.0, 118.0),
    (13.2, 16.4, 90.0),
    (62.3, 27.9, 43.0),
    (33.3, 36.1, 156.0),
    (44.3, 21.3, 29.0),
    (71.3, 42.0, 126.0),
    (27.8, 35.6, 15.0),
    (50.0, 51.2, 55.0),
    (66.1, 20.7, 73.0),
    (85.9, 11.8, 33.0),
    (41.5, 45.1, 63.0),
    (20.5, 31.1, 101.0),
    (11.6, 40.4, 100.0),
    (68.9, 35.5, 127.0),
    (77.7, 22.0, 20.0),
    (63.4, 36.6, 42.0),
    (54.3, 29.4, 114.0),
    (74.9, 54.8, 102.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 96, size.height / 64);
    const box = Rect.fromLTWH(0, 0, 96, 64);
    canvas.drawRect(box, Paint()..color = page);
    switch (background) {
      case ChatBackground.plain:
        break;
      case ChatBackground.pattern:
        final paint = Paint();
        for (final (i, (x, y, turn)) in _spots.indexed) {
          paint.color = sprinkles[i % sprinkles.length].withValues(alpha: 0.8);
          canvas
            ..save()
            ..translate(x, y)
            ..rotate(turn * math.pi / 180)
            ..drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: 9, height: 3.4),
                const Radius.circular(1.7),
              ),
              paint,
            )
            ..restore();
        }
      case ChatBackground.photo:
        // A ball field under the page color: the photo stand-in, which is
        // content, not theme (design §1c).
        final field = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_grassTop, _grassBottom],
          ).createShader(box);
        canvas
          ..drawRect(box, field)
          ..drawPath(
            Path()
              ..moveTo(48, 18)
              ..lineTo(74, 40)
              ..lineTo(48, 62)
              ..lineTo(22, 40)
              ..close(),
            Paint()..color = _dirt,
          )
          ..drawPath(
            Path()
              ..moveTo(48, 26)
              ..lineTo(65, 40)
              ..lineTo(48, 54)
              ..lineTo(31, 40)
              ..close(),
            Paint()..color = _infield,
          )
          ..drawRect(box, Paint()..color = page.withValues(alpha: 0.55));
    }
    final other = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 10, 50, 14),
      const Radius.circular(7),
    );
    canvas
      ..drawRRect(other, Paint()..color = surface)
      ..drawRRect(
        other,
        Paint()
          ..color = divider
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 34, 48, 14),
          const Radius.circular(7),
        ),
        Paint()..color = bubble,
      )
      ..restore();
  }

  static const _grassTop = Color(0xFF5E8F3A);
  static const _grassBottom = Color(0xFF2F5A22);
  static const _dirt = Color(0xFFB98A5A);
  static const _infield = Color(0xFF4F8A30);

  @override
  bool shouldRepaint(_ThumbnailPainter old) =>
      old.background != background ||
      old.page != page ||
      old.surface != surface ||
      old.divider != divider ||
      old.bubble != bubble;
}
