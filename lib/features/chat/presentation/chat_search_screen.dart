import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/chat_search.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/search_words.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart'
    show dayLabel;
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Opens search in a chat (CHAT-20): a team's, or with [direct] a direct
/// conversation's.
void openChatSearch(
  BuildContext context,
  GroupId groupId, {
  required bool direct,
}) => unawaited(
  context.push(
    direct
        ? '/messages/${groupId.value}/search'
        : '/g/${groupId.value}/chat/search',
  ),
);

/// Search in a team's chat (CHAT-20), at the end of the Chat tab's pinned
/// row: a 24 px search icon in a 48 × 48 box.
class ChatSearchButton extends StatelessWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).searchChat,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: EdgeInsets.zero,
    iconSize: 24,
    color: GumdropColors.of(context).textOnPage,
    icon: const Icon(AppIcons.search),
    onPressed: () => openChatSearch(context, groupId, direct: false),
  );
}

/// Ctrl+F and ⌘+F, which open search in a chat on web and desktop (SPEC
/// §4.2), in place of the browser's find, which can't read the app's text.
Map<ShortcutActivator, VoidCallback> chatSearchShortcuts(VoidCallback open) => {
  const SingleActivator(LogicalKeyboardKey.keyF, control: true): open,
  const SingleActivator(LogicalKeyboardKey.keyF, meta: true): open,
};

/// Search in a chat (CHAT-20): a team's, or a direct conversation's. Enter
/// searches; results come newest first, each with who sent it and when, the
/// words found in bold, and a tap opens the chat at it, highlighted. More
/// load near the end of the list. The last search is still there when
/// coming back to it.
class ChatSearchScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends ConsumerState<ChatSearchScreen> {
  late final TextEditingController _field = TextEditingController(
    text: ref.read(chatSearchProvider(widget.groupId)).query,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  ChatSearch get _search =>
      ref.read(chatSearchProvider(widget.groupId).notifier);

  void _clear() {
    _field.clear();
    _search.clear();
    setState(() {});
  }

  /// The chat, scrolled to [m] (CHAT-20). Its time lets one from long ago
  /// open in a page.
  void _open(Message m, {required bool direct}) {
    final at = m.createdAt?.millisecondsSinceEpoch;
    final path = direct
        ? '/messages/${widget.groupId.value}/m/${m.id}'
        : '/g/${widget.groupId.value}/chat/m/${m.id}';
    context.go(at == null ? path : '$path?at=$at');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final direct = group?.isDirect ?? false;
    final me = ref.watch(authUserProvider).value?.uid;
    final other = direct ? group?.people[group.otherThan(me)]?.name : null;
    final search = ref.watch(chatSearchProvider(widget.groupId));
    final width = MediaQuery.sizeOf(context).width;

    final field = Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter(width),
        Space.sm,
        Space.gutter(width),
        Space.sm,
      ),
      child: TextField(
        controller: _field,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: direct
              ? l10n.directSearchHint(other ?? '')
              : l10n.chatSearchHint(group?.name ?? ''),
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: _field.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.clearSearch,
                  icon: const Icon(AppIcons.close),
                  onPressed: _clear,
                ),
        ),
        // The clear button comes and goes with the text.
        onChanged: (_) => setState(() {}),
        onSubmitted: (query) => unawaited(_search.search(query)),
      ),
    );

    final Widget results;
    if (!search.searched && search.query.isEmpty) {
      results = EmptyState(
        icon: AppIcons.search,
        message: l10n.chatSearchPrompt,
      );
    } else if (!search.searched) {
      results = EmptyState(
        icon: AppIcons.search,
        message: l10n.chatSearchTooShort,
      );
    } else if (search.loading) {
      results = const Center(child: CircularProgressIndicator());
    } else if (search.results.isEmpty && search.failed) {
      results = EmptyState(
        icon: AppIcons.warning,
        message: l10n.chatSearchFailed,
        actionLabel: l10n.retry,
        onAction: () => unawaited(_search.search(search.query)),
      );
    } else if (search.results.isEmpty && search.reachedEnd) {
      results = EmptyState(
        icon: AppIcons.search,
        message: l10n.chatSearchNone(search.query),
      );
    } else {
      final more = !search.reachedEnd;
      results = ListView.builder(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        itemCount: search.results.length + (more ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= search.results.length - 3 && more && !search.failed) {
            // After this frame: the list asks while it builds.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_search.loadMore());
            });
          }
          if (i == search.results.length) {
            return Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Center(
                child: search.failed
                    ? IconButton(
                        tooltip: l10n.retry,
                        icon: const Icon(AppIcons.retry),
                        onPressed: () => unawaited(_search.loadMore()),
                      )
                    : const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
              ),
            );
          }
          final m = search.results[i];
          return _ResultTile(
            message: m,
            terms: search.terms,
            onTap: () => _open(m, direct: direct),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(direct ? l10n.searchConversation : l10n.searchChat),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.contentMax),
          child: Column(
            children: [
              field,
              // Offline, the search ran on what this device has.
              if (search.fromCache && search.results.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Space.gutter(width),
                    0,
                    Space.gutter(width),
                    Space.sm,
                  ),
                  child: Text(
                    l10n.chatSearchOffline,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Expanded(child: results),
            ],
          ),
        ),
      ),
    );
  }
}

/// One message found (CHAT-20): who sent it and when, and its text with the
/// words found in bold, from a little before the first of them.
class _ResultTile extends ConsumerWidget {
  const new({required this.message, required this.terms, required this.onTap});

  final Message message;
  final List<String> terms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final path = message.authorPhotoPath;
    final url = path == null
        ? null
        : ref.watch(teamPhotoUrlProvider(path)).value;
    final at = message.createdAt;
    final when = at == null
        ? ''
        : dayLabel(
            l10n,
            ViewerZone.wallClock(context, at),
            ViewerZone.wallClock(context, DateTime.now()),
          );
    final kind = switch (message.type) {
      MessageType.image => (AppIcons.photo, l10n.quotePhoto),
      MessageType.poll => (AppIcons.poll, l10n.quotePoll),
      MessageType.event => (AppIcons.event, l10n.quoteEvent),
      _ => null,
    };
    final bold = TextStyle(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );
    return Semantics(
      button: true,
      label: l10n.chatSearchResult(
        message.authorName,
        when,
        kind == null ? message.text : '${kind.$2}: ${message.text}',
      ),
      // Its own tap: leaving out the row's parts leaves out the InkWell's
      // tap too, and a screen reader couldn't open the result.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.gutter(MediaQuery.sizeOf(context).width),
            vertical: Space.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                name: message.authorName,
                colorKey: message.authorId,
                imageUrl: url,
                size: 36,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Side by side, or the day under the name when they
                    // don't fit (a long name, large text).
                    OverflowBar(
                      spacing: Space.sm,
                      alignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (kind != null) ...[
                              Icon(kind.$1, size: 16),
                              const SizedBox(width: Space.xs),
                            ],
                            Flexible(
                              child: Text(
                                when,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text.rich(
                      searchSnippet(message.text, terms, bold),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [text] with the words of a search, [terms], in [bold] (CHAT-20). When
/// the first is far in, it starts at a word a little before it, after "…",
/// so it shows in the lines a result has.
@visibleForTesting
TextSpan searchSnippet(String text, List<String> terms, TextStyle bold) {
  final found = [
    for (final m in _typedWord.allMatches(text))
      if (searchWords(m[0]!).any(terms.contains)) m,
  ];
  var from = 0;
  if (found.isNotEmpty && found.first.start > _lead * 2) {
    final space = text.lastIndexOf(RegExp(r'\s'), found.first.start - _lead);
    from = space < 0 ? 0 : space + 1;
  }
  final spans = <InlineSpan>[if (from > 0) const TextSpan(text: '…')];
  var at = from;
  for (final m in found) {
    if (m.start < from) continue;
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    spans.add(TextSpan(text: m[0], style: bold));
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(children: spans);
}

/// How much comes before the first word found, about.
const _lead = 30;

/// A word as typed: letters, digits, accents, and apostrophes, which
/// searchWords reads as one.
final _typedWord = RegExp(r"[\p{L}\p{N}\p{M}'\u2019\u02BC]+", unicode: true);
