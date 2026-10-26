import 'dart:async';
import 'dart:math' as math;

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/haptics.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/domain/mentions.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/presentation/direct_actions.dart';
import 'package:battleplan/features/chat/presentation/photo_grid.dart';
import 'package:battleplan/features/chat/presentation/photo_viewer.dart';
import 'package:battleplan/features/chat/presentation/quote_block.dart';
import 'package:battleplan/features/chat/presentation/reactions.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/polls/polls.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/features/schedule/schedule.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One row of the chat: a system line, or a bubble with the sender's name
/// and photo at the start of their group (CHAT-1). Tapping a bubble shows
/// its time; on the web, hovering does.
class MessageTile extends ConsumerStatefulWidget {
  const new({
    required this.message,
    required this.mine,
    required this.startsGroup,
    required this.endsGroup,
    this.showSent = false,
    this.highlighted = false,
    this.pinned = false,
    this.bubbleColor,
    this.quoted,
    this.onReply,
    this.onOpenQuote,
    super.key,
  });

  final Message message;
  final bool mine;
  final bool startsGroup;
  final bool endsGroup;

  /// Shows "Sent" under it: my newest message, once the server has it.
  /// Every other message of mine says so with its time (tap or hover).
  final bool showSent;

  /// Briefly tinted after jumping to it from a quote.
  final bool highlighted;

  /// On the bar at the top of the chat (CHAT-15): says "Pinned", and the
  /// menu offers Unpin to admins.
  final bool pinned;

  /// My bubbles' color from the team's chat look (CHAT-18); null uses the
  /// brand color.
  final Color? bubbleColor;

  /// The original of a reply, when loaded, for the quote until the server
  /// has written `replyPreview`.
  final Message? quoted;

  /// Starts a reply (menu, or swipe right on phones). Null where replying
  /// isn't allowed.
  final VoidCallback? onReply;

  /// Jumps to the quoted original (CHAT-13).
  final VoidCallback? onOpenQuote;

  @override
  ConsumerState<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends ConsumerState<MessageTile> {
  bool _showTime = false;
  bool _hovering = false;

  /// Focused from the keyboard (SPEC §7.6), and so ringed.
  bool _focused = false;

  /// A blocked person's message the viewer chose to see.
  bool _revealed = false;

  /// How far the bubble is dragged right toward a reply (phones).
  double _swipe = 0;
  static const _swipeToReply = 64.0;

  Future<void> _react(Reaction r) => ref
      .read(chatMessagesProvider(widget.message.groupId).notifier)
      .react(widget.message, r);

  /// Who reacted, grouped by reaction (CHAT-6).
  Future<void> _showWho() => showAdaptiveSheet<void>(
    context,
    builder: (_) => ReactionsSheet(message: widget.message),
  );

  /// On the web, a small button beside a hovered bubble opens the menu.
  Widget _hoverButton() => IconButton(
    tooltip: AppLocalizations.of(context).messageMenu,
    visualDensity: VisualDensity.compact,
    icon: const Icon(AppIcons.addReaction, size: 20),
    onPressed: () => unawaited(_openMenu()),
  );

  /// Edits my message's text in a dialog (CHAT-15).
  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context);
    final m = widget.message;
    final text = TextEditingController(text: m.text);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.editMessage),
        content: TextField(
          controller: text,
          autofocus: true,
          minLines: 1,
          maxLines: 8,
          maxLength: Limits.messageTextMax,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final updated = text.text.trim();
    if (save != true || !mounted || updated == m.text.trim()) return;
    if (updated.isEmpty && m.attachments.isEmpty) return;
    try {
      await ref.read(chatMessagesProvider(m.groupId).notifier).edit(m, updated);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.editFailed);
    }
  }

  /// Pins or unpins it on the bar at the top of the chat (CHAT-15).
  Future<void> _setPinned({required bool pinned}) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(chatMessagesProvider(widget.message.groupId).notifier)
          .setPinned(widget.message, pinned: pinned);
      if (mounted) {
        showAppSnackBar(context, pinned ? l10n.pinnedDone : l10n.unpinnedDone);
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e is InvalidInput && e.message == 'too-many-pins'
            ? l10n.pinLimitReached(Limits.pinnedMessagesMax)
            : l10n.pinFailed,
      );
    }
  }

  /// Asks first, then deletes for everyone (CHAT-8).
  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteMessageTitle,
      // Deleting a poll's message deletes the poll (POLL-5).
      message: widget.message.type == MessageType.poll
          ? l10n.deletePollBody
          : l10n.deleteMessageBody,
      confirmLabel: l10n.deleteMessageAction,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(chatMessagesProvider(widget.message.groupId).notifier)
          .delete(widget.message);
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.errorDeleteMessage);
    }
  }

  /// React, Reply, Copy text, Delete (and Report with task 66). A super
  /// admin viewing the team gets Copy text and Delete only (ADMIN-3).
  Future<void> _openMenu() async {
    final m = widget.message;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authUserProvider).value;
    final me = user?.uid;
    final viewing = ref.read(viewingAsSuperAdminProvider(m.groupId));
    final superAdmin = user?.isSuperAdmin ?? false;
    // A direct conversation (CHAT-19) has no admins: each person deletes
    // their own, and super admins act on reports from the admin panel.
    final direct = ref.read(groupProvider(m.groupId)).value?.isDirect ?? false;
    final canModerate =
        !direct &&
        (superAdmin ||
            (ref.read(myMembershipProvider(m.groupId))?.isAdmin ?? false));
    // An archived team is read-only (TEAM-9): deleteMessage refuses
    // everyone there but a super admin.
    final archived =
        ref.read(groupProvider(m.groupId)).value?.isArchived ?? false;
    final canDelete = (widget.mine || canModerate) && (!archived || superAdmin);
    await showAdaptiveSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        // Scrolls when large text or a short screen can't fit it all.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!viewing) ...[
                ReactionPicker(
                  mine: me == null ? null : m.reactions[me],
                  onPick: (r) {
                    Navigator.of(sheet).pop();
                    Haptics.light();
                    fireAndForget(_react(r));
                  },
                ),
                const Divider(height: Space.xl),
              ],
              // Also on a chip's long-press or right-click (CHAT-6).
              if (m.reactions.isNotEmpty)
                ListTile(
                  leading: const Icon(AppIcons.roster),
                  title: Text(l10n.whoReacted),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(_showWho());
                  },
                ),
              if (widget.onReply case final reply?)
                ListTile(
                  leading: const Icon(AppIcons.reply),
                  title: Text(l10n.reply),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    reply();
                  },
                ),
              // Edit my own text or photo caption (CHAT-15).
              if (widget.mine &&
                  !m.pending &&
                  (m.type == MessageType.text || m.type == MessageType.image))
                ListTile(
                  leading: const Icon(AppIcons.edit),
                  title: Text(l10n.editMessage),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(_edit());
                  },
                ),
              if (m.text.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(AppIcons.copy),
                  title: Text(l10n.copyText),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(Clipboard.setData(ClipboardData(text: m.text)));
                    showAppSnackBar(context, l10n.textCopied);
                  },
                ),
              // Admins pin to the bar at the top (CHAT-15); not on an
              // archived team, which is read-only.
              if (canModerate && !archived && !m.pending)
                ListTile(
                  leading: Icon(widget.pinned ? AppIcons.unpin : AppIcons.pin),
                  title: Text(
                    widget.pinned ? l10n.unpinMessage : l10n.pinMessage,
                  ),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(_setPinned(pinned: !widget.pinned));
                  },
                ),
              // Other people's messages: report them or block their author
              // (SAFE-1, SAFE-2).
              if (!widget.mine && !viewing) ...[
                ListTile(
                  leading: const Icon(AppIcons.report),
                  title: Text(l10n.reportMessage),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(
                      showReportSheet(
                        context,
                        ref,
                        groupId: m.groupId,
                        targetType: ReportTargetType.message,
                        targetId: m.id,
                        direct: direct,
                      ),
                    );
                  },
                ),
                // An imported author has no account to block.
                if (m.importedFrom == null &&
                    !ref.read(blockedIdsProvider).contains(m.authorId))
                  ListTile(
                    leading: const Icon(AppIcons.block),
                    title: Text(l10n.blockPerson(m.authorName)),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      unawaited(
                        confirmBlock(
                          context,
                          ref,
                          uid: UserId(m.authorId),
                          name: m.authorName,
                        ),
                      );
                    },
                  ),
              ],
              // Your own messages; admins and super admins can delete any.
              if (canDelete)
                ListTile(
                  leading: Icon(
                    AppIcons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(l10n.deleteMessage),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    unawaited(_confirmDelete());
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the author's page (TEAM-15), when they're someone on the team,
  /// or in the conversation, now: not for system lines, imported messages,
  /// or a deleted account. From a team's chat it names the team, which the
  /// page then lists (they've been seen there).
  VoidCallback? _authorTap(Message m) {
    if (m.isSystem || m.importedFrom != null) return null;
    if (!ref.watch(memberNamesProvider(m.groupId)).containsKey(m.authorId)) {
      return null;
    }
    final direct = ref.watch(groupProvider(m.groupId)).value?.isDirect ?? false;
    return () => openPersonPage(
      context,
      UserId(m.authorId),
      teamId: direct ? null : m.groupId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final web = ref.watch(browserInfoProvider).isWeb;
    // A direct conversation (CHAT-19) is laid out as iMessage lays out one:
    // no photo or name beside the other person's messages.
    final direct = ref.watch(groupProvider(m.groupId)).value?.isDirect ?? false;
    final c = GumdropColors.of(context);
    if (m.isSystem) {
      // CHAT-10: small centered lines like "Sam joined", on the page.
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Space.sm,
          horizontal: Space.xl,
        ),
        child: Text(
          m.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: c.textMutedOnPage,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final mine = widget.mine;
    // Messages from someone I blocked are collapsed until I tap Show
    // (CHAT-12).
    if (!mine &&
        !_revealed &&
        ref.watch(blockedIdsProvider).contains(m.authorId)) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                l10n.blockedMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textMutedOnPage,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(l10n.show),
            ),
          ],
        ),
      );
    }
    final deleted = m.deletedAt != null;
    // An admin's announcement (CHAT-15) looks the same from everyone: a
    // lemon bubble.
    final announcement = m.announcement && !deleted;
    final custom = mine && !announcement ? widget.bubbleColor : null;
    // Others' bubbles are cards (Gumdrop Pop §3.14); mine are candy, in the
    // chat look's color or the theme's "you" color, with ink text, or white
    // on a dark team color.
    final background = announcement
        ? c.lemon.face
        : mine
        ? custom ?? c.you.face
        : c.surface;
    final foreground = announcement
        ? c.ink
        : mine
        ? (custom == null ? c.ink : bubbleTextOn(c, custom))
        : c.textPrimary;
    final muted = mine || announcement
        ? foreground
        : (deleted ? c.textMutedOnPage : c.textMuted);
    final time = m.createdAt == null
        ? null
        : MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(m.createdAt!.toLocal()));
    // @mentions (CHAT-14) in bold, and the ones naming me (or everyone)
    // stand out, by the mentioned people's current names. In my bubble a
    // mention is a white pill, as the design has it.
    final names = m.mentions.isEmpty
        ? const <String, String>{}
        : ref.watch(memberNamesProvider(m.groupId));
    final highlights = <TextHighlight>[
      for (final r in mentionRanges(
        m.text,
        names: {for (final uid in m.mentions) uid: ?names[uid]},
        everyone: m.mentionsEveryone,
        me: ref.watch(authUserProvider).value?.uid,
      ))
        (
          start: r.start,
          end: r.end,
          style: mine
              ? TextStyle(
                  fontWeight: FontWeight.w900,
                  color: c.ink,
                  backgroundColor: GumdropColors.mentionBg,
                )
              : r.isMe
              ? TextStyle(
                  fontWeight: FontWeight.w900,
                  color: c.ink,
                  backgroundColor: c.lemon.face,
                )
              : const TextStyle(fontWeight: FontWeight.w900),
        ),
    ];
    // "edited" and "Pinned" (CHAT-15) beside the time. Where an imported
    // message came from (IMPORT-9) goes with the name, once per run.
    final marks = [
      if (m.editedAt != null && !deleted) l10n.edited,
      if (widget.pinned && !deleted) l10n.pinnedBadge,
    ].join(' · ');
    final headerMarks = [
      if (m.importedFrom case final from?) l10n.importedMark(_appName(from)),
      if (marks.isNotEmpty) marks,
    ].join(' · ');

    final hasText = m.text.trim().isNotEmpty;
    // A reply's quote (CHAT-13): the server's copy, or the loaded original
    // until the server has written it.
    final preview = m.replyPreview;
    final original = widget.quoted;
    final quote = m.replyToId == null || deleted
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: QuoteBlock(
              authorName: preview?.authorName ?? original?.authorName ?? '',
              text: preview != null
                  ? quoteText(l10n, preview.type, preview.text)
                  : original == null
                  ? ''
                  : quoteText(l10n, original.type, original.text),
              deleted:
                  (preview?.deleted ?? false) || original?.deletedAt != null,
              onTap: widget.onOpenQuote,
            ),
          );
    // A poll shows as its card (POLL-2, CHAT-11); its text is the question,
    // which the card shows itself, with who asked and when.
    final isPoll = m.type == MessageType.poll && !deleted;
    // An event card (CHAT-11, SCHED-3), posted by the server.
    final isEvent =
        m.type == MessageType.event && m.eventId != null && !deleted;
    final card = isPoll || isEvent;

    // Inside the bubble, at the top (CHAT-1): the name (Fredoka) with the
    // players and time beside it in small muted type on a group's first
    // message (mine shows only the time), and "edited" or "Pinned" on any
    // message that is.
    final meta = [
      if (widget.startsGroup) ?time,
      if (widget.startsGroup) headerMarks else marks,
    ].where((p) => p.isNotEmpty).join(' · ');
    final named = widget.startsGroup && !mine && !direct;
    final metaStyle = ChatText.face(theme.textTheme.bodySmall).copyWith(
      fontSize: 13,
      height: 1.2,
      fontWeight: mine ? FontWeight.w800 : FontWeight.w700,
      color: muted,
      letterSpacing: 0,
    );
    final innerHeader = card || (!named && meta.isEmpty)
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Text.rich(
              textWidthBasis: TextWidthBasis.longestLine,
              TextSpan(
                children: [
                  if (named) ..._nameSpans(m, foreground, muted),
                  if (meta.isNotEmpty) TextSpan(text: named ? '  $meta' : meta),
                ],
              ),
              style: mine ? metaStyle.copyWith(fontSize: 12) : metaStyle,
            ),
          );

    // Photos sit inside the bubble, above the caption (CHAT-3).
    final photos = deleted || m.attachments.isEmpty
        ? null
        : PhotoGrid(
            count: m.attachments.length,
            single: m.attachments.first.aspectRatio,
            tile: (i) {
              void open() =>
                  unawaited(PhotoViewer.open(context, m.attachments, i));
              // "Photo from Alex", a button that opens the viewer.
              return Semantics(
                button: true,
                label: l10n.photoFrom(m.authorName),
                excludeSemantics: true,
                onTap: open,
                child: GestureDetector(
                  onTap: open,
                  child: StoredPhoto(
                    attachment: m.attachments[i],
                    decodeWidth: PhotoGrid.maxWidth,
                  ),
                ),
              );
            },
          );
    // Around photos the bubble is a thin frame, and what's above and below
    // them is inset to line up with a text bubble's.
    const photoInset = Space.xs + 2;
    final side = mine ? 14.0 : 13.0;
    Widget inset(Widget child) => photos == null
        ? child
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: side - photoInset),
            child: child,
          );
    final body = <Widget>[
      if (innerHeader != null) inset(innerHeader),
      if (deleted)
        Text(
          switch (m.deletedReason) {
            'admin' => l10n.messageRemovedByAdmin,
            // Its last photo was deleted in Media (STORE-5).
            'media' => l10n.photoRemovedByAdmin,
            _ => l10n.messageDeleted,
          },
          style: ChatText.of(theme.textTheme.bodyLarge).copyWith(
            fontStyle: FontStyle.italic,
            fontSize: 15,
            color: c.textMutedOnPage,
          ),
        )
      else ...[
        if (announcement)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.announcement, size: 18, color: foreground),
                const SizedBox(width: Space.xs),
                Text(
                  l10n.chatAnnouncementLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        if (photos != null)
          Padding(
            padding: EdgeInsets.only(
              top: innerHeader == null ? 0 : Space.xs,
              bottom: hasText || quote != null ? Space.xs + 2 : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: photos,
            ),
          ),
        if (quote != null) inset(quote),
        if (hasText)
          inset(
            LinkifiedText(
              m.text,
              phones: !web,
              // The bubble hugs its longest line, as iMessage's do.
              textWidthBasis: TextWidthBasis.longestLine,
              style: ChatText.of(
                theme.textTheme.bodyLarge?.copyWith(color: foreground),
                mine: mine,
              ),
              linkColor: foreground,
              highlights: highlights,
              onOpen: (uri) =>
                  unawaited(ref.read(linkOpenerProvider).open(uri)),
            ),
          ),
      ],
    ];
    // Each message is its own bubble, fitted to its text and no wider than
    // the design's (bubbleMaxWidth), rounded with a small tail corner: at
    // the top left of the first of others' messages, at the bottom right of
    // the last of mine (§3.14). A one-line bubble is still 48 tall, a full
    // tap target (SPEC §7.6), with its text centered.
    final besideAvatar = !mine && !direct;
    final radius = bubbleRadius(
      mine: mine,
      tail: mine ? widget.endsGroup : widget.startsGroup,
    );
    final padding = photos != null
        ? EdgeInsets.fromLTRB(
            photoInset,
            innerHeader == null ? photoInset : 7,
            photoInset,
            hasText ? 9 : photoInset,
          )
        : mine
        ? const EdgeInsets.fromLTRB(14, 9, 14, 10)
        : innerHeader != null
        ? const EdgeInsets.fromLTRB(13, 7, 13, 9)
        : const EdgeInsets.fromLTRB(13, 9, 13, 10);
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: bubbleMaxWidth(context, besideAvatar: besideAvatar),
        minHeight: kMinInteractiveDimension,
      ),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: body,
          ),
        ),
      ),
    );
    final textBubble = DecoratedBox(
      decoration: BoxDecoration(
        color: deleted ? null : background,
        border: deleted
            ? Border.all(color: c.divider, width: 2)
            // My bubble on a page of its own hue (lemon on a Yellow team's
            // page, blue on a Light blue team's) keeps an ink edge.
            : mine && ColorMath.contrast(background, c.page) < 2
            ? Border.all(color: c.ink, width: 2)
            : !mine && !announcement && c.surfaceBorderWidth > 0
            ? Border.all(color: c.surfaceBorder, width: c.surfaceBorderWidth)
            : null,
        borderRadius: radius,
      ),
      // Others' bubbles are white cards in Candy: their text and quotes
      // take the card's colors.
      child: !mine && !announcement && !deleted
          ? GumdropSurface(child: content)
          : content,
    );
    final bubble = card
        ? isPoll
              ? PollCard(
                  pollId: PollId(m.pollId ?? m.id),
                  groupId: m.groupId,
                  asked: mine
                      ? l10n.pollYouAsked
                      : l10n.pollPersonAsked(shortNameOf(m.authorName)),
                  time: [
                    ?time,
                    if (headerMarks.isNotEmpty) headerMarks,
                  ].join(' · '),
                )
              : Column(
                  crossAxisAlignment: mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EventCard(
                      eventId: EventId(m.eventId!),
                      groupId: m.groupId,
                      seriesId: m.seriesId,
                      text: m.text,
                      reminder: m.reminder,
                    ),
                  ],
                )
        : textBubble;

    final openAuthor = mine ? null : _authorTap(m);
    final pageMeta = theme.textTheme.bodySmall?.copyWith(
      color: c.textMutedOnPage,
      fontWeight: FontWeight.w800,
    );
    // Event cards keep the name and time above them, on the page. A poll
    // card says who asked inside it.
    final header = !isEvent
        ? null
        : widget.startsGroup && !mine
        ? Padding(
            padding: const EdgeInsets.only(left: 2, bottom: Space.xs),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: nameWithPlayersOf(
                      m.authorName,
                      m.authorPlayerSummary,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: c.textOnPage,
                    ),
                  ),
                  if (time != null) TextSpan(text: '  $time'),
                  if (headerMarks.isNotEmpty) TextSpan(text: ' · $headerMarks'),
                ],
              ),
              style: pageMeta,
            ),
          )
        : widget.startsGroup && time != null
        ? Padding(
            padding: const EdgeInsets.only(right: 2, bottom: Space.xs),
            child: Text(
              headerMarks.isNotEmpty ? '$time · $headerMarks' : time,
              style: pageMeta,
            ),
          )
        : marks.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: mine ? 0 : 2,
              right: mine ? 2 : 0,
              bottom: 2,
            ),
            child: Text(marks, style: pageMeta),
          )
        : null;

    final column = Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ?header,
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () => setState(() => _showTime = !_showTime),
            // Swipe right to reply (CHAT-13, phones).
            onHorizontalDragUpdate: widget.onReply == null || web
                ? null
                : (d) => setState(
                    () => _swipe = (_swipe + d.delta.dx).clamp(0, 96),
                  ),
            onHorizontalDragEnd: widget.onReply == null || web
                ? null
                : (_) {
                    if (_swipe >= _swipeToReply) {
                      Haptics.selection();
                      widget.onReply!();
                    }
                    setState(() => _swipe = 0);
                  },
            // The message menu (CHAT-7): long-press on phones, right-click
            // on the web. Double-tap loves it (CHAT-6).
            onLongPress: deleted
                ? null
                : () {
                    Haptics.medium();
                    unawaited(_openMenu());
                  },
            onSecondaryTap: deleted ? null : () => unawaited(_openMenu()),
            // Not on polls: waiting for a second tap would hold up voting.
            onDoubleTap:
                deleted ||
                    web ||
                    isPoll ||
                    isEvent ||
                    ref.watch(viewingAsSuperAdminProvider(m.groupId))
                ? null
                : () {
                    Haptics.light();
                    fireAndForget(_react(Reaction.love));
                  },
            // Full keyboard navigation (SPEC §7.6): Tab reaches each
            // message, and Enter, Space, the menu key, or Shift+F10 opens
            // its menu, as long-press and right-click do.
            child: FocusableActionDetector(
              enabled: !deleted,
              onShowFocusHighlight: (on) => setState(() => _focused = on),
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.contextMenu):
                    ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.f10, shift: true):
                    ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) => unawaited(_openMenu()),
                ),
              },
              child: Transform.translate(
                offset: Offset(_swipe, 0),
                child: Row(
                  mainAxisSize: isPoll ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (mine && _hovering && !deleted) _hoverButton(),
                    Flexible(
                      fit: isPoll ? FlexFit.tight : FlexFit.loose,
                      child: DecoratedBox(
                        // The visible focus ring (SPEC §7.6).
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          border: _focused
                              ? Border.all(color: c.textOnPage, width: 2)
                              : null,
                          borderRadius: card
                              ? BorderRadius.circular(Corners.panel)
                              : radius,
                        ),
                        child: bubble,
                      ),
                    ),
                    if (!mine && _hovering && !deleted) _hoverButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (m.reactions.isNotEmpty && !deleted)
          ReactionChips(
            message: m,
            me: ref.watch(authUserProvider).value?.uid,
            alignEnd: mine,
            onShowWho: () => unawaited(_showWho()),
            // As the picker: not while viewing as a super admin.
            onReact: ref.watch(viewingAsSuperAdminProvider(m.groupId))
                ? null
                : (r) {
                    Haptics.light();
                    fireAndForget(_react(r));
                  },
          ),
        // Delivery state (CHAT-4): sending until the server has it, then
        // "Sent" with a mint check under my newest message, and with the
        // time on the others.
        if (m.pending || widget.showSent)
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 2),
            child: ReadReceipt(
              label: m.pending ? l10n.messageSending : l10n.messageSent,
              sent: !m.pending,
            ),
          )
        else if ((_showTime || _hovering) &&
            time != null &&
            (mine || !widget.startsGroup))
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: mine ? 0 : 2,
              right: mine ? 2 : 0,
            ),
            child: Text(
              !mine
                  ? time
                  : widget.startsGroup
                  ? l10n.messageSent
                  : '$time · ${l10n.messageSent}',
              style: pageMeta?.copyWith(fontSize: 12),
            ),
          ),
      ],
    );

    // Others' messages get their photo beside the first bubble of a group,
    // in a slot as wide as a tap target, since it opens their page. A poll
    // card takes the whole width and names who asked.
    final avatarSlot = SizedBox(
      width: kMinInteractiveDimension,
      // Level with the bubble's top, where the name is; a card has its
      // name above it.
      child: widget.startsGroup
          ? Padding(
              padding: EdgeInsets.only(top: isEvent ? 20 : 0),
              child: _AuthorAvatar(message: m, onTap: openAuthor),
            )
          : null,
    );

    final row = Padding(
      // The design's spacing (§3.14): 16 from the screen's edges (the
      // photo's tap target reaches 4 past it), 12 between people, a little
      // less between one person's messages. Others' messages on the left,
      // mine on the right.
      padding: EdgeInsets.fromLTRB(
        besideAvatar && !isPoll ? Space.md : Space.lg,
        widget.startsGroup ? Space.xs + 2 : 2,
        Space.lg,
        widget.endsGroup ? Space.xs + 2 : 2,
      ),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (besideAvatar && !isPoll) avatarSlot,
          Flexible(child: column),
        ],
      ),
    );
    return AnimatedContainer(
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      color: widget.highlighted
          ? c.you.face.withValues(alpha: 0.28)
          : Colors.transparent,
      child: row,
    );
  }

  /// The sender's name in the label font, and their players beside it in small
  /// muted type ("Claire D." then "· Luke #7"), as the design has it.
  List<InlineSpan> _nameSpans(Message m, Color name, Color muted) {
    final full = nameWithPlayersOf(m.authorName, m.authorPlayerSummary);
    final short = shortNameOf(m.authorName);
    final split =
        full != m.authorName && full.startsWith(short) && full != short;
    final nameStyle = GumdropStyle.of(context).label(
      TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
        color: name,
      ),
    );
    return [
      TextSpan(text: split ? short : full, style: nameStyle),
      if (split) TextSpan(text: ' ${full.substring(short.length).trim()}'),
    ];
  }
}

/// The text color on a bubble of [color]: ink, or white on a dark team
/// color, whichever reads better (CHAT-18).
Color bubbleTextOn(GumdropColors c, Color color) =>
    ColorMath.contrast(c.ink, color) >= ColorMath.contrast(Colors.white, color)
    ? c.ink
    : Colors.white;

/// A bubble's corners (§3.14): 20, with the [tail] corner 6, at the top
/// left of others' messages and the bottom right of mine.
BorderRadius bubbleRadius({required bool mine, bool tail = true}) {
  const round = Radius.circular(Corners.bubble);
  const point = Radius.circular(Corners.bubbleTail);
  return BorderRadius.only(
    topLeft: !mine && tail ? point : round,
    topRight: round,
    bottomLeft: round,
    bottomRight: mine && tail ? point : round,
  );
}

/// The widest a message bubble grows (CHAT-1): others' nearly fill the
/// column beside their photo, as the design has them, still leaving the
/// other side a little free, and mine (or others' in a direct conversation,
/// which have no photo) about three quarters of the room, so they sit to
/// the right; no wider than a comfortable line on big screens.
/// [besideAvatar] leaves the photo's slot out of the room.
double bubbleMaxWidth(BuildContext context, {bool besideAvatar = false}) {
  final room =
      MediaQuery.sizeOf(context).width -
      2 * Space.lg -
      (besideAvatar ? kMinInteractiveDimension - Space.xs : 0);
  return math.max(
    kMinInteractiveDimension,
    math.min(520, room * (besideAvatar ? 0.92 : 0.78)),
  );
}

/// "Sent" under my newest message (CHAT-4): small heavy type on the page
/// with a mint check disc (§3.14), or "Sending…" without it.
class ReadReceipt extends StatelessWidget {
  const new({
    required this.label,
    this.sent = true,
    this.failed = false,
    super.key,
  });

  final String label;
  final bool sent;

  /// Not sent: a cherry disc with an X in place of the check.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sent || failed) ...[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: failed ? c.cherry.face : c.mint.face,
              shape: BoxShape.circle,
            ),
            child: Icon(
              failed ? AppIcons.close : AppIcons.check,
              size: 12,
              weight: 800,
              color: c.ink,
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: c.textMutedOnPage,
          ),
        ),
      ],
    );
  }
}

/// The author's photo beside their messages; tapping it opens their page
/// (TEAM-15) when [onTap] is given. The 36 px photo sits 4 in from the top
/// left of a full 48 × 48 tap target (SPEC §7.6), 8 from the bubble.
class _AuthorAvatar extends ConsumerWidget {
  const new({required this.message, this.onTap});

  final Message message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = message.authorPhotoPath;
    final url = path == null
        ? null
        : ref.watch(teamPhotoUrlProvider(path)).value;
    final avatar = Padding(
      padding: const EdgeInsetsDirectional.only(start: Space.xs),
      child: Avatar(
        name: message.authorName,
        colorKey: message.authorId,
        imageUrl: url,
        size: 36,
      ),
    );
    final tap = onTap;
    if (tap == null) return Align(alignment: Alignment.topLeft, child: avatar);
    // Its own node, so a screen reader finds it apart from the message.
    return Semantics(
      container: true,
      button: true,
      label: AppLocalizations.of(context).openProfile(message.authorName),
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: SizedBox.square(
            dimension: kMinInteractiveDimension,
            child: Align(alignment: Alignment.topLeft, child: avatar),
          ),
        ),
      ),
    );
  }
}

/// A photo message still uploading (CHAT-3, CHAT-4): the photos with a
/// progress bar, or Retry and Delete if the upload failed.
class OutgoingPhotosTile extends StatelessWidget {
  const new({
    required this.item,
    required this.onRetry,
    required this.onDiscard,
    this.online = true,
    super.key,
  });

  final OutgoingPhotos item;

  /// False while the chat is offline: the photos wait for the connection.
  final bool online;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final waiting = !item.failed && (item.waiting || !online);
    // Progress shows in the bubble itself (CHAT-3): a ring over the photos.
    final grid = PhotoGrid(
      count: item.photos.length,
      tile: (i) => LocalPhoto(bytes: item.photos[i].bytes),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (item.failed)
            Opacity(opacity: 0.5, child: grid)
          else
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: 0.7, child: grid),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: c.ink.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: waiting
                        ? const Icon(AppIcons.cloudOff, color: Colors.white)
                        : CircularProgressIndicator(
                            value: item.progress == 0 ? null : item.progress,
                            color: Colors.white,
                            strokeWidth: 3,
                            semanticsLabel: l10n.photosUploading,
                          ),
                  ),
                ),
              ],
            ),
          if (item.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.caption,
                style: ChatText.of(
                  Theme.of(context).textTheme.bodyLarge,
                  mine: true,
                ).copyWith(color: c.textOnPage),
              ),
            ),
          const SizedBox(height: Space.xs),
          if (item.failed || item.waiting)
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Offline they wait for the connection and go by themselves;
                // Retry tries now, Delete gives up.
                ReadReceipt(
                  label: item.failed ? l10n.photosFailed : l10n.photosWaiting,
                  sent: false,
                  failed: item.failed,
                ),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(AppIcons.retry),
                  label: Text(l10n.retry),
                ),
                TextButton(onPressed: onDiscard, child: Text(l10n.delete)),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: ReadReceipt(
                label: waiting ? l10n.photosWaiting : l10n.messageSending,
                sent: false,
              ),
            ),
        ],
      ),
    );
  }
}

/// A text message not on the server yet (CHAT-4): "Sending…" while it waits
/// its turn (offline, until the connection returns), or "Not sent" with
/// Retry and Delete if the server refused it.
class OutgoingTextTile extends StatelessWidget {
  const new({
    required this.item,
    required this.onRetry,
    required this.onDiscard,
    this.bubbleColor,
    super.key,
  });

  final OutgoingText item;

  /// My bubbles' color from the team's chat look (CHAT-18), as on the
  /// messages already sent; null uses the brand color.
  final Color? bubbleColor;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    final custom = bubbleColor;
    final background = custom ?? c.you.face;
    final foreground = custom == null ? c.ink : bubbleTextOn(c, custom);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 2, Space.lg, Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: item.failed ? 0.6 : 0.8,
            // As a sent bubble of mine (MessageTile): fitted to its text.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: bubbleRadius(mine: true),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: bubbleMaxWidth(context),
                  minHeight: kMinInteractiveDimension,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      item.text,
                      textWidthBasis: TextWidthBasis.longestLine,
                      style: ChatText.of(
                        theme.textTheme.bodyLarge?.copyWith(color: foreground),
                        mine: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (item.failed)
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ReadReceipt(
                  label: l10n.messageNotSent,
                  sent: false,
                  failed: true,
                ),
                TextButton(onPressed: onRetry, child: Text(l10n.retry)),
                TextButton(onPressed: onDiscard, child: Text(l10n.delete)),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 2),
              child: ReadReceipt(label: l10n.messageSending, sent: false),
            ),
        ],
      ),
    );
  }
}

/// The app an imported message came from, by name (IMPORT-9).
String _appName(String source) => switch (source) {
  'groupme' => 'GroupMe',
  _ => source,
};
