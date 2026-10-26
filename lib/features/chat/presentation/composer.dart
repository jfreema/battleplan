import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/features/chat/domain/mentions.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/quote_block.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The message box (CHAT-2): several lines up to 4,000 characters, a counter
/// near the limit, and Send. On a keyboard, Enter sends and Shift+Enter adds
/// a line. Typing @ suggests team members (CHAT-14): tap one, or pick with
/// the arrow keys and Enter or Tab; Escape closes the list. Admins can
/// write an announcement from the + menu (CHAT-15).
class Composer extends StatefulWidget {
  const new({
    required this.onSend,
    this.onPickPhotos,
    this.onTakePhoto,
    this.onCreatePoll,
    this.onAttachBlocked,
    this.replyingTo,
    this.onCancelReply,
    this.teamName = '',
    this.mentionCandidates = const [],
    this.canMentionEveryone = false,
    this.onAnnounce,
    this.announcing = false,
    this.onCancelAnnouncement,
    super.key,
  });

  /// Names the team in the hint, "Message Thunder U14…" (SPEC §5.4).
  final String teamName;

  /// The message being replied to, shown above the box with ✕ (CHAT-13).
  final Message? replyingTo;
  final VoidCallback? onCancelReply;

  final void Function(String text) onSend;

  /// The + menu (CHAT-2): Photo library, Camera on phones, and Poll for
  /// people allowed to make polls (POLL-1).
  final VoidCallback? onPickPhotos;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onCreatePoll;

  /// When set, attaching photos is off (the team's storage is full,
  /// STORE-4): the photo items call this to say why. Polls and text still
  /// work, so + opens the menu when there's a poll to make, and otherwise
  /// says why straight away.
  final VoidCallback? onAttachBlocked;

  /// Who typing @ suggests (CHAT-14), and whether @everyone is among them
  /// (admins).
  final List<MentionCandidate> mentionCandidates;
  final bool canMentionEveryone;

  /// Admins: the + menu's Announcement (CHAT-15). While [announcing], a
  /// banner says the next message notifies everyone, with ✕
  /// ([onCancelAnnouncement]).
  final VoidCallback? onAnnounce;
  final bool announcing;
  final VoidCallback? onCancelAnnouncement;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _text = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);

  /// The members matching the @ being typed, and the one Enter would pick.
  List<MentionCandidate> _suggestions = const [];
  int _selected = 0;

  /// Where the @ being typed starts.
  int _mentionStart = 0;

  /// Closed with Escape until the @ word changes.
  String? _dismissed;

  @override
  void initState() {
    super.initState();
    _text.addListener(_suggest);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Looks for an @ being typed at the cursor and lists who it could be.
  void _suggest() {
    final sel = _text.selection;
    final q = sel.isValid && sel.isCollapsed
        ? mentionQueryAt(_text.text, sel.baseOffset)
        : null;
    final key = q == null ? null : '${q.start}:${q.query}';
    final found = q == null || key == _dismissed
        ? const <MentionCandidate>[]
        : mentionSuggestions(
            q.query,
            widget.mentionCandidates,
            everyone: widget.canMentionEveryone,
          );
    if (found.isEmpty && _suggestions.isEmpty) return;
    setState(() {
      _suggestions = found;
      _selected = 0;
      if (q != null) _mentionStart = q.start;
    });
  }

  /// Puts "@Name " in place of the @ being typed.
  void _pick(MentionCandidate c) {
    final cursor = _text.selection.baseOffset;
    final insert = mentionText(c);
    final text = _text.text.replaceRange(_mentionStart, cursor, insert);
    // A longer name starting the same way ("Mary Ann Lee" after "Mary
    // Ann") isn't offered again until something more is typed.
    _dismissed = '$_mentionStart:${insert.substring(1)}';
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: _mentionStart + insert.length),
    );
    Haptics.selection();
    setState(() => _suggestions = const []);
    _focus.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    // While suggestions show, the arrows, Enter, and Tab pick one, and
    // Escape closes the list (CHAT-14).
    if (_suggestions.isNotEmpty) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowUp) {
        final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
        setState(() => _selected = (_selected + step) % _suggestions.length);
        return KeyEventResult.handled;
      }
      if ((enter || key == LogicalKeyboardKey.tab) &&
          event is KeyDownEvent &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _pick(_suggestions[_selected]);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        final sel = _text.selection;
        final q = mentionQueryAt(_text.text, sel.baseOffset);
        setState(() {
          _dismissed = q == null ? null : '${q.start}:${q.query}';
          _suggestions = const [];
        });
        return KeyEventResult.handled;
      }
    }
    // Enter while an input method is still composing a word picks the
    // word, not sends.
    if (event is KeyDownEvent &&
        enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !_text.value.composing.isValid) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty || text.length > Limits.messageTextMax) return;
    Haptics.light();
    widget.onSend(text);
    _text.clear();
    setState(() {
      _suggestions = const [];
      _dismissed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final length = _text.text.length;
    final canSend =
        _text.text.trim().isNotEmpty && length <= Limits.messageTextMax;
    final replying = widget.replyingTo;
    final hint = widget.announcing
        ? l10n.announcementHint
        : widget.teamName.trim().isEmpty
        ? l10n.messageHint
        : l10n.messageTeamHint(widget.teamName.trim());
    // Photos only where there are no polls (a direct conversation, CHAT-19).
    final addTooltip = widget.onCreatePoll == null
        ? l10n.addPhotosToMessage
        : l10n.addToMessage;
    final c = GumdropColors.of(context);
    final buttons = GumdropButtons.of(context);
    // The 46 px + and Send gumdrops (§3.13): + secondary, Send in the
    // "you" color. With nothing to send it stays candy-colored, its arrow
    // faded, as the design draws the empty composer.
    final addStyle = buttons
        .icon(size: 46)
        .copyWith(iconSize: const WidgetStatePropertyAll(26));
    final sendLip = GumdropShape.lipFor(46);
    final sendStyle = buttons
        .icon(size: 46, accent: c.you)
        .copyWith(
          iconSize: const WidgetStatePropertyAll(22),
          backgroundColor: WidgetStatePropertyAll(c.you.face),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.ink.withValues(alpha: 0.5)
                : c.ink,
          ),
          shape: WidgetStateProperty.resolveWith(
            (s) => buttons.style.styled(
              GumdropShape(
                lip: sendLip,
                lipColor: c.you.lip,
                pressed: s.contains(WidgetState.pressed) ? 1 : 0,
              ),
            ),
          ),
          padding: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed)
                ? EdgeInsets.only(top: sendLip)
                : EdgeInsets.only(bottom: sendLip),
          ),
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(23),
      borderSide: BorderSide(color: c.inputBorder, width: 2),
    );
    final box = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 6, Space.lg, Space.sm),
        child: Row(
          // The buttons carry a 4 px lip below their faces; the box lines
          // up with the faces.
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.onAttachBlocked case final blocked?
                when widget.onCreatePoll == null && widget.onAnnounce == null)
              IconButton(
                tooltip: addTooltip,
                style: addStyle,
                onPressed: blocked,
                icon: Icon(AppIcons.add, weight: 700, color: c.textMuted),
              )
            else if (widget.onPickPhotos != null)
              PopupMenuButton<VoidCallback>(
                tooltip: addTooltip,
                style: addStyle,
                icon: const Icon(AppIcons.add, weight: 700),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: widget.onAttachBlocked ?? widget.onPickPhotos,
                    child: ListTile(
                      leading: const Icon(AppIcons.photo),
                      title: Text(l10n.photoLibrary),
                    ),
                  ),
                  if (widget.onTakePhoto case final take?)
                    PopupMenuItem(
                      value: widget.onAttachBlocked ?? take,
                      child: ListTile(
                        leading: const Icon(AppIcons.camera),
                        title: Text(l10n.camera),
                      ),
                    ),
                  if (widget.onCreatePoll case final poll?)
                    PopupMenuItem(
                      value: poll,
                      child: ListTile(
                        leading: const Icon(AppIcons.poll),
                        title: Text(l10n.createPoll),
                      ),
                    ),
                  // Admins (CHAT-15). Full storage doesn't stop it.
                  if (widget.onAnnounce case final announce?)
                    PopupMenuItem(
                      value: () {
                        announce();
                        _focus.requestFocus();
                      },
                      child: ListTile(
                        leading: const Icon(AppIcons.announcement),
                        title: Text(l10n.announceAction),
                      ),
                    ),
                ],
              ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: sendLip),
                // The box is in the card's colors (navy text in Candy).
                child: GumdropSurface(
                  child: Builder(
                    builder: (context) => TextField(
                      controller: _text,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      // What's typed looks as it will once sent, but in
                      // the box's weight (ChatText).
                      style: ChatText.of(
                        Theme.of(context).textTheme.bodyLarge,
                      ).copyWith(color: GumdropColors.of(context).textPrimary),
                      cursorColor: GumdropColors.of(context).textPrimary,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: GumdropColors.of(context).textMuted,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: c.inputFill,
                        // 48 px tall, the smallest tap target (the
                        // design's 46 is just under it).
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(
                            color: GumdropColors.of(context).textPrimary,
                            width: 2,
                          ),
                        ),
                        // The counter appears only near the limit, on the
                        // page under the box.
                        counterStyle: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: c.textMutedOnPage,
                        ),
                        counterText: length > Limits.messageTextMax - 500
                            ? '$length / ${Limits.messageTextMax}'
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            IconButton(
              tooltip: l10n.send,
              style: sendStyle,
              onPressed: canSend ? _send : null,
              // The paper plane points up and to the right (design §3.14).
              icon: Transform.rotate(
                angle: -math.pi / 4,
                child: const Icon(AppIcons.send, weight: 700),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_suggestions.isNotEmpty)
          _MentionList(
            suggestions: _suggestions,
            selected: _selected,
            onPick: _pick,
          ),
        if (widget.announcing)
          _AnnouncementBanner(onCancel: widget.onCancelAnnouncement),
        if (replying != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 6, Space.sm, 0),
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
                  icon: Icon(AppIcons.close, color: c.textOnPage),
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

/// The members matching the @ being typed (CHAT-14), above the box.
class _MentionList extends StatelessWidget {
  const new({
    required this.suggestions,
    required this.selected,
    required this.onPick,
  });

  final List<MentionCandidate> suggestions;
  final int selected;
  final void Function(MentionCandidate) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    return Semantics(
      container: true,
      label: l10n.mentionSuggestions,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, 0),
        // Its own Material, so the rows' highlight and ink show: a card,
        // in the card's colors.
        child: GumdropSurface(
          child: Material(
            color: c.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              side: c.surfaceBorderWidth == 0
                  ? BorderSide.none
                  : BorderSide(
                      color: c.surfaceBorder,
                      width: c.surfaceBorderWidth,
                    ),
              borderRadius: BorderRadius.circular(Corners.tile),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, c) in suggestions.indexed)
                  ListTile(
                    dense: true,
                    selected: i == selected,
                    leading: c.uid.isEmpty
                        ? const Icon(AppIcons.group)
                        : Avatar(name: c.name, colorKey: c.uid, size: 28),
                    title: Text(
                      c.uid.isEmpty ? l10n.mentionEveryoneName : c.name,
                    ),
                    subtitle: c.uid.isEmpty
                        ? Text(l10n.mentionEveryoneHelp)
                        : null,
                    onTap: () => onPick(c),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Announcement: notifies everyone…" above the box while an admin writes
/// one (CHAT-15), with ✕ to send a plain message instead.
class _AnnouncementBanner extends StatelessWidget {
  const new({this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    // A lemon note, as announcements are lemon in the chat.
    return Container(
      margin: const EdgeInsets.fromLTRB(Space.lg, 6, Space.lg, 0),
      padding: const EdgeInsets.only(left: Space.md),
      decoration: BoxDecoration(
        color: c.lemon.face,
        borderRadius: BorderRadius.circular(Corners.tile),
      ),
      child: Row(
        children: [
          Icon(AppIcons.announcement, color: c.ink),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              l10n.announcementBanner,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: c.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.cancelAnnouncement,
            icon: Icon(AppIcons.close, color: c.ink),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
