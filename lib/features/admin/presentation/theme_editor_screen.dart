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
import 'package:battleplan/features/admin/presentation/theme_palette.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The colors a theme can set: the "you" color, the page, the text on it,
/// the cards, and the text on them (#82, #83).
enum ThemeColor { accent, page, text, card, cardText }

/// The theme editor at `/admin/themes/<scheme>`, or `/admin/themes/new`
/// (#82, owner's request 2026-11-20: "make the app's default buttons and
/// whatever is always coral colored, customizable for the theme ... Allow
/// the background and the background of the bubbles to be changed ... and
/// allow new themes to be saved"; #83, 2026-11-21: "all the text color to
/// be changed", "add more colors to each option ... have it say the name
/// of the color in addition to showing the color code", and "a protection
/// in there that prevents text and background from being the same color").
///
/// Any theme can set its "you" color (coral today: buttons, your messages,
/// the picked tab, unread counts), its background and its text, and its
/// cards and their text; each empty field keeps the original. Each color
/// says its name, and Choose a color offers the candy colors, the team
/// colors, and every built-in theme's own. A saved theme also has a name
/// and the built-in theme it starts from. A preview shows the colors as
/// they're typed. A color that leaves anything hard to read says so under
/// the field that can fix it, and Save won't send it ([themeProblems]); the
/// server checks again. Saving changes the theme for everyone at once.
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
    for (final (field, argb) in [
      (ThemeColor.accent, theme?.accent),
      (ThemeColor.page, theme?.page),
      (ThemeColor.text, theme?.text),
      (ThemeColor.card, theme?.card),
      (ThemeColor.cardText, theme?.cardText),
    ]) {
      _hex[field]!.text = hexOfColor(argb) ?? '';
    }
  }

  /// The built-in scheme the theme starts from, and its roles.
  TeamScheme get _baseScheme {
    final scheme = _scheme;
    return scheme == null || scheme.isCustom ? _base : scheme;
  }

  SchemeRoles get _baseRoles => SchemeRoles.builtIn(_baseScheme);

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

  bool _set(ThemeColor c) => _color(c) != null;

  ThemeOverride get _theme => ThemeOverride(
    name: _isSaved ? _name.text.trim() : null,
    base: _isSaved ? _base : null,
    accent: _color(ThemeColor.accent),
    page: _color(ThemeColor.page),
    card: _color(ThemeColor.card),
    text: _color(ThemeColor.text),
    cardText: _color(ThemeColor.cardText),
  );

  SchemeRoles get _roles {
    final t = _theme;
    Color? color(int? argb) => argb == null ? null : Color(argb);
    return _baseRoles.withOverrides(
      page: color(t.page),
      card: color(t.card),
      you: color(t.accent),
      text: color(t.text),
      cardText: color(t.cardText),
    );
  }

  Set<ThemeProblem> get _problems => themeProblems(_baseRoles, _roles);

  /// The field that can fix [p]: the one changed, where two could.
  ThemeColor _fieldFor(ThemeProblem p) => switch (p) {
    ThemeProblem.textOnPage =>
      _set(ThemeColor.text)
          ? ThemeColor.text
          : _set(ThemeColor.page)
          ? ThemeColor.page
          : ThemeColor.accent,
    ThemeProblem.textOnBars => ThemeColor.text,
    ThemeProblem.textOnCard =>
      _set(ThemeColor.cardText)
          ? ThemeColor.cardText
          : _set(ThemeColor.card)
          ? ThemeColor.card
          : ThemeColor.text,
    ThemeProblem.inkOnAccent => ThemeColor.accent,
    ThemeProblem.accentHidden =>
      _set(ThemeColor.accent)
          ? ThemeColor.accent
          : _set(ThemeColor.page)
          ? ThemeColor.page
          : _set(ThemeColor.card)
          ? ThemeColor.card
          : ThemeColor.accent,
  };

  /// What's wrong with [field]'s color, if anything.
  String? _problemAt(AppLocalizations l10n, ThemeColor field) {
    final base = _baseScheme.label(l10n);
    for (final p in ThemeProblem.values) {
      if (!_problems.contains(p) || _fieldFor(p) != field) continue;
      return switch ((p, field)) {
        (ThemeProblem.inkOnAccent, _) => l10n.adminThemeInkOnAccent,
        (ThemeProblem.accentHidden, ThemeColor.page) =>
          l10n.adminThemePageHidesAccent,
        (ThemeProblem.accentHidden, ThemeColor.card) =>
          l10n.adminThemeCardHidesAccent,
        (ThemeProblem.accentHidden, _) => l10n.adminThemeAccentHidden,
        (ThemeProblem.textOnPage, ThemeColor.page) => l10n.adminThemeTextOnPage,
        (ThemeProblem.textOnPage, ThemeColor.accent) =>
          l10n.adminThemeAccentHidden,
        (ThemeProblem.textOnPage, _) => l10n.adminThemeTextOnBackground,
        (ThemeProblem.textOnBars, _) =>
          _isSaved
              ? l10n.adminThemeTextOnBarsSaved(base)
              : l10n.adminThemeTextOnBars(base),
        (ThemeProblem.textOnCard, ThemeColor.card) => l10n.adminThemeTextOnCard,
        (ThemeProblem.textOnCard, ThemeColor.cardText) =>
          l10n.adminThemeCardTextUnreadable,
        (ThemeProblem.textOnCard, _) => l10n.adminThemeTextOnCards,
      };
    }
    return null;
  }

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
            text: t.text,
            cardText: t.cardText,
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

  /// Opens the colors to choose from for [field], and puts the one picked
  /// in its box.
  Future<void> _choose(ThemeColor field, String title, Color current) async {
    final picked = await showColorChooser(
      context,
      title: title,
      current: current,
    );
    if (picked == null || !mounted) return;
    setState(() => _hex[field]!.text = ColorMath.hex(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final themes = ref.watch(allThemesProvider);
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
      final base = _baseRoles;
      final cardTextFollows = base.cardText == base.text;

      Widget field(
        ThemeColor field, {
        required String title,
        required String help,
        required Color original,
        required Color color,
        String? emptyNote,
      }) => _ColorField(
        title: title,
        help: help,
        controller: _hex[field]!,
        color: color,
        emptyNote:
            emptyNote ??
            l10n.adminThemeOriginalNamed(
              colorNameOf(l10n, original),
              ColorMath.hex(original),
            ),
        hint: ColorMath.hex(original),
        badHex: _badHex(field),
        problem: _problemAt(l10n, field),
        onChanged: () => setState(() {}),
        onChoose: () => unawaited(_choose(field, title, color)),
      );

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
          field(
            ThemeColor.accent,
            title: l10n.adminThemeAccent,
            help: l10n.adminThemeAccentHelp,
            original: base.you,
            color: roles.you,
          ),
          field(
            ThemeColor.page,
            title: l10n.adminThemePage,
            help: l10n.adminThemePageHelp,
            original: base.page,
            color: roles.page,
          ),
          field(
            ThemeColor.text,
            title: l10n.adminThemeText,
            help: l10n.adminThemeTextHelp,
            original: base.text,
            color: roles.text,
          ),
          field(
            ThemeColor.card,
            title: l10n.adminThemeCard,
            help: l10n.adminThemeCardHelp,
            original: base.card,
            color: roles.card,
          ),
          field(
            ThemeColor.cardText,
            title: l10n.adminThemeCardText,
            help: l10n.adminThemeCardTextHelp,
            original: base.cardText,
            color: roles.cardText,
            emptyNote: cardTextFollows ? l10n.adminThemeFollowsText : null,
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

/// One of a theme's colors: what it is, a swatch of it now with its name
/// and code, a box for its `#RRGGBB` (empty for the original), Choose a
/// color, and what's wrong with it, if anything.
class _ColorField extends StatelessWidget {
  const new({
    required this.title,
    required this.help,
    required this.controller,
    required this.color,
    required this.emptyNote,
    required this.hint,
    required this.badHex,
    required this.problem,
    required this.onChanged,
    required this.onChoose,
  });

  final String title;
  final String help;
  final TextEditingController controller;

  /// The color now, as the preview shows it.
  final Color color;

  /// What an empty box means: the original, by name and code.
  final String emptyNote;
  final String hint;
  final bool badHex;

  /// Why it can't be saved, or null.
  final String? problem;
  final VoidCallback onChanged;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final empty = controller.text.trim().isEmpty;
    return AdminSectionCard(
      title: title,
      children: [
        Text(help, style: text.bodyMedium),
        const SizedBox(height: Space.md),
        // The color now, by name and code.
        Row(
          children: [
            ColorDot(color: color, size: 44),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    colorNameOf(l10n, color),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(ColorMath.hex(color), style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        TextField(
          controller: controller,
          maxLength: 7,
          decoration: InputDecoration(
            labelText: l10n.adminThemeColorCode,
            hintText: hint,
            helperText: empty ? emptyNote : null,
            helperMaxLines: 3,
            errorText: badHex ? l10n.adminThemeHexError : problem,
            errorMaxLines: 5,
            counterText: '',
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.xs,
          children: [
            OutlinedButton.icon(
              icon: const Icon(AppIcons.colorScheme),
              label: Text(l10n.adminThemeChoose),
              onPressed: onChoose,
            ),
            if (!empty)
              TextButton.icon(
                icon: const Icon(AppIcons.reset),
                label: Text(l10n.adminThemeUseOriginal),
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// The colors to choose from, by name and code (#83): the candy colors,
/// the team colors, and each built-in theme's own. Returns the one picked,
/// or null.
Future<Color?> showColorChooser(
  BuildContext context, {
  required String title,
  required Color current,
}) => showModalBottomSheet<Color>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: Text(
              '${l10n.adminThemeChoose}: $title',
              style: text.titleMedium,
            ),
          ),
          for (final group in themePalette(l10n)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                Space.xs,
              ),
              child: Text(group.title, style: text.titleSmall),
            ),
            for (final named in group.colors)
              ListTile(
                leading: ColorDot(color: named.color, size: 32),
                title: Text(named.name),
                subtitle: Text(ColorMath.hex(named.color)),
                trailing: named.color.toARGB32() == current.toARGB32()
                    ? const Icon(AppIcons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(named.color),
              ),
          ],
        ],
      ),
    );
  },
);

/// A round swatch of [color], ringed so a color like the page's still
/// shows.
class ColorDot extends StatelessWidget {
  const new({required this.color, required this.size, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
        width: 1.5,
      ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.adminThemePreviewHeading,
                              style: text.titleLarge?.copyWith(
                                color: r.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.adminThemePreviewCardDetail,
                              style: text.bodyMedium?.copyWith(
                                color: Color.alphaBlend(r.pageMuted, r.page),
                              ),
                            ),
                          ],
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
                          style: text.bodyMedium?.copyWith(
                            color: Color.alphaBlend(r.cardMuted, r.card),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: candy(r.you, r.youLip),
                          child: Text(
                            l10n.adminThemePreviewButton,
                            style: text.labelLarge?.copyWith(
                              color: r.youInk,
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
                      decoration: candy(r.you, r.youLip),
                      child: Text(
                        l10n.adminThemePreviewMine,
                        style: text.bodyMedium?.copyWith(
                          color: r.youInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The tab bar, the middle tab picked in the "you" color, as
            // the app draws it.
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
                    Icon(
                      icon,
                      size: 24,
                      fill: i == 1 ? 1 : 0,
                      color: i == 1
                          ? r.you
                          : Color.alphaBlend(r.pageMuted, r.tabbar),
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
