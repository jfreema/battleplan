// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(documentRepository)
final documentRepositoryProvider = DocumentRepositoryProvider._();

/// Overridden in app/providers.dart.

final class DocumentRepositoryProvider
    extends
        $FunctionalProvider<
          DocumentRepository,
          DocumentRepository,
          DocumentRepository
        >
    with $Provider<DocumentRepository> {
  /// Overridden in app/providers.dart.
  DocumentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentRepositoryHash();

  @$internal
  @override
  $ProviderElement<DocumentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DocumentRepository create(Ref ref) {
    return documentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentRepository>(value),
    );
  }
}

String _$documentRepositoryHash() =>
    r'7fccadbfe0d5915fffeafc5dfaa4458bd1d685d6';

/// One document, live (DOC-4). Null once it's deleted.

@ProviderFor(document)
final documentProvider = DocumentFamily._();

/// One document, live (DOC-4). Null once it's deleted.

final class DocumentProvider
    extends
        $FunctionalProvider<AsyncValue<Document?>, Document?, Stream<Document?>>
    with $FutureModifier<Document?>, $StreamProvider<Document?> {
  /// One document, live (DOC-4). Null once it's deleted.
  DocumentProvider._({
    required DocumentFamily super.from,
    required DocumentId super.argument,
  }) : super(
         retry: null,
         name: r'documentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentHash();

  @override
  String toString() {
    return r'documentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Document?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Document?> create(Ref ref) {
    final argument = this.argument as DocumentId;
    return document(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentHash() => r'ffa9db2099de464751cf60c5bd5dbc0fdc30b1e0';

/// One document, live (DOC-4). Null once it's deleted.

final class DocumentFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Document?>, DocumentId> {
  DocumentFamily._()
    : super(
        retry: null,
        name: r'documentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One document, live (DOC-4). Null once it's deleted.

  DocumentProvider call(DocumentId id) =>
      DocumentProvider._(argument: id, from: this);

  @override
  String toString() => r'documentProvider';
}

/// A download URL for a stored file: image thumbnails, and opening other
/// files in the phone's default app (DOC-4).

@ProviderFor(documentFileUrl)
final documentFileUrlProvider = DocumentFileUrlFamily._();

/// A download URL for a stored file: image thumbnails, and opening other
/// files in the phone's default app (DOC-4).

final class DocumentFileUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A download URL for a stored file: image thumbnails, and opening other
  /// files in the phone's default app (DOC-4).
  DocumentFileUrlProvider._({
    required DocumentFileUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentFileUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentFileUrlHash();

  @override
  String toString() {
    return r'documentFileUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return documentFileUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentFileUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentFileUrlHash() => r'72c384ab35e3743537b1b6f133d88b60598946a2';

/// A download URL for a stored file: image thumbnails, and opening other
/// files in the phone's default app (DOC-4).

final class DocumentFileUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  DocumentFileUrlFamily._()
    : super(
        retry: null,
        name: r'documentFileUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A download URL for a stored file: image thumbnails, and opening other
  /// files in the phone's default app (DOC-4).

  DocumentFileUrlProvider call(String path) =>
      DocumentFileUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'documentFileUrlProvider';
}

/// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
/// Kept while the viewer is open.

@ProviderFor(documentFileBytes)
final documentFileBytesProvider = DocumentFileBytesFamily._();

/// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
/// Kept while the viewer is open.

final class DocumentFileBytesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List?>,
          Uint8List?,
          FutureOr<Uint8List?>
        >
    with $FutureModifier<Uint8List?>, $FutureProvider<Uint8List?> {
  /// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
  /// Kept while the viewer is open.
  DocumentFileBytesProvider._({
    required DocumentFileBytesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentFileBytesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentFileBytesHash();

  @override
  String toString() {
    return r'documentFileBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List?> create(Ref ref) {
    final argument = this.argument as String;
    return documentFileBytes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentFileBytesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentFileBytesHash() => r'cd3191f116c86072d4b99cc0e2aef587324156a5';

/// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
/// Kept while the viewer is open.

final class DocumentFileBytesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List?>, String> {
  DocumentFileBytesFamily._()
    : super(
        retry: null,
        name: r'documentFileBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A stored file's bytes, for the viewer, Share, and Download (DOC-4).
  /// Kept while the viewer is open.

  DocumentFileBytesProvider call(String path) =>
      DocumentFileBytesProvider._(argument: path, from: this);

  @override
  String toString() => r'documentFileBytesProvider';
}

@ProviderFor(DocumentsViewOptions)
final documentsViewOptionsProvider = DocumentsViewOptionsProvider._();

final class DocumentsViewOptionsProvider
    extends $NotifierProvider<DocumentsViewOptions, DocumentsView> {
  DocumentsViewOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsViewOptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsViewOptionsHash();

  @$internal
  @override
  DocumentsViewOptions create() => DocumentsViewOptions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentsView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentsView>(value),
    );
  }
}

String _$documentsViewOptionsHash() =>
    r'6bcfae43ff7f03a74a9371ad2345540facabd640';

abstract class _$DocumentsViewOptions extends $Notifier<DocumentsView> {
  DocumentsView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DocumentsView, DocumentsView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DocumentsView, DocumentsView>,
              DocumentsView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A team's documents in [sort] order: the first 100 live, then pages of
/// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
/// on their own so they list first even when they're older.

@ProviderFor(TeamDocuments)
final teamDocumentsProvider = TeamDocumentsFamily._();

/// A team's documents in [sort] order: the first 100 live, then pages of
/// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
/// on their own so they list first even when they're older.
final class TeamDocumentsProvider
    extends $NotifierProvider<TeamDocuments, DocumentListState> {
  /// A team's documents in [sort] order: the first 100 live, then pages of
  /// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
  /// on their own so they list first even when they're older.
  TeamDocumentsProvider._({
    required TeamDocumentsFamily super.from,
    required (GroupId, DocumentSort) super.argument,
  }) : super(
         retry: null,
         name: r'teamDocumentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamDocumentsHash();

  @override
  String toString() {
    return r'teamDocumentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TeamDocuments create() => TeamDocuments();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamDocumentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamDocumentsHash() => r'd3e26f18e81f43fc8326a525ebd9f0f990e4e62d';

/// A team's documents in [sort] order: the first 100 live, then pages of
/// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
/// on their own so they list first even when they're older.

final class TeamDocumentsFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamDocuments,
          DocumentListState,
          DocumentListState,
          DocumentListState,
          (GroupId, DocumentSort)
        > {
  TeamDocumentsFamily._()
    : super(
        retry: null,
        name: r'teamDocumentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's documents in [sort] order: the first 100 live, then pages of
  /// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
  /// on their own so they list first even when they're older.

  TeamDocumentsProvider call(GroupId groupId, DocumentSort sort) =>
      TeamDocumentsProvider._(argument: (groupId, sort), from: this);

  @override
  String toString() => r'teamDocumentsProvider';
}

/// A team's documents in [sort] order: the first 100 live, then pages of
/// 100 (queries are capped at 100, ARCH §10.2), with the pinned ones live
/// on their own so they list first even when they're older.

abstract class _$TeamDocuments extends $Notifier<DocumentListState> {
  late final _$args = ref.$arg as (GroupId, DocumentSort);
  GroupId get groupId => _$args.$1;
  DocumentSort get sort => _$args.$2;

  DocumentListState build(GroupId groupId, DocumentSort sort);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DocumentListState, DocumentListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DocumentListState, DocumentListState>,
              DocumentListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
