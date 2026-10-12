import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/quote_block.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The message box (CHAT-2): several lines up to 4,000 characters, a counter
/// near the limit, and Send. On a keyboard, Enter sends and Shift+Enter adds
/// a line.
class Composer extends StatefulWidget {
  const new({
    required this.onSend,
    this.onPickPhotos,
    this.onTakePhoto,
    this.onAttachBlocked,
    this.replyingTo,
    this.onCancelReply,
    super.key,
  });

  /// The message being replied to, shown above the box with ✕ (CHAT-13).
  final Message? replyingTo;
  final VoidCallback? onCancelReply;

  final void Function(String text) onSend;

  /// The + menu (CHAT-2): Photo library, and Camera on phones. Polls join
  /// it in M5.
  final VoidCallback? onPickPhotos;
  final VoidCallback? onTakePhoto;

  /// When set, attaching is off (the team's storage is full, STORE-4): +
  /// calls this to say why instead of opening the menu. Text still sends.
  final VoidCallback? onAttachBlocked;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent &&
        enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty || text.length > Limits.messageTextMax) return;
    widget.onSend(text);
    _text.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final length = _text.text.length;
    final canSend =
        _text.text.trim().isNotEmpty && length <= Limits.messageTextMax;
    final replying = widget.replyingTo;
    final box = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.xs,
          Space.xs,
          Space.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.onAttachBlocked case final blocked?)
              IconButton(
                tooltip: l10n.addToMessage,
                onPressed: blocked,
                icon: Icon(
                  AppIcons.add,
                  color: Theme.of(context).disabledColor,
                ),
              )
            else if (widget.onPickPhotos != null)
              PopupMenuButton<VoidCallback>(
                tooltip: l10n.addToMessage,
                icon: const Icon(AppIcons.add),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: widget.onPickPhotos,
                    child: ListTile(
                      leading: const Icon(AppIcons.photo),
                      title: Text(l10n.photoLibrary),
                    ),
                  ),
                  if (widget.onTakePhoto case final take?)
                    PopupMenuItem(
                      value: take,
                      child: ListTile(
                        leading: const Icon(AppIcons.camera),
                        title: Text(l10n.camera),
                      ),
                    ),
                ],
              ),
            Expanded(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                minLines: 1,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Corners.bubble),
                  ),
                  // The counter appears only near the limit.
                  counterText: length > Limits.messageTextMax - 500
                      ? '$length / ${Limits.messageTextMax}'
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.send,
              onPressed: canSend ? _send : null,
              icon: const Icon(AppIcons.send),
            ),
          ],
        ),
      ),
    );
    if (replying == null) return box;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.xs, 0),
          child: Row(
            children: [
              Expanded(
                child: QuoteBlock(
                  authorName: replying.authorName,
                  text: quoteText(l10n, replying.type, replying.text),
                ),
              ),
              IconButton(
                tooltip: l10n.cancelReply,
                icon: const Icon(AppIcons.close),
                onPressed: widget.onCancelReply,
              ),
            ],
          ),
        ),
        box,
      ],
    );
  }
}
