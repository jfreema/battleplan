import 'dart:async';

import 'package:battleplan/core/camp_theme.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/theme_readability.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/team_color_names.dart';
import 'package:battleplan/core/widgets/camo.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// The theme editor, back for Boot Camp Mix (#88, owner's request
// 2026-11-22: "can you put the theme editor back in? only available to
// super admins, of course."; SPEC ADMIN-10). Every color a scheme is drawn
// from can change, the games, send and alerts color too (his question the
// same evening: "does that have to be red in every theme? can it be changed
// in the theme editor?"). The Super Admin Panel stays drawn as the app
// ships, so whatever is saved can always be put back here.

/// The editor's colors, in groups, in the order it shows them: the accents
/// first, games, send and alerts at the top.
const List<(String Function(AppLocalizations), List<CampColor>)> _groups = [
  (
    _accents,
    [
      CampColor.red,
      CampColor.mustard,
      CampColor.balloon,
      CampColor.blue,
      CampColor.green,
      CampColor.orange,
      CampColor.purple,
    ],
  ),
  (
    _page,
    [
      CampColor.page,
      CampColor.panel,
      CampColor.tabBar,
      CampColor.ink,
      CampColor.shadow,
    ],
  ),
  (
    _lettering,
    [
      CampColor.text,
      CampColor.muted,
      CampColor.panelText,
      CampColor.panelMuted,
      CampColor.headerLettering,
    ],
  ),
  (
    _camo,
    [
      CampColor.camoGround,
      CampColor.camoBig,
      CampColor.camoMid,
      CampColor.camoSmall,
    ],
  ),
  (
    _details,
    [
      CampColor.unansweredTag,
      CampColor.answerRow,
      CampColor.toolsRow,
      CampColor.disabledIcon,
      CampColor.ballChain,
    ],
  ),
];

String _accents(AppLocalizations l10n) => l10n.adminThemeGroupAccents;
String _page(AppLocalizations l10n) => l10n.adminThemeGroupPage;
String _lettering(AppLocalizations l10n) => l10n.adminThemeGroupLettering;
String _camo(AppLocalizations l10n) => l10n.adminThemeGroupCamo;
String _details(AppLocalizations l10n) => l10n.adminThemeGroupDetails;

/// What the editor calls [color].
String campColorLabel(AppLocalizations l10n, CampColor color) =>
    switch (color) {
      CampColor.red => l10n.adminThemeColorRed,
      CampColor.mustard => l10n.adminThemeColorMustard,
      CampColor.balloon => l10n.adminThemeColorBalloon,
      CampColor.blue => l10n.adminThemeColorBlue,
      CampColor.green => l10n.adminThemeColorGreen,
      CampColor.orange => l10n.adminThemeColorOrange,
      CampColor.purple => l10n.adminThemeColorPurple,
      CampColor.page => l10n.adminThemeColorPage,
      CampColor.panel => l10n.adminThemeColorPanel,
      CampColor.tabBar => l10n.adminThemeColorTabBar,
      CampColor.ink => l10n.adminThemeColorInk,
      CampColor.shadow => l10n.adminThemeColorShadow,
      CampColor.text => l10n.adminThemeColorText,
      CampColor.muted => l10n.adminThemeColorMuted,
      CampColor.panelText => l10n.adminThemeColorPanelText,
      CampColor.panelMuted => l10n.adminThemeColorPanelMuted,
      CampColor.headerLettering => l10n.adminThemeColorHeaderLettering,
      CampColor.camoGround => l10n.adminThemeColorCamoGround,
      CampColor.camoBig => l10n.adminThemeColorCamoBig,
      CampColor.camoMid => l10n.adminThemeColorCamoMid,
      CampColor.camoSmall => l10n.adminThemeColorCamoSmall,
      CampColor.unansweredTag => l10n.adminThemeColorUnansweredTag,
      CampColor.answerRow => l10n.adminThemeColorAnswerRow,
      CampColor.toolsRow => l10n.adminThemeColorToolsRow,
      CampColor.disabledIcon => l10n.adminThemeColorDisabledIcon,
      CampColor.ballChain => l10n.adminThemeColorBallChain,
    };

/// What [color] changes in the app, in a line.
String campColorHelp(AppLocalizations l10n, CampColor color) => switch (color) {
  CampColor.red => l10n.adminThemeColorRedHelp,
  CampColor.mustard => l10n.adminThemeColorMustardHelp,
  CampColor.balloon => l10n.adminThemeColorBalloonHelp,
  CampColor.blue => l10n.adminThemeColorBlueHelp,
  CampColor.green => l10n.adminThemeColorGreenHelp,
  CampColor.orange => l10n.adminThemeColorOrangeHelp,
  CampColor.purple => l10n.adminThemeColorPurpleHelp,
  CampColor.page => l10n.adminThemeColorPageHelp,
  CampColor.panel => l10n.adminThemeColorPanelHelp,
  CampColor.tabBar => l10n.adminThemeColorTabBarHelp,
  CampColor.ink => l10n.adminThemeColorInkHelp,
  CampColor.shadow => l10n.adminThemeColorShadowHelp,
  CampColor.text => l10n.adminThemeColorTextHelp,
  CampColor.muted => l10n.adminThemeColorMutedHelp,
  CampColor.panelText => l10n.adminThemeColorPanelTextHelp,
  CampColor.panelMuted => l10n.adminThemeColorPanelMutedHelp,
  CampColor.headerLettering => l10n.adminThemeColorHeaderLetteringHelp,
  CampColor.camoGround => l10n.adminThemeColorCamoGroundHelp,
  CampColor.camoBig => l10n.adminThemeColorCamoBigHelp,
  CampColor.camoMid => l10n.adminThemeColorCamoMidHelp,
  CampColor.camoSmall => l10n.adminThemeColorCamoSmallHelp,
  CampColor.unansweredTag => l10n.adminThemeColorUnansweredTagHelp,
  CampColor.answerRow => l10n.adminThemeColorAnswerRowHelp,
  CampColor.toolsRow => l10n.adminThemeColorToolsRowHelp,
  CampColor.disabledIcon => l10n.adminThemeColorDisabledIconHelp,
  CampColor.ballChain => l10n.adminThemeColorBallChainHelp,
};

/// [scheme]'s palette with the colors saved for it.
CampPalette _paletteOf(TeamScheme scheme, CampTheme? theme) => theme == null
    ? SchemeRoles.builtIn(scheme).palette
    : editedPalette(scheme, theme.colors);

/// What the editor calls a header background (#91).
String headerStyleLabel(AppLocalizations l10n, HeaderStyle style) =>
    switch (style) {
      HeaderStyle.camo => l10n.headerCamo,
      HeaderStyle.digital => l10n.headerDigital,
      HeaderStyle.topo => l10n.headerTopo,
      HeaderStyle.playbook => l10n.headerPlaybook,
      HeaderStyle.stripes => l10n.headerStripes,
      HeaderStyle.halftone => l10n.headerHalftone,
    };

/// What's changed in [theme], in a line: its header background and how
/// many colors.
String _changes(AppLocalizations l10n, CampTheme theme) => [
  if (theme.header != HeaderStyle.camo)
    l10n.adminThemeHeaderNamed(headerStyleLabel(l10n, theme.header)),
  if (theme.colors.isNotEmpty) l10n.adminThemeChangedCount(theme.colors.length),
].join(' · ');

/// Themes (#88): every Boot Camp Mix scheme, each with a strip of its colors as
/// they're drawn, and how many are changed. A scheme whose saved colors
/// the app won't draw says so.
class AdminThemesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(allCampThemesProvider);
    final text = Theme.of(context).textTheme;
    return AdminScaffold(
      section: AdminSection.themes,
      title: l10n.adminThemes,
      body: AdminBody(
        maxWidth: 720,
        children: [
          Text(l10n.adminThemesIntro, style: text.bodyMedium),
          const SizedBox(height: Space.lg),
          AdminSectionCard(
            title: l10n.adminThemes,
            children: [
              for (final scheme in bootCampSchemes)
                ListTile(
                  key: ValueKey('theme-${scheme.value}'),
                  contentPadding: EdgeInsets.zero,
                  leading: _PaletteStrip(_paletteOf(scheme, saved[scheme])),
                  title: Text(scheme.label(l10n)),
                  subtitle: Text(switch (saved[scheme]) {
                    null => l10n.adminThemeAsShipped,
                    final theme when !campThemeReads(scheme, theme) =>
                      l10n.adminThemeTurnedOff,
                    final theme => _changes(l10n, theme),
                  }),
                  trailing: const Icon(AppIcons.chevronRight),
                  onTap: () => context.go('/admin/themes/${scheme.value}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A scheme's main colors in a row of ink-edged squares: its page, panels,
/// tab bar, games, trim, your messages, and camouflage.
class _PaletteStrip extends StatelessWidget {
  const new(this.palette);

  final CampPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in [
          palette.page,
          palette.panel,
          palette.red,
          palette.mustard,
          palette.balloon,
          palette.camoGround,
        ])
          Container(
            width: 14,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: palette.ink, width: 1.5),
            ),
          ),
      ],
    ),
  );
}

/// One scheme's colors (#88): a preview of them, its header background
/// (#91), then every color in its group, each by name with its code and
/// what it changes; a tap chooses another. Colors nearly the same as what
/// they sit on are marked and can't be saved. Save replaces what was saved
/// for the scheme; Put back as it ships takes it all away.
class AdminThemeEditorScreen extends ConsumerStatefulWidget {
  const new({required this.scheme, super.key});

  /// One of the Boot Camp Mix schemes ([bootCampSchemes]).
  final TeamScheme scheme;

  @override
  ConsumerState<AdminThemeEditorScreen> createState() =>
      _AdminThemeEditorScreenState();
}

class _AdminThemeEditorScreenState
    extends ConsumerState<AdminThemeEditorScreen> {
  /// What's changed here: the saved colors and header to start with.
  late CampColors _colors = Map.of(_start.colors);
  late HeaderStyle _header = _start.header;
  bool _saving = false;

  CampTheme get _start =>
      ref.read(allCampThemesProvider)[widget.scheme] ?? const CampTheme();

  CampPalette get _base => SchemeRoles.builtIn(widget.scheme).palette;

  CampTheme get _saved =>
      ref.watch(allCampThemesProvider)[widget.scheme] ?? const CampTheme();

  CampTheme get _edits => CampTheme(colors: _colors, header: _header);

  bool get _dirty => _edits != _saved;

  /// [color] set to [value], or back to the original when it's that.
  void _set(CampColor color, Color value) => setState(() {
    final argb = value.toARGB32() | 0xFF000000;
    if (argb == _base.colorOf(color).toARGB32()) {
      _colors.remove(color);
    } else {
      _colors[color] = argb;
    }
  });

  Future<void> _choose(CampColor color, CampPalette palette) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showCampColorChooser(
      context,
      title: l10n.adminThemeChooseFor(campColorLabel(l10n, color)),
      current: palette.colorOf(color),
      original: _base.colorOf(color),
    );
    if (picked != null && mounted) _set(color, picked);
  }

  Future<void> _chooseHeader(CampPalette palette) async {
    final picked = await showHeaderChooser(
      context,
      palette: palette,
      current: _header,
    );
    if (picked != null && mounted) setState(() => _header = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = widget.scheme.label(l10n);
    final repository = ref.read(adminRepositoryProvider);
    final edits = CampTheme(colors: Map.of(_colors), header: _header);
    setState(() => _saving = true);
    await runAdminAction(
      context,
      () => edits.isEmpty
          ? repository.resetCampTheme(widget.scheme)
          : repository.saveCampTheme(widget.scheme, edits),
      done: l10n.adminThemeSaved(name),
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _putBack() async {
    final l10n = AppLocalizations.of(context);
    final name = widget.scheme.label(l10n);
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminThemeBackToShippedTitle(name),
      message: l10n.adminThemeBackToShippedBody,
      confirmLabel: l10n.adminThemeBackToShipped,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final done = await runAdminAction(
      context,
      () => ref.read(adminRepositoryProvider).resetCampTheme(widget.scheme),
      done: l10n.adminThemeBackToShippedDone(name),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (done) {
        _colors = {};
        _header = HeaderStyle.camo;
      }
    });
  }

  /// Leaving with changes asks first.
  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final leave = await showConfirmDialog(
      context,
      title: l10n.adminThemeDiscardTitle,
      message: l10n.adminThemeDiscardBody(widget.scheme.label(l10n)),
      confirmLabel: l10n.adminThemeDiscard,
      cancelLabel: l10n.adminThemeKeepEditing,
      destructive: true,
    );
    if (leave && mounted) {
      setState(() {
        _colors = Map.of(_saved.colors);
        _header = _saved.header;
      });
      context.go('/admin/themes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = _base.withColors({
      for (final MapEntry(:key, :value) in _colors.entries) key: Color(value),
    });
    // Each color in a pair that's nearly the same, with what it's against.
    final against = <CampColor, CampColor>{};
    for (final pair in campThemeProblems(_base, palette)) {
      against
        ..putIfAbsent(pair.fg, () => pair.bg)
        ..putIfAbsent(pair.bg, () => pair.fg);
    }
    final saved = _saved;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: AdminScaffold(
        section: AdminSection.themes,
        title: widget.scheme.label(l10n),
        body: AdminBody(
          maxWidth: 720,
          children: [
            AdminSectionCard(
              title: l10n.adminThemePreview,
              children: [
                Center(
                  child: CampThemePreview(palette: palette, header: _header),
                ),
              ],
            ),
            // The header's background (#91), drawn in these colors.
            AdminSectionCard(
              title: l10n.adminThemeHeader,
              children: [
                ListTile(
                  key: const ValueKey('header-style'),
                  contentPadding: EdgeInsets.zero,
                  leading: _HeaderSwatch(palette: palette, style: _header),
                  title: Text(headerStyleLabel(l10n, _header)),
                  subtitle: Text(l10n.adminThemeHeaderHelp),
                  trailing: _header == HeaderStyle.camo
                      ? const Icon(AppIcons.chevronRight)
                      : IconButton(
                          tooltip: l10n.adminThemeUseOriginal,
                          icon: const Icon(AppIcons.reset),
                          onPressed: () =>
                              setState(() => _header = HeaderStyle.camo),
                        ),
                  onTap: () => unawaited(_chooseHeader(palette)),
                ),
              ],
            ),
            for (final (title, colors) in _groups)
              AdminSectionCard(
                title: title(l10n),
                children: [
                  for (final color in colors)
                    _ColorRow(
                      color: color,
                      value: palette.colorOf(color),
                      changed: _colors.containsKey(color),
                      problem: switch (against[color]) {
                        final other? => l10n.adminThemeNearlySame(
                          campColorLabel(l10n, other),
                        ),
                        null => null,
                      },
                      onTap: () => unawaited(_choose(color, palette)),
                      onReset: () => _set(color, _base.colorOf(color)),
                    ),
                ],
              ),
            if (against.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Text(
                  l10n.adminThemeFixFirst,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: _dirty && against.isEmpty && !_saving
                      ? () => unawaited(_save())
                      : null,
                  child: Text(l10n.save),
                ),
                if (!saved.isEmpty)
                  TextButton.icon(
                    icon: const Icon(AppIcons.reset),
                    label: Text(l10n.adminThemeBackToShipped),
                    onPressed: _saving ? null : () => unawaited(_putBack()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One color: its swatch, name, code and what it changes, or why it can't
/// be saved; a tap chooses another, and a changed one goes back.
class _ColorRow extends StatelessWidget {
  const new({
    required this.color,
    required this.value,
    required this.changed,
    required this.problem,
    required this.onTap,
    required this.onReset,
  });

  final CampColor color;
  final Color value;
  final bool changed;
  final String? problem;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final problem = this.problem;
    return ListTile(
      key: ValueKey('color-${color.value}'),
      contentPadding: EdgeInsets.zero,
      leading: ColorDot(color: value, size: 40),
      title: Text(campColorLabel(l10n, color)),
      subtitle: Text(
        problem ?? '${ColorMath.hex(value)} · ${campColorHelp(l10n, color)}',
        style: problem == null
            ? null
            : TextStyle(color: theme.colorScheme.error),
      ),
      trailing: changed
          ? IconButton(
              tooltip: l10n.adminThemeUseOriginal,
              icon: const Icon(AppIcons.reset),
              onPressed: onReset,
            )
          : const Icon(AppIcons.chevronRight),
      onTap: onTap,
    );
  }
}

/// A round swatch of [color] in an outline, so a color like the page's
/// still shows.
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
        width: 2,
      ),
    ),
  );
}

/// Chooses a color (#88): by its code, or from every scheme's own
/// colors and the team colors, each named. Returns the one picked, or null.
Future<Color?> showCampColorChooser(
  BuildContext context, {
  required String title,
  required Color current,
  required Color original,
}) => showModalBottomSheet<Color>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  // On the sheet's card color, in its lettering (Candy Pop's navy on white).
  builder: (_) => GumdropSurface(
    child: FractionallySizedBox(
      heightFactor: 0.85,
      child: _ColorChooser(title: title, current: current, original: original),
    ),
  ),
);

class _ColorChooser extends StatefulWidget {
  const new({
    required this.title,
    required this.current,
    required this.original,
  });

  final String title;
  final Color current;
  final Color original;

  @override
  State<_ColorChooser> createState() => _ColorChooserState();
}

class _ColorChooserState extends State<_ColorChooser> {
  late final _code = TextEditingController(text: ColorMath.hex(widget.current));
  bool _bad = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _useCode() {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(_code.text.trim());
    if (m == null) {
      setState(() => _bad = true);
      return;
    }
    Navigator.of(context).pop(Color(0xFF000000 | int.parse(m[1]!, radix: 16)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.sm),
      child: Text(title, style: text.titleSmall),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      children: [
        Text(widget.title, style: text.titleMedium),
        const SizedBox(height: Space.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('colorCode'),
                controller: _code,
                maxLength: 7,
                decoration: InputDecoration(
                  labelText: l10n.adminThemeColorCode,
                  helperText: l10n.adminThemeOriginal(
                    ColorMath.hex(widget.original),
                  ),
                  errorText: _bad ? l10n.adminThemeHexError : null,
                  errorMaxLines: 3,
                  counterText: '',
                ),
                onChanged: (_) {
                  if (_bad) setState(() => _bad = false);
                },
                onSubmitted: (_) => _useCode(),
              ),
            ),
            const SizedBox(width: Space.md),
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: FilledButton(
                onPressed: _useCode,
                child: Text(l10n.adminThemeUseCode),
              ),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(AppIcons.reset),
            label: Text(l10n.adminThemeUseOriginal),
            onPressed: () => Navigator.of(context).pop(widget.original),
          ),
        ),
        for (final scheme in bootCampSchemes) ...[
          heading(l10n.adminThemeSchemeColors(scheme.label(l10n))),
          _Swatches([
            for (final (name, color) in _schemeColors(l10n, scheme))
              (name: name, color: color),
          ], current: widget.current),
        ],
        heading(l10n.adminThemeTeamColors),
        _Swatches([
          for (final argb in teamColorValues)
            (name: teamColorName(l10n, argb), color: Color(argb)),
        ], current: widget.current),
      ],
    );
  }
}

/// [scheme]'s colors as it ships, each once, by what the editor calls it.
List<(String, Color)> _schemeColors(AppLocalizations l10n, TeamScheme scheme) {
  final palette = SchemeRoles.builtIn(scheme).palette;
  final seen = <int>{};
  return [
    for (final (_, colors) in _groups)
      for (final color in colors)
        if (seen.add(palette.colorOf(color).toARGB32()))
          (campColorLabel(l10n, color), palette.colorOf(color)),
  ];
}

/// Colors to pick from, each a round swatch named for screen readers and
/// by a long press, the [current] one ringed.
class _Swatches extends StatelessWidget {
  const new(this.colors, {required this.current});

  final List<({String name, Color color})> colors;
  final Color current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ring = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final (:name, :color) in colors)
          Tooltip(
            message: l10n.adminThemeSwatch(name, ColorMath.hex(color)),
            child: Semantics(
              button: true,
              selected: color.toARGB32() == current.toARGB32(),
              label: l10n.adminThemeSwatch(name, ColorMath.hex(color)),
              child: InkResponse(
                onTap: () => Navigator.of(context).pop(color),
                radius: 26,
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: color.toARGB32() == current.toARGB32()
                        ? Border.all(color: ring, width: 3)
                        : null,
                  ),
                  child: ExcludeSemantics(
                    child: ColorDot(color: color, size: 36),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A header background (#91) in [palette]'s colors, as a small swatch.
class _HeaderSwatch extends StatelessWidget {
  const new({required this.palette, required this.style});

  final CampPalette palette;
  final HeaderStyle style;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 64,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: palette.ink, width: 2),
      ),
      child: CustomPaint(painter: CamoPainter(palette, style: style)),
    ),
  );
}

/// Chooses a header background (#91): the six, each drawn in [palette]'s
/// colors, so they're seen as the scheme would have them. Returns the one
/// picked, or null.
Future<HeaderStyle?> showHeaderChooser(
  BuildContext context, {
  required CampPalette palette,
  required HeaderStyle current,
}) => showModalBottomSheet<HeaderStyle>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return GumdropSurface(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminThemeChooseHeader,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.md,
              children: [
                for (final style in HeaderStyle.values)
                  Semantics(
                    button: true,
                    selected: style == current,
                    label: headerStyleLabel(l10n, style),
                    child: InkWell(
                      key: ValueKey('header-${style.value}'),
                      onTap: () => Navigator.of(context).pop(style),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 64,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: style == current
                                      ? theme.colorScheme.primary
                                      : palette.ink,
                                  width: style == current ? 4 : 2,
                                ),
                              ),
                              child: CustomPaint(
                                painter: CamoPainter(palette, style: style),
                              ),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(headerStyleLabel(l10n, style)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// A small picture of a Boot Camp Mix scheme drawn from [palette] (#88):
/// the camouflage header with the team's name and an unread dot, the page
/// under its dot grid with someone's balloon and yours, a game panel under
/// its color with a tag and the answers, the message box's send button,
/// and the tab bar with its current tab on the trim. Plain widgets painted
/// from the palette, so it shows colors that aren't saved yet.
class CampThemePreview extends StatelessWidget {
  const new({required this.palette, this.header = HeaderStyle.camo, super.key});

  final CampPalette palette;

  /// The header's background (#91).
  final HeaderStyle header;

  /// Ink or white, whichever reads better on [face].
  Color _on(Color face) =>
      ColorMath.contrast(palette.ink, face) >=
          ColorMath.contrast(Colors.white, face)
      ? palette.ink
      : Colors.white;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = palette;
    final ink = BorderSide(color: p.ink, width: 2.5);
    TextStyle stencil(double size, Color color) => TextStyle(
      fontFamily: AppFonts.stencil,
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      height: 1.1,
    );
    TextStyle body(Color color) => TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 13,
      fontWeight: AppFonts.reading,
      color: color,
    );
    Widget balloon(String text, Color face, {required bool mine}) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: face,
          border: Border.fromBorderSide(ink),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: p.shadow, offset: const Offset(2, 2))],
        ),
        child: Text(text, style: body(mine ? _on(face) : p.panelText)),
      ),
    );
    Widget answer(String label, Color face) => Expanded(
      child: Container(
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: face,
          border: Border.fromBorderSide(ink),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label.toUpperCase(), style: stencil(11, _on(face))),
      ),
    );
    return ExcludeSemantics(
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: p.page,
          border: Border.all(color: p.ink, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The header: the team's name on the camouflage, the bell's dot.
            SizedBox(
              height: 52,
              child: CustomPaint(
                painter: CamoPainter(p, style: header),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        l10n.adminThemePreviewTeam.toUpperCase(),
                        style: stencil(24, p.headerLettering),
                      ),
                      const Spacer(),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: p.red,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(height: 3, color: p.ink),
            // The page: balloons and a game.
            CustomPaint(
              painter: DotGridPainter(color: p.pageDots),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    balloon(l10n.adminThemePreviewTheirs, p.panel, mine: false),
                    balloon(l10n.adminThemePreviewMine, p.balloon, mine: true),
                    Container(
                      decoration: BoxDecoration(
                        color: p.panel,
                        border: Border.fromBorderSide(ink),
                        boxShadow: [
                          BoxShadow(
                            color: p.shadow,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: p.red,
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  color: p.mustard,
                                  child: Text(
                                    l10n.adminThemePreviewTag.toUpperCase(),
                                    style: stencil(10, p.ink),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.adminThemePreviewGame.toUpperCase(),
                                  style: stencil(17, _on(p.red)),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 2.5, color: p.ink),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                answer(l10n.rsvpGoing, p.green),
                                const SizedBox(width: 6),
                                answer(l10n.rsvpMaybe, p.orange),
                                const SizedBox(width: 6),
                                answer(l10n.rsvpNotGoing, CampPalette.cantGo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The message box and its send button.
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: p.panel,
                              border: Border.fromBorderSide(ink),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: p.red,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(ink),
                          ),
                          child: Icon(
                            AppIcons.send,
                            size: 16,
                            color: _on(p.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // The tab bar, its current tab on the trim.
            Container(
              decoration: BoxDecoration(
                color: p.tabBar,
                border: Border(top: ink),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (icon, current) in [
                    (AppIcons.chat, true),
                    (AppIcons.schedule, false),
                    (AppIcons.documents, false),
                  ])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: current
                          ? BoxDecoration(
                              color: p.mustard,
                              border: Border.fromBorderSide(ink),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: Icon(
                        icon,
                        size: 20,
                        color: current ? p.ink : p.text,
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
