import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
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

  /// Saves the icon color (SET-8); the copy to my memberships follows.
  Future<void> _pick(String uid, AvatarColor color) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(userRepositoryProvider).setAvatarColor(uid, color);
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.iconColorSaveFailed);
    }
  }

  /// The color an icon shows with none picked, as [Avatar.colorFor] hashes
  /// it.
  AvatarColor _hashedColor(String uid) {
    final c = GumdropColors.of(context);
    final face = Avatar.colorFor(c, uid);
    return AvatarColor.values.firstWhere(
      (a) => Avatar.faceOf(c, a) == face,
      orElse: () => AvatarColor.blueRaspberry,
    );
  }

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
                // The 20 px gutters, less what the swatches may reach into.
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20 - _Swatches.reach,
                    6,
                    20 - _Swatches.reach,
                    32,
                  ),
                  children: [
                    _inset(
                      Text(
                        l10n.yourIconLede,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 21 / 15,
                          color: c.textMutedOnPage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _inset(
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Avatar(
                                name: profile.displayName,
                                colorKey: profile.uid,
                                color: profile.avatarColor,
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
                                                    .read(
                                                      userRepositoryProvider,
                                                    )
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
                    ),
                    const SizedBox(height: 24),
                    _inset(
                      SectionLabel(
                        hasPhoto
                            ? l10n.iconColorBehindPhoto
                            : l10n.iconPickColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Swatches(
                      picked: profile.avatarColor,
                      // No color picked yet: the hashed one shows as picked,
                      // so this matches what people see.
                      shown: profile.avatarColor ?? _hashedColor(profile.uid),
                      onPick: (color) => unawaited(_pick(profile.uid, color)),
                    ),
                    const SizedBox(height: 24),
                    _inset(SectionLabel(l10n.iconInChat)),
                    const SizedBox(height: 10),
                    _inset(
                      _ChatPreview(
                        name: profile.displayName,
                        uid: profile.uid,
                        color: profile.avatarColor,
                        photoUrl: photoUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// What's in the 20 px gutters, everything but the swatches: [child]
/// inset by what they may reach into.
Widget _inset(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: _Swatches.reach),
  child: child,
);

/// The seven icon colors (SET-8), spread across the column: 40 px circles
/// in 48 px tap areas, the picked one ringed in the page and the text
/// color with a check. The row reaches 2 px past the column each side, or
/// as far into the gutters as seven 48 px tap areas need ([reach] at most,
/// on narrow phones); on a column narrower still, they take two rows.
class _Swatches extends StatelessWidget {
  const new({required this.picked, required this.shown, required this.onPick});

  final AvatarColor? picked;
  final AvatarColor shown;
  final ValueChanged<AvatarColor> onPick;

  /// How far into each 20 px gutter the row may reach, leaving 8 px at
  /// the screen's edge.
  static const double reach = 12;

  /// A swatch's tap area.
  static const double _tap = 48;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const colors = AvatarColor.values;
      final column = constraints.maxWidth - 2 * reach;
      final width = math.max(column + 4, colors.length * _tap);
      if (width <= constraints.maxWidth) {
        return Center(
          child: SizedBox(
            width: width,
            child: Row(
              children: [
                for (final color in colors)
                  Expanded(child: Center(child: _swatch(context, color))),
              ],
            ),
          ),
        );
      }
      // Two rows on one grid, the second centered under the first.
      final perRow = (colors.length / 2).ceil();
      final slot = math.max(_tap, constraints.maxWidth / perRow);
      return Column(
        children: [
          for (final row in [colors.take(perRow), colors.skip(perRow)])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in row)
                  SizedBox(
                    width: slot,
                    child: Center(child: _swatch(context, color)),
                  ),
              ],
            ),
        ],
      );
    },
  );

  Widget _swatch(BuildContext context, AvatarColor color) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    return Semantics(
      button: true,
      selected: color == shown,
      inMutuallyExclusiveGroup: true,
      label: candyName(l10n, color),
      excludeSemantics: true,
      onTap: color == picked ? null : () => onPick(color),
      child: FocusRingInk(
        onTap: color == picked ? null : () => onPick(color),
        radius: BorderRadius.circular(24),
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Avatar.faceOf(c, color),
                shape: BoxShape.circle,
                boxShadow: color == shown
                    ? [
                        BoxShadow(color: c.textOnPage, spreadRadius: 5.5),
                        BoxShadow(color: c.page, spreadRadius: 3),
                      ]
                    : null,
              ),
              foregroundDecoration: c.avatarRing.a == 0
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.avatarRing, width: 1.5),
                    ),
              child: color == shown
                  ? Icon(AppIcons.check, size: 20, weight: 800, color: c.ink)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// My icon as others see it beside a message (SPEC §7.3): in a field-colored
/// well, the icon, name and time, and a sample message.
class _ChatPreview extends StatelessWidget {
  const new({
    required this.name,
    required this.uid,
    required this.color,
    required this.photoUrl,
  });

  final String name;
  final String uid;
  final AvatarColor? color;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    TextStyle body(double size, FontWeight weight, Color color, double line) =>
        TextStyle(
          fontFamily: AppFonts.body,
          fontSize: size,
          height: line / size,
          fontWeight: weight,
          color: color,
        );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: c.fieldRim.a == 0 ? null : Border.all(color: c.fieldRim),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              name: name,
              colorKey: uid,
              color: color,
              imageUrl: photoUrl,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: name),
                        TextSpan(
                          text: '  4:58 PM',
                          style: body(
                            13,
                            FontWeight.w600,
                            c.textMutedOnPage,
                            20,
                          ),
                        ),
                      ],
                    ),
                    style: body(16, FontWeight.w800, c.textOnPage, 20),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.iconSampleMessage,
                    style: body(17, FontWeight.w500, c.textOnPage, 23),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The name of an icon color (Blue raspberry, ...).
String candyName(AppLocalizations l10n, AvatarColor color) => switch (color) {
  AvatarColor.blueRaspberry => l10n.candyBlueRaspberry,
  AvatarColor.lemon => l10n.candyLemon,
  AvatarColor.mint => l10n.candyMint,
  AvatarColor.grape => l10n.candyGrape,
  AvatarColor.bubblegum => l10n.candyBubblegum,
  AvatarColor.tangerine => l10n.candyTangerine,
  AvatarColor.cherry => l10n.candyCherry,
};
