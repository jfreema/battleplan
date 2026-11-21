import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/theme_readability.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/core/widgets/scheme_swatch.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The three colors a theme can set (#82).
enum ThemeColor { accent, page, card }

/// The theme editor at `/admin/themes/<scheme>`, or `/admin/themes/new`
/// (#82, owner's request 2026-11-20: "make the app's default buttons and
/// whatever is always coral colored, customizable for the theme ... Allow
/// the background and the background of the bubbles to be changed ... and
/// allow new themes to be saved").
///
/// Any theme can set its "you" color (coral today: buttons, your messages,
/// the picked tab, unread counts), its background, and its cards and
/// bubbles; each empty field keeps the original. A saved theme also has a
/// name and the built-in theme it starts from. A preview shows the colors
/// as they're typed, and a color that leaves text unreadable can't be saved
/// ([themeProblems]). Saving changes the theme for everyone at once.
class AdminThemeEditorScreen extends ConsumerStatefulWidget {
  /// [scheme] to edit, or null for a new theme. [missing] when the link
  /// names no scheme or a saved theme that's gone.
  const new({required this.scheme, this.missing = false, super.key});

  final TeamScheme? scheme;
  final bool missing;

  @override
  ConsumerState<AdminThemeEditorScreen> createState() =>
      _AdminThemeEditorScreenState();
}

class _AdminThemeEditorScreenState
    extends ConsumerState<AdminThemeEditorScreen> {
  final _name = TextEditingController();
  final Map<ThemeColor, TextEditingController> _hex = {
    for (final c in ThemeColor.values) c: TextEditingController(),
  };
  TeamScheme _base = defaultTeamScheme;

  /// Filled from the saved theme once the settings arrive.
  bool _loaded = false;
  bool _missing = false;
  bool _saving = false;

  /// Shown once Save is pressed: a missing name, and colors not saved.
  bool _tried = false;

  TeamScheme? get _scheme => widget.scheme;
  bool get _isSaved => _scheme?.isCustom ?? true;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _hex.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Map<TeamScheme, ThemeOverride> themes) {
    _loaded = true;
    final scheme = _scheme;
    if (widget.missing ||
        (scheme != null && !schemeAvailable(scheme, themes))) {
      _missing = true;
      return;
    }
    final theme = scheme == null ? null : themes[scheme];
    _name.text = theme?.name ?? '';
    _base = theme?.base ?? defaultTeamScheme;
    _hex[ThemeColor.accent]!.text = hexOfColor(theme?.accent) ?? '';
    _hex[ThemeColor.page]!.text = hexOfColor(theme?.page) ?? '';
    _hex[ThemeColor.card]!.text = hexOfColor(theme?.card) ?? '';
  }

  /// The built-in roles the theme starts from.
  SchemeRoles get _baseRoles {
    final scheme = _scheme;
    return SchemeRoles.builtIn(
      scheme == null || scheme.isCustom ? _base : scheme,
    );
  }

  /// [c]'s field as `#RRGGBB` (the # optional), or null when it's empty or
  /// not a color.
  int? _color(ThemeColor c) {
    final text = _hex[c]!.text.trim();
    if (text.isEmpty) return null;
    return colorFromHex(text.startsWith('#') ? text : '#$text');
  }

  /// Whether [c]'s field has something in it that isn't a color.
  bool _badHex(ThemeColor c) =>
      _hex[c]!.text.trim().isNotEmpty && _color(c) == null;

  ThemeOverride get _theme => ThemeOverride(
    name: _isSaved ? _name.text.trim() : null,
    base: _isSaved ? _base : null,
    accent: _color(ThemeColor.accent),
    page: _color(ThemeColor.page),
    card: _color(ThemeColor.card),
  );

  SchemeRoles get _roles {
    final t = _theme;
    Color? color(int? argb) => argb == null ? null : Color(argb);
    return _baseRoles.withOverrides(
      page: color(t.page),
      card: color(t.card),
      you: color(t.accent),
    );
  }

  Set<ThemeProblem> get _problems => themeProblems(_baseRoles, _roles);

  bool get _canSave =>
      _problems.isEmpty &&
      !ThemeColor.values.any(_badHex) &&
      (!_isSaved || _name.text.trim().isNotEmpty);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _tried = true);
    if (!_canSave) {
      showAppSnackBar(context, l10n.adminThemeFixFirst);
      return;
    }
    setState(() => _saving = true);
    final t = _theme;
    final saved = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .saveTheme(
            scheme: _scheme,
            name: t.name,
            base: t.base,
            accent: t.accent,
            page: t.page,
            card: t.card,
          ),
      done: l10n.adminThemeSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) _close();
  }

  /// Back to the list.
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminSection.themes.path);
    }
  }

  /// Deletes a saved theme, or puts a built-in one back as it ships.
  Future<void> _remove(String name) async {
    final l10n = AppLocalizations.of(context);
    final scheme = _scheme!;
    final done = await confirmAndRun(
      context,
      title: _isSaved
          ? l10n.adminThemeDeleteTitle(name)
          : l10n.adminThemeResetTitle(name),
      message: _isSaved
          ? l10n.adminThemeDeleteMessage
          : l10n.adminThemeResetMessage,
      confirmLabel: _isSaved ? l10n.delete : l10n.adminThemeReset,
      destructive: _isSaved,
      action: () => ref.read(adminRepositoryProvider).deleteTheme(scheme),
      done: _isSaved ? l10n.adminThemeDeleted : l10n.adminThemeResetDone,
    );
    if (done && mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final themes = ref.watch(themeOverridesProvider);
    if (!_loaded && config.value != null) _load(themes);
    final scheme = _scheme;
    final title = scheme == null
        ? l10n.adminNewTheme
        : themes[scheme]?.name ?? scheme.label(l10n);

    Widget body;
    if (!_loaded) {
      body = config.hasError
          ? LoadError(onRetry: () => ref.invalidate(appConfigProvider))
          : const Center(child: CircularProgressIndicator());
    } else if (_missing) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Text(l10n.adminNotFound, textAlign: TextAlign.center),
        ),
      );
    } else {
      final roles = _roles;
      final problems = _problems;
      final base = _baseRoles;
      String? problem(ThemeProblem p, String text) =>
          problems.contains(p) ? text : null;
      body = AdminBody(
        maxWidth: 640,
        children: [
          if (_isSaved)
            AdminSectionCard(
              title: l10n.adminThemeName,
              children: [
                TextField(
                  controller: _name,
                  maxLength: themeNameMax,
                  decoration: InputDecoration(
                    labelText: l10n.adminThemeName,
                    errorText: _tried && _name.text.trim().isEmpty
                        ? l10n.adminThemeNameError
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.sm),
                DropdownButtonFormField<TeamScheme>(
                  initialValue: _base,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.adminThemeStartFrom,
                    helperText: l10n.adminThemeStartFromHelp,
                    helperMaxLines: 3,
                  ),
                  items: [
                    for (final s in builtInSchemes)
                      DropdownMenuItem(value: s, child: Text(s.label(l10n))),
                  ],
                  onChanged: (s) {
                    if (s != null) setState(() => _base = s);
                  },
                ),
              ],
            ),
          AdminSectionCard(
            title: l10n.adminThemePreview,
            children: [ThemePreview(roles: roles)],
          ),
          _ColorField(
            title: l10n.adminThemeAccent,
            help: l10n.adminThemeAccentHelp,
            controller: _hex[ThemeColor.accent]!,
            original: base.you,
            color: roles.you,
            presets: _accentPresets,
            badHex: _badHex(ThemeColor.accent),
            problem: problem(
              ThemeProblem.inkOnAccent,
              l10n.adminThemeInkOnAccent,
            ),
            onChanged: () => setState(() {}),
          ),
          _ColorField(
            title: l10n.adminThemePage,
            help: l10n.adminThemePageHelp,
            controller: _hex[ThemeColor.page]!,
            original: base.page,
            color: roles.page,
            presets: [
              for (final s in builtInSchemes) SchemeRoles.builtIn(s).page,
            ],
            badHex: _badHex(ThemeColor.page),
            problem: problem(
              ThemeProblem.textOnPage,
              l10n.adminThemeTextOnPage,
            ),
            onChanged: () => setState(() {}),
          ),
          _ColorField(
            title: l10n.adminThemeCard,
            help: l10n.adminThemeCardHelp,
            controller: _hex[ThemeColor.card]!,
            original: base.card,
            color: roles.card,
            presets: [
              for (final s in builtInSchemes) SchemeRoles.builtIn(s).card,
            ],
            badHex: _badHex(ThemeColor.card),
            problem: problem(
              ThemeProblem.textOnCard,
              l10n.adminThemeTextOnCard,
            ),
            onChanged: () => setState(() {}),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (scheme != null &&
                  (scheme.isCustom || themes.containsKey(scheme)))
                OutlinedButton.icon(
                  icon: Icon(_isSaved ? AppIcons.delete : AppIcons.reset),
                  label: Text(
                    _isSaved ? l10n.adminThemeDelete : l10n.adminThemeReset,
                  ),
                  style: _isSaved
                      ? OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        )
                      : null,
                  onPressed: _saving ? null : () => unawaited(_remove(title)),
                ),
              FilledButton(
                onPressed: _saving ? null : () => unawaited(_save()),
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      );
    }
    return AdminScaffold(
      section: AdminSection.themes,
      title: title,
      body: body,
    );
  }
}

/// The candy faces and a few more, for the "you" color.
const List<Color> _accentPresets = [
  CandyFaces.coral,
  CandyFaces.tangerine,
  CandyFaces.lemon,
  Color(0xFFFDD023),
  CandyFaces.mint,
  CandyFaces.blueRaspberry,
  CandyFaces.grape,
  CandyFaces.bubblegum,
  Color(0xFFFFFFFF),
  Color(0xFFC0C5CC),
];

/// One of a theme's colors: what it is, a swatch of it now, its `#RRGGBB`
/// (empty for the original), a row of colors to pick from, and what's wrong
/// with it, if anything.
class _ColorField extends StatelessWidget {
  const new({
    required this.title,
    required this.help,
    required this.controller,
    required this.original,
    required this.color,
    required this.presets,
    required this.badHex,
    required this.problem,
    required this.onChanged,
  });

  final String title;
  final String help;
  final TextEditingController controller;

  /// The base's color, which an empty field keeps.
  final Color original;

  /// The color now, as the preview shows it.
  final Color color;
  final List<Color> presets;
  final bool badHex;

  /// Why it can't be saved, or null.
  final String? problem;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    void use(String hex) {
      controller.text = hex;
      onChanged();
    }

    return AdminSectionCard(
      title: title,
      children: [
        Text(help, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Space.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _Dot(color: color, ring: outline, size: 44),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 7,
                decoration: InputDecoration(
                  labelText: l10n.adminThemeHex,
                  hintText: ColorMath.hex(original),
                  helperText: l10n.adminThemeHexHelp(ColorMath.hex(original)),
                  helperMaxLines: 2,
                  errorText: badHex ? l10n.adminThemeHexError : problem,
                  errorMaxLines: 4,
                  counterText: '',
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final p in presets.toSet())
              Semantics(
                button: true,
                label: l10n.adminThemeUseColor(ColorMath.hex(p)),
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => use(ColorMath.hex(p)),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _Dot(color: p, ring: outline, size: 32),
                  ),
                ),
              ),
          ],
        ),
        if (controller.text.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(AppIcons.reset),
              label: Text(l10n.adminThemeUseOriginal),
              onPressed: () => use(''),
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const new({required this.color, required this.ring, required this.size});

  final Color color;
  final Color ring;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: 1.5),
    ),
  );
}

/// A small picture of a theme as it would look (#82): its page with a
/// heading, a card, a chat with someone else's bubble and yours, a button,
/// and the tab bar. Plain widgets painted from [roles], so it shows colors
/// that aren't saved yet without touching the app's own theme.
class ThemePreview extends StatelessWidget {
  const new({required this.roles, super.key});

  final SchemeRoles roles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = roles;
    BoxDecoration candy(Color face, Color lip, {double radius = 18}) =>
        BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: lip, width: 1.5),
          boxShadow: [BoxShadow(color: lip, offset: const Offset(0, 2))],
        );
    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: r.page,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: r.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SchemeSwatch.roles(r),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.adminThemePreviewHeading,
                          style: text.titleLarge?.copyWith(
                            color: r.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: candy(r.card, r.cardRim, radius: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminThemePreviewCard,
                          style: text.titleMedium?.copyWith(
                            color: r.cardText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.adminThemePreviewCardDetail,
                          style: text.bodyMedium?.copyWith(color: r.cardMuted),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: candy(r.you, r.candyLipCoral),
                          child: Text(
                            l10n.adminThemePreviewButton,
                            style: text.labelLarge?.copyWith(
                              color: r.candyInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: candy(r.card, r.cardRim),
                      child: Text(
                        l10n.adminThemePreviewTheirs,
                        style: text.bodyMedium?.copyWith(color: r.cardText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: candy(r.you, r.candyLipCoral),
                      child: Text(
                        l10n.adminThemePreviewMine,
                        style: text.bodyMedium?.copyWith(
                          color: r.candyInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The tab bar, the middle tab picked.
            Container(
              color: r.tabbar,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (i, icon) in const [
                    AppIcons.chat,
                    AppIcons.schedule,
                    AppIcons.person,
                  ].indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: i == 1
                          ? BoxDecoration(
                              color: r.accentMark,
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      child: Icon(
                        icon,
                        size: 22,
                        color: i == 1
                            ? ColorMath.onColor(r.accentMark, dark: r.candyInk)
                            : r.pageMuted,
                      ),
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
