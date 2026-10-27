import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/board_edit.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/presentation/board_painter.dart';
import 'package:battleplan/features/plays/presentation/play_board.dart';
import 'package:battleplan/features/plays/presentation/plays_screen.dart';
import 'package:battleplan/features/plays/presentation/step_player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// What a finger, pencil, or mouse does on the board (BOARD-2).
enum BoardTool {
  move,
  team,
  opponent,
  ball,
  run,
  pass,
  block,
  draw,
  text,
  erase,
}

/// How far from a marker or line a touch still picks it: a fingertip.
const double _reachPixels = 28;

/// Draws a play (SPEC BOARD-1 to BOARD-3): the board fills the screen,
/// made for a tablet's touch and a laptop's mouse alike. Tools sit in a
/// rail beside the board on wide screens and in a bar below it on phones.
///
/// As the [whiteboard], it's the coach's board: kept on this device until
/// it's cleared, a new board a tap away, and saved to the team's plays only
/// when asked. On a saved play, Save writes it and leaving with changes
/// asks first.
class PlayEditorScreen extends ConsumerStatefulWidget {
  const new({
    required this.groupId,
    required this.initial,
    this.playId,
    this.whiteboard = false,
    this.freshBoard = false,
    super.key,
  });

  final GroupId groupId;

  /// The saved play being changed, or null.
  final PlayId? playId;
  final bool whiteboard;

  /// The whiteboard starts as a new board, nothing drawn yet: a different
  /// board needs no asking.
  final bool freshBoard;

  /// What the board starts with.
  final PlayDraft initial;

  @override
  ConsumerState<PlayEditorScreen> createState() => _PlayEditorState();
}

class _PlayEditorState extends ConsumerState<PlayEditorScreen>
    with SingleTickerProviderStateMixin {
  late BoardEdit _edit = BoardEdit(steps: widget.initial.steps);
  late PlayBoard _board = widget.initial.board;
  late BoardVariant _variant = widget.initial.variant;
  late final _player = StepPlayer(this);
  late bool _untouched = widget.freshBoard;
  late String _title = widget.initial.title;
  late String _note = widget.initial.note;
  BoardTool _tool = BoardTool.move;
  String? _selected;
  bool _dirty = false;
  bool _saving = false;

  /// While dragging: where it began, what's dragged, and the last point.
  BoardEdit? _dragStart;
  String? _dragId;
  BoardPoint? _dragLast;

  /// An arrow or line being drawn.
  List<BoardPoint>? _drawing;

  /// The field's width over its height, for distances on it.
  double get _aspect => fieldAspect(_board, _variant);

  /// The part of the field the board shows.
  BoardFrame get _frame => boardFrame(_board);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  PlayDraft get _draftNow => (
    board: _board,
    variant: _variant,
    title: _title,
    note: _note,
    steps: _edit.steps,
  );

  /// [next] on the board. The whiteboard keeps it on the device, except
  /// each move while dragging ([persist] false; the drag's end does).
  void _set(BoardEdit next, {bool dirty = true, bool persist = true}) {
    setState(() {
      _edit = next;
      _dirty = _dirty || dirty;
      _untouched = _untouched && !dirty;
    });
    if (widget.whiteboard && persist) {
      unawaited(
        ref.read(whiteboardStoreProvider).save(widget.groupId, _draftNow),
      );
    }
  }

  BoardElement? _byId(String? id) {
    for (final e in _edit.elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The next free number for a team marker: 1, 2, 3...
  String _nextNumber() {
    final used = {
      for (final e in _edit.elements)
        if (e is MarkerElement && e.side == MarkerSide.team) e.label,
    };
    var n = 1;
    while (used.contains('$n')) {
      n++;
    }
    return '$n';
  }

  // ---- Touch ---------------------------------------------------------------------

  /// A tap at [p] on the board, the whole field [width] pixels across.
  Future<void> _tap(BoardPoint p, double width) async {
    if (_player.playing) return;
    final l10n = AppLocalizations.of(context);
    final hit = hitTest(
      _edit.elements,
      p,
      _aspect,
      tolerance: _reachPixels / width,
    );
    switch (_tool) {
      case BoardTool.move:
        setState(() => _selected = hit?.id);
      case BoardTool.erase:
        if (hit != null) {
          _set(_edit.remove(hit.id));
          _selected = null;
        }
      case BoardTool.team || BoardTool.opponent || BoardTool.ball:
        if (!_edit.hasRoom) {
          showAppSnackBar(context, l10n.playFull(Limits.playElementsMax));
          return;
        }
        final side = switch (_tool) {
          BoardTool.team => MarkerSide.team,
          BoardTool.opponent => MarkerSide.opponent,
          _ => MarkerSide.ball,
        };
        _set(
          _edit.add(
            BoardElement.marker(
              id: newElementId(),
              at: p,
              side: side,
              label: side == MarkerSide.team ? _nextNumber() : '',
            ),
          ),
        );
      case BoardTool.text:
        final text = await askPlayText(
          context,
          title: l10n.playNoteOnBoard,
          label: l10n.playNoteOnBoardLabel,
          maxLength: Limits.playTextMax,
        );
        if (text == null || text.isEmpty || !mounted) return;
        _set(
          _edit.add(BoardElement.note(id: newElementId(), at: p, text: text)),
        );
      case BoardTool.run || BoardTool.pass || BoardTool.block || BoardTool.draw:
        break;
    }
  }

  void _panStart(BoardPoint p, double width) {
    if (_player.playing) return;
    switch (_tool) {
      case BoardTool.move:
        final hit = hitTest(
          _edit.elements,
          p,
          _aspect,
          tolerance: _reachPixels / width,
        );
        if (hit == null) return;
        setState(() {
          // A drag moves it; only a tap picks it, so the step's controls
          // stay in reach on a phone (and what was picked stays picked).
          if (_selected != hit.id) _selected = null;
          _dragStart = _edit;
          _dragId = hit.id;
          _dragLast = p;
        });
      case BoardTool.run || BoardTool.pass || BoardTool.block || BoardTool.draw:
        if (!_edit.hasRoom) return;
        setState(() => _drawing = [p]);
      case BoardTool.team ||
          BoardTool.opponent ||
          BoardTool.ball ||
          BoardTool.text ||
          BoardTool.erase:
        break;
    }
  }

  void _panUpdate(BoardPoint p) {
    if (_drawing case final path?) {
      setState(() => _drawing = [...path, p]);
      return;
    }
    final last = _dragLast;
    final dragged = _byId(_dragId);
    if (last == null || dragged == null) return;
    _set(
      _edit.moveLive(moveElement(dragged, p.x - last.x, p.y - last.y, _frame)),
      persist: false,
    );
    _dragLast = p;
  }

  void _panEnd(double width) {
    if (_drawing case final path?) {
      setState(() => _drawing = null);
      final points = simplifyPath(path, _aspect);
      // A tap-length scribble isn't an arrow.
      if (boardDistance(points.first, points.last, _aspect) * width < 12 &&
          points.length <= 2) {
        return;
      }
      final id = newElementId();
      _set(
        _edit.add(
          _tool == BoardTool.draw
              ? BoardElement.line(id: id, points: points)
              : BoardElement.arrow(
                  id: id,
                  kind: switch (_tool) {
                    BoardTool.pass => ArrowKind.pass,
                    BoardTool.block => ArrowKind.block,
                    _ => ArrowKind.run,
                  },
                  points: points,
                ),
        ),
      );
      return;
    }
    if (_dragStart case final start?) {
      _set(_edit.commitFrom(start));
    }
    setState(() {
      _dragStart = null;
      _dragId = null;
      _dragLast = null;
    });
  }

  BoardElement? get _draft {
    final path = _drawing;
    if (path == null || path.length < 2) return null;
    return _tool == BoardTool.draw
        ? BoardElement.line(id: '_', points: path)
        : BoardElement.arrow(
            id: '_',
            kind: switch (_tool) {
              BoardTool.pass => ArrowKind.pass,
              BoardTool.block => ArrowKind.block,
              _ => ArrowKind.run,
            },
            points: path,
          );
  }

  // ---- Selection ------------------------------------------------------------------

  Future<void> _editSelected() async {
    final l10n = AppLocalizations.of(context);
    final e = _byId(_selected);
    switch (e) {
      case MarkerElement():
        final next = await _MarkerLabelSheet.show(context, widget.groupId, e);
        if (next != null && mounted) _set(_edit.replace(next));
      case NoteElement():
        final text = await askPlayText(
          context,
          title: l10n.playNoteOnBoard,
          label: l10n.playNoteOnBoardLabel,
          maxLength: Limits.playTextMax,
          initial: e.text,
        );
        if (text == null || !mounted) return;
        _set(
          text.isEmpty
              ? _edit.remove(e.id)
              : _edit.replace(e.copyWith(text: text)),
        );
      case ArrowElement() || LineElement() || null:
        break;
    }
  }

  void _deleteSelected() {
    final id = _selected;
    if (id == null) return;
    _set(_edit.remove(id));
    setState(() => _selected = null);
  }

  // ---- Saving ---------------------------------------------------------------------

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final title = await askPlayText(
      context,
      title: l10n.playName,
      label: l10n.playNameLabel,
      maxLength: Limits.playTitleMax,
      initial: _title,
    );
    if (title == null || title.isEmpty || !mounted) return;
    setState(() {
      _title = title;
      _dirty = true;
    });
  }

  Future<void> _editNote() async {
    final l10n = AppLocalizations.of(context);
    final note = await askPlayText(
      context,
      title: l10n.playNotes,
      label: l10n.playNotesLabel,
      maxLength: Limits.playNoteMax,
      initial: _note,
      multiline: true,
    );
    if (note == null || !mounted) return;
    setState(() {
      _note = note;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_title.trim().isEmpty || widget.whiteboard) {
      await _rename();
      if (_title.trim().isEmpty || !mounted) return;
    }
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final draft = _draftNow;
    try {
      final repo = ref.read(playRepositoryProvider);
      final g = widget.groupId.value;
      if (widget.playId case final id?) {
        await repo.update(id, draft);
        if (!mounted) return;
        setState(() => _dirty = false);
        context.pop();
      } else if (widget.whiteboard) {
        // The whiteboard keeps its drawing; the team gets a copy.
        await repo.create(widget.groupId, UserId(uid), draft);
        if (!mounted) return;
        showAppSnackBar(context, l10n.playSaved(_title));
      } else {
        final id = await repo.create(widget.groupId, UserId(uid), draft);
        if (!mounted) return;
        setState(() => _dirty = false);
        context.pushReplacement('/g/$g/plays/${id.value}');
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e is PermissionDenied ? l10n.notAllowed : l10n.playSaveFailed,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openSaved() =>
      unawaited(context.push('/g/${widget.groupId.value}/plays/saved'));

  /// A different board, or a fresh one (the whiteboard's eraser for
  /// everything): asks first when there's drawing to lose.
  Future<void> _newBoard() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showNewPlaySheet(context, _board);
    if (choice == null || !mounted) return;
    if (!_untouched) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.playNewBoardTitle,
        message: l10n.playNewBoardBody,
        confirmLabel: l10n.playNewBoardConfirm,
        cancelLabel: l10n.cancel,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    final draft = draftFor(choice);
    setState(() {
      _board = draft.board;
      _variant = draft.variant;
      _title = '';
      _note = '';
      _selected = null;
    });
    _set(BoardEdit(steps: draft.steps), dirty: false);
    setState(() => _untouched = true);
  }

  /// Plays the steps from this one (or the first, from the last), the
  /// players and the ball gliding between them; again to stop.
  Future<void> _playSteps() async {
    if (_player.playing) {
      setState(_player.stop);
      return;
    }
    setState(() => _selected = null);
    final start = _edit.step == _edit.steps.length - 1 ? 0 : _edit.step;
    _set(_edit.show(start), dirty: false, persist: false);
    await _player.play(
      _edit.steps,
      start: start,
      onStep: (i) => _set(_edit.show(i), dirty: false, persist: false),
    );
    if (mounted) setState(() {});
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    return await showConfirmDialog(
      context,
      title: l10n.playDiscardTitle,
      message: l10n.playDiscardBody,
      confirmLabel: l10n.playDiscard,
      cancelLabel: l10n.playKeepEditing,
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _byId(_selected);
    final undo = _edit.canUndo ? () => _set(_edit.undo()) : null;
    final redo = _edit.canRedo ? () => _set(_edit.redo()) : null;
    // A laptop's keys: undo, redo, delete, and Escape to let go.
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): ?undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): ?undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
          ?redo,
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        shift: true,
      ): ?redo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true): ?redo,
      if (selected != null) ...{
        const SingleActivator(LogicalKeyboardKey.delete): _deleteSelected,
        const SingleActivator(LogicalKeyboardKey.backspace): _deleteSelected,
      },
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          setState(() => _selected = null),
    };
    // A phone has one bar over the board, so the board runs the screen's
    // width (BOARD-2); a tablet or laptop has room for the steps' own bar.
    final phone = MediaQuery.sizeOf(context).width < 600;
    final saveLabel = widget.whiteboard ? l10n.playSaveToTeam : l10n.save;
    // What's in More. A phone's whiteboard keeps a new board and the saved
    // plays here too, and goes without its title.
    final more = <_Action>[
      if (widget.whiteboard && phone) ...[
        (label: l10n.playNewBoard, onPressed: () => unawaited(_newBoard())),
      ],
      if (!widget.whiteboard)
        (label: l10n.playRename, onPressed: () => unawaited(_rename())),
      (label: l10n.playNotes, onPressed: () => unawaited(_editNote())),
      (label: l10n.playClearStep, onPressed: () => _set(_edit.clear())),
    ];
    void onShow(int i) => _set(_edit.show(i), dirty: false);
    void onAdd() => _set(_edit.addStep());
    void onRemove() => _set(_edit.removeStep());
    void onPlay() => unawaited(_playSteps());
    void onEditSelected() => unawaited(_editSelected());

    return PopScope(
      canPop: widget.whiteboard || !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: CallbackShortcuts(
        bindings: shortcuts,
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: phone
                ? _PhoneBar(
                    edit: _edit,
                    playing: _player.playing,
                    selected: selected,
                    saveLabel: saveLabel,
                    saveInMore: widget.whiteboard,
                    onSaved: widget.whiteboard ? _openSaved : null,
                    onSave: _saving ? null : () => unawaited(_save()),
                    onUndo: undo,
                    onRedo: redo,
                    onShow: onShow,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    onPlay: onPlay,
                    onEditSelected: onEditSelected,
                    onDeleteSelected: _deleteSelected,
                    more: more,
                  )
                : AppBar(
                    title: widget.whiteboard
                        ? Text(l10n.tabPlays)
                        : InkWell(
                            onTap: () => unawaited(_rename()),
                            child: Text(
                              _title.isEmpty ? l10n.playUntitled : _title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    actions: [
                      if (widget.whiteboard) ...[
                        IconButton(
                          tooltip: l10n.playNewBoard,
                          icon: const PlaysIcon(),
                          onPressed: () => unawaited(_newBoard()),
                        ),
                        // Named, not just an icon, so it's found.
                        TextButton.icon(
                          onPressed: _openSaved,
                          icon: const Icon(AppIcons.savedPlays),
                          label: Text(l10n.playsSaved),
                        ),
                      ],
                      IconButton(
                        tooltip: l10n.playUndo,
                        icon: const Icon(AppIcons.undo),
                        onPressed: undo,
                      ),
                      IconButton(
                        tooltip: l10n.playRedo,
                        icon: const Icon(AppIcons.redo),
                        onPressed: redo,
                      ),
                      _MoreButton(actions: more),
                      Padding(
                        padding: const EdgeInsets.only(right: Space.md),
                        child: FilledButton(
                          onPressed: _saving ? null : () => unawaited(_save()),
                          child: Text(saveLabel),
                        ),
                      ),
                    ],
                  ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= 720;
                  final board = _boardArea(phone: phone);
                  final tools = _Tools(
                    tool: _tool,
                    board: _board,
                    vertical: wide,
                    compact: phone,
                    onTool: (t) => setState(() {
                      _tool = t;
                      if (t != BoardTool.move) _selected = null;
                    }),
                  );
                  if (phone) {
                    return Column(
                      children: [
                        Expanded(child: board),
                        tools,
                      ],
                    );
                  }
                  final steps = _StepsBar(
                    edit: _edit,
                    playing: _player.playing,
                    onPlay: onPlay,
                    selected: selected,
                    onShow: onShow,
                    onAdd: onAdd,
                    onRemove: onRemove,
                    onEditSelected: onEditSelected,
                    onDeleteSelected: _deleteSelected,
                  );
                  if (wide) {
                    return Row(
                      children: [
                        tools,
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: board),
                              steps,
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: board),
                      steps,
                      tools,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The board, as big as it fits: on a phone, the screen's width, edge to
  /// edge.
  Widget _boardArea({required bool phone}) => Padding(
    padding: phone ? EdgeInsets.zero : const EdgeInsets.all(Space.md),
    child: Center(
      child: AspectRatio(
        aspectRatio: boardAspect(_board, _variant),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            // The board may show only part of the field (baseball's is cut
            // to the fence): where a touch is on the field, and how wide
            // the whole field is on screen.
            final frame = _frame;
            BoardPoint at(Offset o) => onBoard(
              frame.pointAt(o.dx / size.width, o.dy / size.height),
              frame,
            );
            final width = size.width / frame.width;
            return GestureDetector(
              key: const ValueKey('playBoard'),
              behavior: HitTestBehavior.opaque,
              // Report where a drag began, not where it was recognized:
              // arrows start at the finger.
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: (d) => unawaited(_tap(at(d.localPosition), width)),
              onDoubleTap: _selected == null
                  ? null
                  : () => unawaited(_editSelected()),
              onPanStart: (d) => _panStart(at(d.localPosition), width),
              onPanUpdate: (d) => _panUpdate(at(d.localPosition)),
              onPanEnd: (_) => _panEnd(width),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(phone ? 0 : 8),
                // While playing, the board repaints each frame.
                child: AnimatedBuilder(
                  animation: _player.controller,
                  builder: (context, child) => CustomPaint(
                    size: size,
                    painter: PlayPainter(
                      board: _board,
                      variant: _variant,
                      elements: _player.elements(_edit.steps, _edit.elements),
                      // What's being dragged is ringed while it moves.
                      selectedId: _dragId ?? _selected,
                      draft: _draft,
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    child: child,
                  ),
                  child: Semantics(
                    label: AppLocalizations.of(context).playBoardLabel(
                      boardName(AppLocalizations.of(context), _board),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// An action in a menu: its name, and what it does (null when it can't
/// be done now).
typedef _Action = ({String label, VoidCallback? onPressed});

/// More: the editor's [actions] that have no button of their own.
class _MoreButton extends StatelessWidget {
  const new({required this.actions});

  final List<_Action> actions;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: AppLocalizations.of(context).playMore,
    onSelected: (action) => action(),
    itemBuilder: (_) => [
      for (final a in actions)
        PopupMenuItem(
          value: a.onPressed,
          enabled: a.onPressed != null,
          child: Text(a.label),
        ),
    ],
  );
}

/// The editor's bar on a phone (BOARD-2): one row over the board, so the
/// board gets the screen's width and most of its height. The step's
/// controls sit on the left (or, with something picked, what to do with
/// it), and undo, redo, More, and Save on the right. What doesn't fit, in
/// this order, goes in More: removing a step, redo, playing the steps,
/// adding one, the step's controls, undo.
class _PhoneBar extends StatelessWidget implements PreferredSizeWidget {
  const new({
    required this.edit,
    required this.playing,
    required this.selected,
    required this.saveLabel,
    required this.saveInMore,
    required this.onSave,
    required this.onUndo,
    required this.onRedo,
    required this.onShow,
    required this.onAdd,
    required this.onRemove,
    required this.onPlay,
    required this.onEditSelected,
    required this.onDeleteSelected,
    required this.more,
    this.onSaved,
  });

  final BoardEdit edit;
  final bool playing;
  final BoardElement? selected;
  final String saveLabel;

  /// The whiteboard's Save to plays waits in More, first: the drawing
  /// stays on the device either way, and the board's tools get the room.
  final bool saveInMore;
  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final ValueChanged<int> onShow;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onPlay;
  final VoidCallback onEditSelected;
  final VoidCallback onDeleteSelected;

  /// Opens the saved plays: on the whiteboard, named first on the bar,
  /// or in More where it doesn't fit.
  final VoidCallback? onSaved;

  /// What's in More whatever fits.
  final List<_Action> more;

  @override
  Size get preferredSize => const Size.fromHeight(kMinInteractiveDimension);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double widthOf(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: text),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final back = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final s = selected;
    final many = edit.steps.length > 1;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) {
          const slot = kMinInteractiveDimension;
          // Back, More, and Save (unless it's in More) are always there.
          var room =
              box.maxWidth -
              Space.xs * 2 -
              slot * (1 + (back ? 1 : 0) + (saveInMore ? 0 : 1));
          bool fits(double width) {
            if (width > room) return false;
            room -= width;
            return true;
          }

          final overflow = <_Action>[];
          final lead = <Widget>[];
          Widget? button(
            String label,
            IconData icon,
            VoidCallback? onPressed, {
            bool filled = false,
          }) {
            if (!fits(slot)) {
              overflow.add((label: label, onPressed: onPressed));
              return null;
            }
            return filled
                ? IconButton.filledTonal(
                    // Ink on the cream (or navy) face: the theme's icon color is the
                    // page's, which is the face's own on a colored page (Olive, Candy).
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                    tooltip: label,
                    icon: Icon(icon),
                    onPressed: onPressed,
                  )
                : IconButton(
                    tooltip: label,
                    icon: Icon(icon),
                    onPressed: onPressed,
                  );
          }

          final undo = button(l10n.playUndo, AppIcons.undo, onUndo);
          if (s != null) {
            // What to do with the picked thing.
            lead.addAll([
              if (s is MarkerElement || s is NoteElement)
                ?button(
                  s is MarkerElement ? l10n.playLabel : l10n.playEditNote,
                  AppIcons.edit,
                  onEditSelected,
                ),
              ?button(l10n.playDeleteItem, AppIcons.delete, onDeleteSelected),
            ]);
          } else {
            final step = edit.step;
            final total = edit.steps.length;
            final previous = step > 0 ? () => onShow(step - 1) : null;
            final next = step < total - 1 ? () => onShow(step + 1) : null;
            if (many) {
              final label = l10n.playStepShort(step + 1, total);
              if (fits(slot * 2 + widthOf(label) + Space.xs * 2)) {
                lead.addAll([
                  IconButton(
                    tooltip: l10n.playStepBack,
                    icon: const Icon(AppIcons.stepBack),
                    onPressed: previous,
                  ),
                  Semantics(
                    container: true,
                    label: l10n.playStepOf(step + 1, total),
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: Text(label, style: text),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.playStepNext,
                    icon: const Icon(AppIcons.stepNext),
                    onPressed: next,
                  ),
                ]);
              } else {
                overflow.addAll([
                  (label: l10n.playStepBack, onPressed: previous),
                  (label: l10n.playStepNext, onPressed: next),
                ]);
              }
            }
            // The whiteboard's saved plays, by name, first on the bar where
            // there's room after
            // the steps' own controls, and before Add step's name: an icon alone in
            // More wasn't found (the owner's report, 2026-10-27).
            if (onSaved case final open? when s == null) {
              final label = l10n.playsSavedShort;
              if (fits(widthOf(label) + 58)) {
                lead.insert(
                  0,
                  TextButton.icon(
                    onPressed: open,
                    icon: const Icon(AppIcons.savedPlays),
                    label: Text(label),
                  ),
                );
              } else {
                overflow.add((label: l10n.playsSaved, onPressed: open));
              }
            }
            final add = edit.canAddStep && !playing ? onAdd : null;
            // Until there are steps, "Add step" says what they are: a
            // text button's icon, gap, and padding around its words.
            if (!many && fits(widthOf(l10n.playAddStep) + 58)) {
              lead.add(
                TextButton.icon(
                  onPressed: add,
                  icon: const Icon(AppIcons.add),
                  label: Text(l10n.playAddStep),
                ),
              );
            } else {
              lead.addAll([?button(l10n.playAddStep, AppIcons.add, add)]);
            }
          }
          final stepped = s == null && many;
          if (stepped) {
            lead.addAll([
              ?button(
                playing ? l10n.playStopPlaying : l10n.playPlaySteps,
                playing ? AppIcons.stop : AppIcons.play,
                onPlay,
                filled: true,
              ),
            ]);
          }
          final redo = button(l10n.playRedo, AppIcons.redo, onRedo);
          if (stepped) {
            lead.addAll([
              ?button(l10n.playRemoveStep, AppIcons.delete, onRemove),
            ]);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: Row(
              children: [
                if (back) const BackButton(),
                ...lead,
                const Spacer(),
                ?undo,
                ?redo,
                _MoreButton(
                  actions: [
                    if (saveInMore) (label: saveLabel, onPressed: onSave),
                    ...overflow,
                    ...more,
                  ],
                ),
                if (!saveInMore)
                  IconButton(
                    tooltip: saveLabel,
                    onPressed: onSave,
                    // A candy in the "you" color, with an ink icon.
                    style: GumdropButtons.of(context)
                        .icon(accent: GumdropColors.of(context).you),
                    icon: const Icon(AppIcons.save),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The tools: big enough for a finger, with their names for mice and
/// screen readers.
class _Tools extends StatelessWidget {
  const new({
    required this.tool,
    required this.board,
    required this.vertical,
    required this.onTool,
    this.compact = false,
  });

  final BoardTool tool;
  final PlayBoard board;
  final bool vertical;
  final ValueChanged<BoardTool> onTool;

  /// A phone's: a finger's size, no more, so the board has the room.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final football = board == PlayBoard.football;
    final items = [
      (BoardTool.move, AppIcons.toolMove, l10n.toolMove),
      (
        BoardTool.team,
        AppIcons.toolTeam,
        football ? l10n.toolOffense : l10n.toolTeam,
      ),
      (
        BoardTool.opponent,
        AppIcons.toolOpponent,
        football ? l10n.toolDefense : l10n.toolOpponent,
      ),
      (BoardTool.ball, AppIcons.toolBall, l10n.toolBall),
      (BoardTool.run, AppIcons.toolRun, l10n.toolRun),
      (BoardTool.pass, AppIcons.toolPass, l10n.toolPass),
      (BoardTool.block, AppIcons.toolBlock, l10n.toolBlock),
      (BoardTool.draw, AppIcons.toolDraw, l10n.toolDraw),
      (BoardTool.text, AppIcons.toolText, l10n.toolText),
      (BoardTool.erase, AppIcons.toolErase, l10n.toolErase),
    ];
    final side = compact ? kMinInteractiveDimension : 52.0;
    // The picked tool is a candy in the "you" color with ink on it; the
    // rest are the theme's tonal buttons. Set here, not left to the tonal
    // defaults, which draw the picked one's icon in its face's color on a
    // colored page (Olive, Candy).
    final c = GumdropColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final toolStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? c.you.face
            : scheme.surfaceContainerHighest,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? c.ink : scheme.onSurfaceVariant,
      ),
    );
    final buttons = [
      for (final (t, icon, label) in items)
        Padding(
          padding: EdgeInsets.all(compact ? Space.xs / 2 : Space.xs),
          child: Tooltip(
            message: label,
            child: Semantics(
              selected: t == tool,
              button: true,
              label: label,
              child: IconButton.filledTonal(
                isSelected: t == tool,
                style: toolStyle,
                iconSize: compact ? 24 : 26,
                constraints: BoxConstraints.tightFor(width: side, height: side),
                onPressed: () => onTool(t),
                icon: Icon(icon),
              ),
            ),
          ),
        ),
    ];
    return vertical
        ? SizedBox(
            width: 72,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Column(children: buttons),
            ),
          )
        : SizedBox(
            height: compact ? side + Space.sm : 68,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? Space.xs : Space.sm,
              ),
              child: Row(children: buttons),
            ),
          );
  }
}

/// The steps (BOARD-3), and what to do with the picked element.
class _StepsBar extends StatelessWidget {
  const new({
    required this.edit,
    required this.playing,
    required this.onPlay,
    required this.selected,
    required this.onShow,
    required this.onAdd,
    required this.onRemove,
    required this.onEditSelected,
    required this.onDeleteSelected,
  });

  final BoardEdit edit;
  final bool playing;
  final VoidCallback onPlay;
  final BoardElement? selected;
  final ValueChanged<int> onShow;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onEditSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.md,
        children: [
          // The steps, then what to do with them: a line each on a phone.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.playStepBack,
                icon: const Icon(AppIcons.stepBack),
                onPressed: edit.step > 0 ? () => onShow(edit.step - 1) : null,
              ),
              Text(l10n.playStepOf(edit.step + 1, edit.steps.length)),
              IconButton(
                tooltip: l10n.playStepNext,
                icon: const Icon(AppIcons.stepNext),
                onPressed: edit.step < edit.steps.length - 1
                    ? () => onShow(edit.step + 1)
                    : null,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (edit.steps.length > 1)
                IconButton.filledTonal(
                  // Ink on the cream (or navy) face: the theme's icon color is the
                  // page's, which is the face's own on a colored page (Olive, Candy).
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                  tooltip: playing ? l10n.playStopPlaying : l10n.playPlaySteps,
                  icon: Icon(playing ? AppIcons.stop : AppIcons.play),
                  onPressed: onPlay,
                ),
              TextButton.icon(
                onPressed: edit.canAddStep && !playing ? onAdd : null,
                icon: const Icon(AppIcons.add),
                label: Text(l10n.playAddStep),
              ),
              if (edit.steps.length > 1)
                IconButton(
                  tooltip: l10n.playRemoveStep,
                  icon: const Icon(AppIcons.delete),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (s != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s is MarkerElement || s is NoteElement)
                  TextButton.icon(
                    onPressed: onEditSelected,
                    icon: const Icon(AppIcons.edit),
                    label: Text(
                      s is MarkerElement ? l10n.playLabel : l10n.playEditNote,
                    ),
                  ),
                TextButton.icon(
                  onPressed: onDeleteSelected,
                  icon: const Icon(AppIcons.delete),
                  label: Text(l10n.playDeleteItem),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A marker's label: typed (a number or a position), or a roster player's
/// (BOARD-2). The label is only drawn on the play; nothing is saved on the
/// player (BOARD-4).
class _MarkerLabelSheet extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.marker});

  final GroupId groupId;
  final MarkerElement marker;

  static Future<MarkerElement?> show(
    BuildContext context,
    GroupId groupId,
    MarkerElement marker,
  ) => showModalBottomSheet<MarkerElement>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MarkerLabelSheet(groupId: groupId, marker: marker),
  );

  @override
  ConsumerState<_MarkerLabelSheet> createState() => _MarkerLabelState();
}

class _MarkerLabelState extends ConsumerState<_MarkerLabelSheet> {
  late final _label = TextEditingController(text: widget.marker.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _done(String label, {PlayerId? player}) =>
      Navigator.of(context)
          .pop(widget.marker.copyWith(label: label.trim(), playerId: player));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final players = widget.marker.side == MarkerSide.team
        ? ref.watch(playersProvider(widget.groupId)).value ?? const <Player>[]
        : const <Player>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.playLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.md),
          TextField(
            controller: _label,
            autofocus: true,
            maxLength: Limits.playLabelMax,
            decoration: InputDecoration(
              labelText: l10n.playLabelField,
              helperText: l10n.playLabelHelp,
            ),
            onSubmitted: _done,
          ),
          if (players.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(l10n.playLabelPlayer),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final p in players)
                  ActionChip(
                    label: Text(
                      [
                        p.displayName,
                        if (p.jerseyNumber case final n?) '#$n',
                      ].join(' '),
                    ),
                    onPressed: () => _done(
                      markerLabelFor(p.displayName, p.jerseyNumber),
                      player: p.id,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => _done(_label.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// What a marker for a roster player says: their number, or else their
/// first name, as short as a marker holds.
String markerLabelFor(String name, String? number) {
  if (number != null && number.trim().isNotEmpty) return number.trim();
  final first = name.trim().split(RegExp(r'\s+')).first;
  return first.length > Limits.playLabelMax
      ? first.substring(0, Limits.playLabelMax)
      : first;
}
