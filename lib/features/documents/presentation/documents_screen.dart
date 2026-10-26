import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_rules.dart';
import 'package:battleplan/features/documents/presentation/add_document.dart';
import 'package:battleplan/features/documents/presentation/document_actions.dart';
import 'package:battleplan/features/documents/presentation/document_row.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The Documents tab (DOC-1): Photos, every photo from the chat (DOC-7),
/// then the documents, pinned first, then everything else by Recent or
/// Name, filtered by typing; + for people allowed to add (DOC-2, DOC-3,
/// TEAM-5). Archived teams are read-only (TEAM-9).
class DocumentsScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  late final _filter = TextEditingController(
    text: ref.read(documentsViewOptionsProvider).filter,
  );

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  /// Set when loading the rest for a filter failed, so it isn't retried
  /// on every rebuild; typing again tries again.
  bool _searchFailed = false;

  Future<void> _loadMore(DocumentSort sort) async {
    try {
      await ref
          .read(teamDocumentsProvider(widget.groupId, sort).notifier)
          .loadMore();
    } on Object {
      if (mounted) {
        setState(() => _searchFailed = true);
        showAppSnackBar(context, AppLocalizations.of(context).loadError);
      }
    }
  }

  /// A filter looks through every document, not just the pages loaded so
  /// far (DOC-1): while one is typed, the rest load page by page.
  void _searchRest(DocumentsView view, DocumentListState state) {
    if (view.filter.trim().isEmpty || _searchFailed) return;
    if (state.reachedEnd || state.loading || state.loadingMore) return;
    if (state.failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadMore(view.sort));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupId = widget.groupId;
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final view = ref.watch(documentsViewOptionsProvider);
    final state = ref.watch(teamDocumentsProvider(groupId, view.sort));
    final canAdd =
        group != null &&
        canAddDocuments(
          group,
          me,
          superAdmin: ref.watch(authUserProvider).value?.isSuperAdmin ?? false,
        );
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    _searchRest(view, state);

    final Widget body;
    if (group == null || (state.loading && state.documents.isEmpty)) {
      body = state.failed
          ? Center(child: Text(l10n.loadError))
          : const SkeletonList();
    } else if (state.failed && state.documents.isEmpty) {
      body = Center(child: Text(l10n.loadError));
    } else if (state.documents.isEmpty && state.reachedEnd) {
      body = EmptyState(
        icon: AppIcons.documents,
        message: l10n.documentsPlaceholder,
      );
    } else {
      final shown = arrangeDocuments(
        state.documents,
        sort: view.sort,
        filter: view.filter,
      );
      // While a filter loads the rest, "No documents match" waits for it.
      final searching =
          view.filter.trim().isNotEmpty && !state.reachedEnd && !_searchFailed;
      final noMatches = shown.isEmpty && !searching;
      final more = !state.reachedEnd;
      // Rows are built as they scroll into view, so image thumbnails below
      // the fold don't all look up their files at once (SPEC §8.1).
      body = ListView.builder(
        padding: const EdgeInsets.only(top: 5, bottom: Space.xxxl * 2),
        itemCount: (noMatches ? 1 : shown.length) + (more ? 1 : 0),
        itemBuilder: (context, i) {
          if (noMatches && i == 0) {
            return Padding(
              padding: EdgeInsets.all(gutter),
              child: Text(
                l10n.documentsNoMatches(view.filter.trim()),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (i == (noMatches ? 1 : shown.length)) {
            return Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Center(
                child: state.loadingMore || searching
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => unawaited(_loadMore(view.sort)),
                        child: Text(l10n.documentsLoadMore),
                      ),
              ),
            );
          }
          final d = shown[i];
          return DocumentRow(
            key: ValueKey(d.id.value),
            doc: d,
            group: group,
            me: me,
            onTap: () => unawaited(openDocument(context, ref, d)),
          );
        },
      );
    }

    return Scaffold(
      floatingActionButton: canAdd
          ? FloatingActionButton(
              // The team's tabs stay built side by side, and Schedule has
              // one too: no shared hero tag between them.
              heroTag: null,
              tooltip: l10n.documentsAddTooltip,
              onPressed: () => unawaited(showAddDocument(context, ref, group)),
              child: const Icon(AppIcons.add),
            )
          : null,
      body: Column(
        children: [
          if (group?.isArchived ?? false)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, 0),
              child: Text(
                l10n.documentsReadOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xs),
            child: _FilterBar(
              filter: TextField(
                controller: _filter,
                decoration: InputDecoration(
                  hintText: l10n.documentsFilterHint,
                  prefixIcon: const Icon(AppIcons.search),
                  isDense: true,
                  suffixIcon: view.filter.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.cancel,
                          icon: const Icon(AppIcons.close),
                          onPressed: () {
                            _filter.clear();
                            ref
                                .read(documentsViewOptionsProvider.notifier)
                                .setFilter('');
                          },
                        ),
                ),
                onChanged: (v) {
                  _searchFailed = false;
                  ref.read(documentsViewOptionsProvider.notifier).setFilter(v);
                },
              ),
              sort: SegmentedButton<DocumentSort>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DocumentSort.recent,
                    label: Text(l10n.documentsSortRecent),
                  ),
                  ButtonSegment(
                    value: DocumentSort.name,
                    label: Text(l10n.documentsSortName),
                  ),
                ],
                selected: {view.sort},
                onSelectionChanged: (s) => ref
                    .read(documentsViewOptionsProvider.notifier)
                    .setSort(s.first),
              ),
            ),
          ),
          // Hidden while a filter looks through the documents.
          if (view.filter.trim().isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, Space.xs, gutter, Space.xs),
              child: SettingsCard(
                children: [
                  SettingsRow(
                    icon: AppIcons.photo,
                    title: l10n.photosTitle,
                    subtitle: l10n.photosSubtitle,
                    onTap: () => unawaited(
                      context.push('/g/${groupId.value}/documents/photos'),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The filter box with the sort beside it, or under it when large text
/// wouldn't fit them side by side (SPEC §7.6).
class _FilterBar extends StatelessWidget {
  const new({required this.filter, required this.sort});

  final Widget filter;
  final Widget sort;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filter,
          const SizedBox(height: Space.sm),
          sort,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: filter),
        const SizedBox(width: Space.sm),
        sort,
      ],
    );
  }
}
