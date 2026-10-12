// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

/// Overridden in app/providers.dart.

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  /// Overridden in app/providers.dart.
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'eb0973e2274b9560dac7ee2791260521326e2911';

/// Platform settings, live while someone is signed in (ADMIN-7). Signed
/// out, the defaults: `config/app` needs a sign-in to read.

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// Platform settings, live while someone is signed in (ADMIN-7). Signed
/// out, the defaults: `config/app` needs a sign-in to read.

final class AppConfigProvider
    extends
        $FunctionalProvider<AsyncValue<AppConfig>, AppConfig, Stream<AppConfig>>
    with $FutureModifier<AppConfig>, $StreamProvider<AppConfig> {
  /// Platform settings, live while someone is signed in (ADMIN-7). Signed
  /// out, the defaults: `config/app` needs a sign-in to read.
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $StreamProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppConfig> create(Ref ref) {
    return appConfig(ref);
  }
}

String _$appConfigHash() => r'd1b65630e089e29f4fb7029e8d1ea7dda8320dc8';

/// Announcements dismissed (or ended) this session (ADMIN-7). Each one is
/// its own, so a new or edited banner shows again. A new sign-in starts
/// over.

@ProviderFor(DismissedAnnouncements)
final dismissedAnnouncementsProvider = DismissedAnnouncementsProvider._();

/// Announcements dismissed (or ended) this session (ADMIN-7). Each one is
/// its own, so a new or edited banner shows again. A new sign-in starts
/// over.
final class DismissedAnnouncementsProvider
    extends $NotifierProvider<DismissedAnnouncements, Set<Announcement>> {
  /// Announcements dismissed (or ended) this session (ADMIN-7). Each one is
  /// its own, so a new or edited banner shows again. A new sign-in starts
  /// over.
  DismissedAnnouncementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedAnnouncementsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedAnnouncementsHash();

  @$internal
  @override
  DismissedAnnouncements create() => DismissedAnnouncements();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<Announcement> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<Announcement>>(value),
    );
  }
}

String _$dismissedAnnouncementsHash() =>
    r'36707dc0d6bb565851c773c3e2676eda13fa508c';

/// Announcements dismissed (or ended) this session (ADMIN-7). Each one is
/// its own, so a new or edited banner shows again. A new sign-in starts
/// over.

abstract class _$DismissedAnnouncements extends $Notifier<Set<Announcement>> {
  Set<Announcement> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<Announcement>, Set<Announcement>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<Announcement>, Set<Announcement>>,
              Set<Announcement>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The banner to show at the top of the app right now, if any (ADMIN-7):
/// set, not expired, and not dismissed this session. It goes away on its
/// own when it expires.

@ProviderFor(liveAnnouncement)
final liveAnnouncementProvider = LiveAnnouncementProvider._();

/// The banner to show at the top of the app right now, if any (ADMIN-7):
/// set, not expired, and not dismissed this session. It goes away on its
/// own when it expires.

final class LiveAnnouncementProvider
    extends $FunctionalProvider<Announcement?, Announcement?, Announcement?>
    with $Provider<Announcement?> {
  /// The banner to show at the top of the app right now, if any (ADMIN-7):
  /// set, not expired, and not dismissed this session. It goes away on its
  /// own when it expires.
  LiveAnnouncementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveAnnouncementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveAnnouncementHash();

  @$internal
  @override
  $ProviderElement<Announcement?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Announcement? create(Ref ref) {
    return liveAnnouncement(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Announcement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Announcement?>(value),
    );
  }
}

String _$liveAnnouncementHash() => r'1a35035b1cf3a038ce12bd8055fb8aadd98084ab';

/// Records a super admin opening a team's tabs (ADMIN-3), once while the
/// "Viewing as super admin" banner is up.

@ProviderFor(adminGroupOpened)
final adminGroupOpenedProvider = AdminGroupOpenedFamily._();

/// Records a super admin opening a team's tabs (ADMIN-3), once while the
/// "Viewing as super admin" banner is up.

final class AdminGroupOpenedProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Records a super admin opening a team's tabs (ADMIN-3), once while the
  /// "Viewing as super admin" banner is up.
  AdminGroupOpenedProvider._({
    required AdminGroupOpenedFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'adminGroupOpenedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminGroupOpenedHash();

  @override
  String toString() {
    return r'adminGroupOpenedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as GroupId;
    return adminGroupOpened(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminGroupOpenedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminGroupOpenedHash() => r'80ddea8ad505ef2d0b0118853085426e947b098d';

/// Records a super admin opening a team's tabs (ADMIN-3), once while the
/// "Viewing as super admin" banner is up.

final class AdminGroupOpenedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, GroupId> {
  AdminGroupOpenedFamily._()
    : super(
        retry: null,
        name: r'adminGroupOpenedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Records a super admin opening a team's tabs (ADMIN-3), once while the
  /// "Viewing as super admin" banner is up.

  AdminGroupOpenedProvider call(GroupId groupId) =>
      AdminGroupOpenedProvider._(argument: groupId, from: this);

  @override
  String toString() => r'adminGroupOpenedProvider';
}

/// ADMIN-1 totals, read when the dashboard opens.

@ProviderFor(adminTotals)
final adminTotalsProvider = AdminTotalsProvider._();

/// ADMIN-1 totals, read when the dashboard opens.

final class AdminTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminTotals>,
          AdminTotals,
          FutureOr<AdminTotals>
        >
    with $FutureModifier<AdminTotals>, $FutureProvider<AdminTotals> {
  /// ADMIN-1 totals, read when the dashboard opens.
  AdminTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminTotalsHash();

  @$internal
  @override
  $FutureProviderElement<AdminTotals> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminTotals> create(Ref ref) {
    return adminTotals(ref);
  }
}

String _$adminTotalsHash() => r'11a30a9ac06b67df0b4404ef2f951f5332e452b1';

/// ADMIN-3: one team's people, players, invites, and counts.

@ProviderFor(adminTeam)
final adminTeamProvider = AdminTeamFamily._();

/// ADMIN-3: one team's people, players, invites, and counts.

final class AdminTeamProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminTeamDetail>,
          AdminTeamDetail,
          FutureOr<AdminTeamDetail>
        >
    with $FutureModifier<AdminTeamDetail>, $FutureProvider<AdminTeamDetail> {
  /// ADMIN-3: one team's people, players, invites, and counts.
  AdminTeamProvider._({
    required AdminTeamFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'adminTeamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminTeamHash();

  @override
  String toString() {
    return r'adminTeamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AdminTeamDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminTeamDetail> create(Ref ref) {
    final argument = this.argument as GroupId;
    return adminTeam(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminTeamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminTeamHash() => r'a2e80f99a717851988e5095afcf38f1b6ca66dbf';

/// ADMIN-3: one team's people, players, invites, and counts.

final class AdminTeamFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AdminTeamDetail>, GroupId> {
  AdminTeamFamily._()
    : super(
        retry: null,
        name: r'adminTeamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-3: one team's people, players, invites, and counts.

  AdminTeamProvider call(GroupId groupId) =>
      AdminTeamProvider._(argument: groupId, from: this);

  @override
  String toString() => r'adminTeamProvider';
}

/// ADMIN-4: one person's details.

@ProviderFor(adminUser)
final adminUserProvider = AdminUserFamily._();

/// ADMIN-4: one person's details.

final class AdminUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminUserDetail>,
          AdminUserDetail,
          FutureOr<AdminUserDetail>
        >
    with $FutureModifier<AdminUserDetail>, $FutureProvider<AdminUserDetail> {
  /// ADMIN-4: one person's details.
  AdminUserProvider._({
    required AdminUserFamily super.from,
    required UserId super.argument,
  }) : super(
         retry: null,
         name: r'adminUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminUserHash();

  @override
  String toString() {
    return r'adminUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AdminUserDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminUserDetail> create(Ref ref) {
    final argument = this.argument as UserId;
    return adminUser(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminUserHash() => r'30d5f5beb64e6081b64cf3f39fa90a23fa9e4287';

/// ADMIN-4: one person's details.

final class AdminUserFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AdminUserDetail>, UserId> {
  AdminUserFamily._()
    : super(
        retry: null,
        name: r'adminUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-4: one person's details.

  AdminUserProvider call(UserId uid) =>
      AdminUserProvider._(argument: uid, from: this);

  @override
  String toString() => r'adminUserProvider';
}

/// A person's name for the audit log, from their profile (super admins
/// may read any). Their uid until it loads, or if they're gone.

@ProviderFor(adminPersonName)
final adminPersonNameProvider = AdminPersonNameFamily._();

/// A person's name for the audit log, from their profile (super admins
/// may read any). Their uid until it loads, or if they're gone.

final class AdminPersonNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// A person's name for the audit log, from their profile (super admins
  /// may read any). Their uid until it loads, or if they're gone.
  AdminPersonNameProvider._({
    required AdminPersonNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminPersonNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminPersonNameHash();

  @override
  String toString() {
    return r'adminPersonNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as String;
    return adminPersonName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminPersonNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminPersonNameHash() => r'00e5fe93682f9ac807cdf72bfb8b0fd8013e8356';

/// A person's name for the audit log, from their profile (super admins
/// may read any). Their uid until it loads, or if they're gone.

final class AdminPersonNameFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, String> {
  AdminPersonNameFamily._()
    : super(
        retry: null,
        name: r'adminPersonNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A person's name for the audit log, from their profile (super admins
  /// may read any). Their uid until it loads, or if they're gone.

  AdminPersonNameProvider call(String uid) =>
      AdminPersonNameProvider._(argument: uid, from: this);

  @override
  String toString() => r'adminPersonNameProvider';
}

/// ADMIN-2: teams matching [query], 50 at a time.

@ProviderFor(AdminTeams)
final adminTeamsProvider = AdminTeamsFamily._();

/// ADMIN-2: teams matching [query], 50 at a time.
final class AdminTeamsProvider
    extends $AsyncNotifierProvider<AdminTeams, AdminList<AdminTeamRow>> {
  /// ADMIN-2: teams matching [query], 50 at a time.
  AdminTeamsProvider._({
    required AdminTeamsFamily super.from,
    required AdminTeamQuery super.argument,
  }) : super(
         retry: null,
         name: r'adminTeamsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminTeamsHash();

  @override
  String toString() {
    return r'adminTeamsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminTeams create() => AdminTeams();

  @override
  bool operator ==(Object other) {
    return other is AdminTeamsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminTeamsHash() => r'7a0b127702999721750a000b17cdf13cde440dd9';

/// ADMIN-2: teams matching [query], 50 at a time.

final class AdminTeamsFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminTeams,
          AsyncValue<AdminList<AdminTeamRow>>,
          AdminList<AdminTeamRow>,
          FutureOr<AdminList<AdminTeamRow>>,
          AdminTeamQuery
        > {
  AdminTeamsFamily._()
    : super(
        retry: null,
        name: r'adminTeamsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-2: teams matching [query], 50 at a time.

  AdminTeamsProvider call(AdminTeamQuery query) =>
      AdminTeamsProvider._(argument: query, from: this);

  @override
  String toString() => r'adminTeamsProvider';
}

/// ADMIN-2: teams matching [query], 50 at a time.

abstract class _$AdminTeams extends $AsyncNotifier<AdminList<AdminTeamRow>> {
  late final _$args = ref.$arg as AdminTeamQuery;
  AdminTeamQuery get query => _$args;

  FutureOr<AdminList<AdminTeamRow>> build(AdminTeamQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<AdminList<AdminTeamRow>>,
              AdminList<AdminTeamRow>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AdminList<AdminTeamRow>>,
                AdminList<AdminTeamRow>
              >,
              AsyncValue<AdminList<AdminTeamRow>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// ADMIN-4: people matching [query], 50 at a time.

@ProviderFor(AdminUsers)
final adminUsersProvider = AdminUsersFamily._();

/// ADMIN-4: people matching [query], 50 at a time.
final class AdminUsersProvider
    extends $AsyncNotifierProvider<AdminUsers, AdminList<AdminUserRow>> {
  /// ADMIN-4: people matching [query], 50 at a time.
  AdminUsersProvider._({
    required AdminUsersFamily super.from,
    required AdminUserQuery super.argument,
  }) : super(
         retry: null,
         name: r'adminUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminUsersHash();

  @override
  String toString() {
    return r'adminUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminUsers create() => AdminUsers();

  @override
  bool operator ==(Object other) {
    return other is AdminUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminUsersHash() => r'0bf8d6433580f9a7bde2dfde92066adf3d1c3f88';

/// ADMIN-4: people matching [query], 50 at a time.

final class AdminUsersFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminUsers,
          AsyncValue<AdminList<AdminUserRow>>,
          AdminList<AdminUserRow>,
          FutureOr<AdminList<AdminUserRow>>,
          AdminUserQuery
        > {
  AdminUsersFamily._()
    : super(
        retry: null,
        name: r'adminUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-4: people matching [query], 50 at a time.

  AdminUsersProvider call(AdminUserQuery query) =>
      AdminUsersProvider._(argument: query, from: this);

  @override
  String toString() => r'adminUsersProvider';
}

/// ADMIN-4: people matching [query], 50 at a time.

abstract class _$AdminUsers extends $AsyncNotifier<AdminList<AdminUserRow>> {
  late final _$args = ref.$arg as AdminUserQuery;
  AdminUserQuery get query => _$args;

  FutureOr<AdminList<AdminUserRow>> build(AdminUserQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<AdminList<AdminUserRow>>,
              AdminList<AdminUserRow>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AdminList<AdminUserRow>>,
                AdminList<AdminUserRow>
              >,
              AsyncValue<AdminList<AdminUserRow>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// ADMIN-5: reports in [status] from every team, newest first.

@ProviderFor(AdminReports)
final adminReportsProvider = AdminReportsFamily._();

/// ADMIN-5: reports in [status] from every team, newest first.
final class AdminReportsProvider
    extends $AsyncNotifierProvider<AdminReports, AdminList<AdminReport>> {
  /// ADMIN-5: reports in [status] from every team, newest first.
  AdminReportsProvider._({
    required AdminReportsFamily super.from,
    required ReportStatus super.argument,
  }) : super(
         retry: null,
         name: r'adminReportsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminReportsHash();

  @override
  String toString() {
    return r'adminReportsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminReports create() => AdminReports();

  @override
  bool operator ==(Object other) {
    return other is AdminReportsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminReportsHash() => r'7e9938f29d3454b06c5b574b1e03e4489e0e4087';

/// ADMIN-5: reports in [status] from every team, newest first.

final class AdminReportsFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminReports,
          AsyncValue<AdminList<AdminReport>>,
          AdminList<AdminReport>,
          FutureOr<AdminList<AdminReport>>,
          ReportStatus
        > {
  AdminReportsFamily._()
    : super(
        retry: null,
        name: r'adminReportsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-5: reports in [status] from every team, newest first.

  AdminReportsProvider call(ReportStatus status) =>
      AdminReportsProvider._(argument: status, from: this);

  @override
  String toString() => r'adminReportsProvider';
}

/// ADMIN-5: reports in [status] from every team, newest first.

abstract class _$AdminReports extends $AsyncNotifier<AdminList<AdminReport>> {
  late final _$args = ref.$arg as ReportStatus;
  ReportStatus get status => _$args;

  FutureOr<AdminList<AdminReport>> build(ReportStatus status);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AdminList<AdminReport>>, AdminList<AdminReport>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AdminList<AdminReport>>,
                AdminList<AdminReport>
              >,
              AsyncValue<AdminList<AdminReport>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// ADMIN-6: the audit log matching [filter], newest first.

@ProviderFor(AdminAudit)
final adminAuditProvider = AdminAuditFamily._();

/// ADMIN-6: the audit log matching [filter], newest first.
final class AdminAuditProvider
    extends $AsyncNotifierProvider<AdminAudit, AdminList<AuditEntry>> {
  /// ADMIN-6: the audit log matching [filter], newest first.
  AdminAuditProvider._({
    required AdminAuditFamily super.from,
    required AuditFilter super.argument,
  }) : super(
         retry: null,
         name: r'adminAuditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminAuditHash();

  @override
  String toString() {
    return r'adminAuditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminAudit create() => AdminAudit();

  @override
  bool operator ==(Object other) {
    return other is AdminAuditProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminAuditHash() => r'e49c0f0c35f501ad459ebb29c1bf4bf0e7457a62';

/// ADMIN-6: the audit log matching [filter], newest first.

final class AdminAuditFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminAudit,
          AsyncValue<AdminList<AuditEntry>>,
          AdminList<AuditEntry>,
          FutureOr<AdminList<AuditEntry>>,
          AuditFilter
        > {
  AdminAuditFamily._()
    : super(
        retry: null,
        name: r'adminAuditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ADMIN-6: the audit log matching [filter], newest first.

  AdminAuditProvider call(AuditFilter filter) =>
      AdminAuditProvider._(argument: filter, from: this);

  @override
  String toString() => r'adminAuditProvider';
}

/// ADMIN-6: the audit log matching [filter], newest first.

abstract class _$AdminAudit extends $AsyncNotifier<AdminList<AuditEntry>> {
  late final _$args = ref.$arg as AuditFilter;
  AuditFilter get filter => _$args;

  FutureOr<AdminList<AuditEntry>> build(AuditFilter filter);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AdminList<AuditEntry>>, AdminList<AuditEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AdminList<AuditEntry>>,
                AdminList<AuditEntry>
              >,
              AsyncValue<AdminList<AuditEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
