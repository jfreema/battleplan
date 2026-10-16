import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/plays/domain/board_layout.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/presentation/board_painter.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A play's board, drawn to fit: in lists, the viewer, and the chat.
class PlayBoardView extends StatelessWidget {
  const new({
    required this.board,
    required this.variant,
    required this.elements,
    this.semanticLabel,
    this.edgeToEdge = false,
    super.key,
  });

  final PlayBoard board;
  final BoardVariant variant;
  final List<BoardElement> elements;
  final String? semanticLabel;

  /// Square corners, for a board that runs a phone's width.
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: boardAspect(board, variant),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(edgeToEdge ? 0 : 6),
      child: CustomPaint(
        painter: PlayPainter(
          board: board,
          variant: variant,
          elements: elements,
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: Semantics(
          label:
              semanticLabel ?? boardName(AppLocalizations.of(context), board),
          image: true,
        ),
      ),
    ),
  );
}

/// [board]'s name, for pickers and lists.
String boardName(AppLocalizations l10n, PlayBoard board) => switch (board) {
  PlayBoard.baseball => l10n.boardBaseball,
  PlayBoard.basketball => l10n.boardBasketball,
  PlayBoard.soccer => l10n.boardSoccer,
  PlayBoard.football => l10n.boardFootball,
  PlayBoard.blank => l10n.boardBlank,
};

/// [v]'s name on [board]: half court, full pitch.
String variantName(AppLocalizations l10n, PlayBoard board, BoardVariant v) =>
    switch ((board, v)) {
      (PlayBoard.basketball, BoardVariant.half) => l10n.boardHalfCourt,
      (PlayBoard.basketball, BoardVariant.full) => l10n.boardFullCourt,
      (PlayBoard.soccer, BoardVariant.half) => l10n.boardHalfPitch,
      (PlayBoard.soccer, BoardVariant.full) => l10n.boardFullPitch,
      _ => boardName(l10n, board),
    };

/// A short text from the person, or null if they cancel: a play's title,
/// a marker's label, a note on the board.
Future<String?> askPlayText(
  BuildContext context, {
  required String title,
  required String label,
  required int maxLength,
  String initial = '',
  bool multiline = false,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 6 : 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        onSubmitted: multiline
            ? null
            : (v) => Navigator.of(dialog).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}
