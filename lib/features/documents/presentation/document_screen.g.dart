// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The PDF viewer (DOC-4): pdfrx on every platform, the web included.
/// Tests swap it for a stand-in, since PDFium doesn't run in them.

@ProviderFor(pdfView)
final pdfViewProvider = PdfViewProvider._();

/// The PDF viewer (DOC-4): pdfrx on every platform, the web included.
/// Tests swap it for a stand-in, since PDFium doesn't run in them.

final class PdfViewProvider
    extends $FunctionalProvider<PdfViewBuilder, PdfViewBuilder, PdfViewBuilder>
    with $Provider<PdfViewBuilder> {
  /// The PDF viewer (DOC-4): pdfrx on every platform, the web included.
  /// Tests swap it for a stand-in, since PDFium doesn't run in them.
  PdfViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfViewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfViewHash();

  @$internal
  @override
  $ProviderElement<PdfViewBuilder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfViewBuilder create(Ref ref) {
    return pdfView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfViewBuilder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfViewBuilder>(value),
    );
  }
}

String _$pdfViewHash() => r'be7ed4bfe64808e9e932d1fb0caa5ac1ff39de98';
