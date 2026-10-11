// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Platform services screens use directly. Declared in core/ so presentation
/// code can reach them; implementations are wired in app/providers.dart.
/// Picks profile photos.

@ProviderFor(photoPicker)
final photoPickerProvider = PhotoPickerProvider._();

/// Platform services screens use directly. Declared in core/ so presentation
/// code can reach them; implementations are wired in app/providers.dart.
/// Picks profile photos.

final class PhotoPickerProvider
    extends $FunctionalProvider<PhotoPicker, PhotoPicker, PhotoPicker>
    with $Provider<PhotoPicker> {
  /// Platform services screens use directly. Declared in core/ so presentation
  /// code can reach them; implementations are wired in app/providers.dart.
  /// Picks profile photos.
  PhotoPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoPickerHash();

  @$internal
  @override
  $ProviderElement<PhotoPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoPicker create(Ref ref) {
    return photoPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoPicker>(value),
    );
  }
}

String _$photoPickerHash() => r'067730d189463d1d8099f2ef8519fcc7b39c9562';

/// Opens web and mailto links.

@ProviderFor(linkOpener)
final linkOpenerProvider = LinkOpenerProvider._();

/// Opens web and mailto links.

final class LinkOpenerProvider
    extends $FunctionalProvider<LinkOpener, LinkOpener, LinkOpener>
    with $Provider<LinkOpener> {
  /// Opens web and mailto links.
  LinkOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkOpenerHash();

  @$internal
  @override
  $ProviderElement<LinkOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkOpener create(Ref ref) {
    return linkOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkOpener>(value),
    );
  }
}

String _$linkOpenerHash() => r'd1c40125c94c381ce2a5ef98e9f84a1350effc35';

/// The device's time zone and the list to pick from.

@ProviderFor(timeZones)
final timeZonesProvider = TimeZonesProvider._();

/// The device's time zone and the list to pick from.

final class TimeZonesProvider
    extends $FunctionalProvider<TimeZones, TimeZones, TimeZones>
    with $Provider<TimeZones> {
  /// The device's time zone and the list to pick from.
  TimeZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timeZonesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timeZonesHash();

  @$internal
  @override
  $ProviderElement<TimeZones> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TimeZones create(Ref ref) {
    return timeZones(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimeZones value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimeZones>(value),
    );
  }
}

String _$timeZonesHash() => r'6ae7fc2d09a741ec5333e9f7e27613f9283b691b';
