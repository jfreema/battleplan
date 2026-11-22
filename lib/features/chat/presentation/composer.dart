import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
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
    this.onMentionTyped,
    this.canMentionEveryone = false,
    this.onAnnounce,
    this.announcing = false,
    this.onCancelAnnouncement,
    this.tray,
    this.hasAttachments = false,
    super.key,
  });

  /// The photos waiting to go, above the box (CHAT-3, #26).
  final Widget? tray;

  /// Photos are waiting: Send works with no text, the text being their
  /// caption, and the hint says so.
  final bool hasAttachments;

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

  /// Called when the text first has an @, so the screen can read who
  /// [mentionCandidates] are; the suggestions show once they arrive.
  final VoidCallback? onMentionTyped;

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
  void didUpdateWidget(Composer old) {
    super.didUpdateWidget(old);
    // The names arrived after the @ was typed: suggest them now.
    if (old.mentionCandidates != widget.mentionCandidates) _suggest();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Looks for an @ being typed at the cursor and lists who it could be.
  void _suggest() {
    if (_text.text.contains('@')) widget.onMentionTyped?.call();
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
    // Waiting photos go with no caption too.
    if ((text.isEmpty && !widget.hasAttachments) ||
        text.length > Limits.messageTextMax) {
      return;
    }
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
        (_text.text.trim().isNotEmpty || widget.hasAttachments) &&
        length <= Limits.messageTextMax;
    final replying = widget.replyingTo;
    final hint = widget.hasAttachments
        ? l10n.photoCaptionHint
        : widget.announcing
        ? l10n.announcementHint
        : widget.teamName.trim().isEmpty
        ? l10n.messageHint
        : l10n.messageTeamHint(widget.teamName.trim());
    // Photos only where there are no polls (a direct conversation, CHAT-19).
    final addTooltip = widget.onCreatePoll == null
        ? l10n.addPhotosToMessage
        : l10n.addToMessage;
    final c = GumdropColors.of(context);
    // The box is a panel, so lettered as panels are (Candy Pop's navy on
    // white, #86).
    final panel = c.card;
    // Boot Camp Mix's composer (#85): one rounded panel (corner 27) in a
    // 3 px ink outline on a hard 3/3 shadow, the + at its left and Send at
    // its right, a 36 px red round button in a 2.5 px ink outline with a
    // white arrow, its arrow faded with nothing to send.
    // The + sits inside the field, at its left edge: 24 px in 48 × 48.
    final addStyle = IconButton.styleFrom(
      fixedSize: const Size(48, 46),
      minimumSize: const Size(48, 46),
      padding: EdgeInsets.zero,
      iconSize: 24,
      foregroundColor: panel.textOnPage,
    );
    final red = c.cherry.face;
    final sendStyle =
        IconButton.styleFrom(
          fixedSize: const Size(48, 46),
          minimumSize: const Size(48, 46),
          padding: EdgeInsets.zero,
          iconSize: 20,
        ).copyWith(
          // The round face is drawn by the icon's own box; the button is only
          // its 48 px tap area.
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(c.ink.withValues(alpha: 0.08)),
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(27),
      borderSide: BorderSide(color: c.ink, width: 3),
    );
    final plus =
        (widget.onAttachBlocked != null &&
            widget.onCreatePoll == null &&
            widget.onAnnounce == null)
        ? IconButton(
            tooltip: addTooltip,
            style: addStyle,
            onPressed: widget.onAttachBlocked,
            icon: Icon(AppIcons.add, weight: 700, color: c.textMuted),
          )
        : widget.onPickPhotos != null
        ? PopupMenuButton<VoidCallback>(
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
          )
        : null;
    final send = IconButton(
      tooltip: l10n.send,
      style: sendStyle,
      onPressed: canSend ? _send : null,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: red,
          shape: BoxShape.circle,
          border: Border.all(color: c.ink, width: 2.5),
        ),
        child: Icon(
          AppIcons.arrowUp,
          weight: 700,
          size: 20,
          color: canSend ? Colors.white : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
    final box = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 17, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DecoratedBox(
                // The hard shadow under the panel.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(color: c.pageShadow, offset: const Offset(3, 3)),
                  ],
                ),
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
                    style: ChatText.of(Theme.of(context).textTheme.bodyLarge)
                        .copyWith(color: panel.textOnPage),
                    cursorColor: panel.textOnPage,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: hint,
                      // One line, ending "…", however long the team's name.
                      hintMaxLines: 1,
                      hintStyle: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: panel.textMutedOnPage,
                      ),
                      prefixIcon: plus,
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 46,
                      ),
                      suffixIcon: send,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 46,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: panel.inputFill,
                      // 48 px tall, the smallest tap target (the
                      // design's 46 is just under it).
                      contentPadding: EdgeInsets.fromLTRB(
                        plus == null ? 16 : 0,
                        12,
                        0,
                        12,
                      ),
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      // Focused, the outline thickens a little.
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: c.ink, width: 3.5),
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
        if (widget.tray case final tray?)
          Padding(padding: const EdgeInsets.only(top: 6), child: tray),
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
