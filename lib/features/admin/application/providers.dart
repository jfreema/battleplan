import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/domain/admin_repository.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.freezed.dart';
part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Platform settings, live while someone is signed in (ADMIN-7). Signed
/// out, the defaults: `config/app` needs a sign-in to read.
@Riverpod(keepAlive: true)
Stream<AppConfig> appConfig(Ref ref) {
  final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const AppConfig());
  return ref.watch(adminRepositoryProvider).watchConfig();
}

/// Announcements dismissed (or ended) this session (ADMIN-7). Each one is
/// its own, so a new or edited banner shows again. A new sign-in starts
/// over.
@Riverpod(keepAlive: true)
class DismissedAnnouncements extends _$DismissedAnnouncements {
  @override
  Set<Announcement> build() {
    ref.watch(authUserProvider.select((a) => a.value?.uid));
    return const {};
  }

  void dismiss(Announcement banner) => state = {...state, banner};
}

/// The banner to show at the top of the app right now, if any (ADMIN-7):
/// set, not expired, and not dismissed this session. It goes away on its
/// own when it expires.
@riverpod
Announcement? liveAnnouncement(Ref ref) {
  final banner = ref.watch(appConfigProvider).value?.announcementBanner;
  final now = DateTime.now();
  if (banner == null || !banner.isLiveAt(now)) return null;
  if (ref.watch(dismissedAnnouncementsProvider).contains(banner)) return null;
  // When it ends, it's put away like a dismissed one. Browsers fire
  // longer timers at once, so a banner that runs for weeks is looked at
  // again daily instead.
  final left = banner.expiresAt.difference(now);
  const day = Duration(days: 1);
  final timer = left > day
      ? Timer(day, ref.invalidateSelf)
      : Timer(
          left,
          () =>
              ref.read(dismissedAnnouncementsProvider.notifier).dismiss(banner),
        );
  ref.onDispose(timer.cancel);
  return banner;
}

/// Records a super admin opening a team's tabs (ADMIN-3), once while the
/// "Viewing as super admin" banner is up.
@riverpod
Future<void> adminGroupOpened(Ref ref, GroupId groupId) =>
    ref.watch(adminRepositoryProvider).openGroup(groupId);

/// ADMIN-1 totals, read when the dashboard opens.
@riverpod
Future<AdminTotals> adminTotals(Ref ref) =>
    ref.watch(adminRepositoryProvider).totals();

/// ADMIN-3: one team's people, players, invites, and counts.
@riverpod
Future<AdminTeamDetail> adminTeam(Ref ref, GroupId groupId) =>
    ref.watch(adminRepositoryProvider).team(groupId);

/// ADMIN-4: one person's details.
@riverpod
Future<AdminUserDetail> adminUser(Ref ref, UserId uid) =>
    ref.watch(adminRepositoryProvider).user(uid);

/// A person's name for the audit log, from their profile (super admins
/// may read any). Their uid until it loads, or if they're gone.
@riverpod
Stream<String?> adminPersonName(Ref ref, String uid) => ref
    .watch(userRepositoryProvider)
    .watchProfile(uid)
    .map((p) => p?.displayName);

/// A paged admin list: the rows loaded so far, oldest page first, and
/// where the next page starts (ARCH §5.3).
@freezed
abstract class AdminList<T> with _$AdminList<T> {
  const factory({
    required List<T> items,
    PageCursor? next,
    @Default(false) bool loadingMore,
  }) = _AdminList<T>;

  const new _();

  /// Nothing more to load.
  bool get reachedEnd => next == null;

  /// This list with [page] after it.
  AdminList<T> append(AdminPage<T> page) =>
      AdminList(items: [...items, ...page.items], next: page.next);
}

/// The first page of a list.
Future<AdminList<T>> _first<T>(Future<AdminPage<T>> page) async {
  final p = await page;
  return AdminList(items: p.items, next: p.next);
}

/// ADMIN-2: teams matching [query], 50 at a time.
@riverpod
class AdminTeams extends _$AdminTeams {
  @override
  Future<AdminList<AdminTeamRow>> build(AdminTeamQuery query) =>
      _first(ref.watch(adminRepositoryProvider).listTeams(query));

  /// Appends the next page. A failure leaves the list as it was and is
  /// rethrown for the screen to report.
  Future<void> loadMore() async {
    final list = state.value;
    if (list == null || list.reachedEnd || list.loadingMore) return;
    state = AsyncData(list.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .listTeams(query, after: list.next);
      if (ref.mounted) state = AsyncData(list.append(page));
    } on Object {
      if (ref.mounted) state = AsyncData(list);
      rethrow;
    }
  }
}

/// ADMIN-4: people matching [query], 50 at a time.
@riverpod
class AdminUsers extends _$AdminUsers {
  @override
  Future<AdminList<AdminUserRow>> build(AdminUserQuery query) =>
      _first(ref.watch(adminRepositoryProvider).listUsers(query));

  /// Appends the next page, as [AdminTeams.loadMore] does.
  Future<void> loadMore() async {
    final list = state.value;
    if (list == null || list.reachedEnd || list.loadingMore) return;
    state = AsyncData(list.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .listUsers(query, after: list.next);
      if (ref.mounted) state = AsyncData(list.append(page));
    } on Object {
      if (ref.mounted) state = AsyncData(list);
      rethrow;
    }
  }
}

/// ADMIN-5: reports in [status] from every team, newest first.
@riverpod
class AdminReports extends _$AdminReports {
  @override
  Future<AdminList<AdminReport>> build(ReportStatus status) =>
      _first(ref.watch(adminRepositoryProvider).listReports(status));

  /// Appends the next page, as [AdminTeams.loadMore] does.
  Future<void> loadMore() async {
    final list = state.value;
    if (list == null || list.reachedEnd || list.loadingMore) return;
    state = AsyncData(list.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .listReports(status, after: list.next);
      if (ref.mounted) state = AsyncData(list.append(page));
    } on Object {
      if (ref.mounted) state = AsyncData(list);
      rethrow;
    }
  }
}

/// ADMIN-6: the audit log matching [filter], newest first.
@riverpod
class AdminAudit extends _$AdminAudit {
  @override
  Future<AdminList<AuditEntry>> build(AuditFilter filter) =>
      _first(ref.watch(adminRepositoryProvider).auditLog(filter));

  /// Appends the next page, as [AdminTeams.loadMore] does.
  Future<void> loadMore() async {
    final list = state.value;
    if (list == null || list.reachedEnd || list.loadingMore) return;
    state = AsyncData(list.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .auditLog(filter, after: list.next);
      if (ref.mounted) state = AsyncData(list.append(page));
    } on Object {
      if (ref.mounted) state = AsyncData(list);
      rethrow;
    }
  }
}
