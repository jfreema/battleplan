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

/// Photos pasted or dropped onto the web page (SPEC §4.2); none on phones.

@ProviderFor(photoDrops)
final photoDropsProvider = PhotoDropsProvider._();

/// Photos pasted or dropped onto the web page (SPEC §4.2); none on phones.

final class PhotoDropsProvider
    extends $FunctionalProvider<PhotoDrops, PhotoDrops, PhotoDrops>
    with $Provider<PhotoDrops> {
  /// Photos pasted or dropped onto the web page (SPEC §4.2); none on phones.
  PhotoDropsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoDropsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoDropsHash();

  @$internal
  @override
  $ProviderElement<PhotoDrops> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoDrops create(Ref ref) {
    return photoDrops(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoDrops value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoDrops>(value),
    );
  }
}

String _$photoDropsHash() => r'48fb963c30e4aed3cdbded44a7d93a5a7b40737f';

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

/// Shares links through the system share sheet.

@ProviderFor(sharer)
final sharerProvider = SharerProvider._();

/// Shares links through the system share sheet.

final class SharerProvider extends $FunctionalProvider<Sharer, Sharer, Sharer>
    with $Provider<Sharer> {
  /// Shares links through the system share sheet.
  SharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharerHash();

  @$internal
  @override
  $ProviderElement<Sharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Sharer create(Ref ref) {
    return sharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Sharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Sharer>(value),
    );
  }
}

String _$sharerHash() => r'5a159f8e549a4b36db142cdc12aa46b6fdf89916';

/// Browser quirks on web, such as iOS needing Add to Home Screen for push.

@ProviderFor(browserInfo)
final browserInfoProvider = BrowserInfoProvider._();

/// Browser quirks on web, such as iOS needing Add to Home Screen for push.

final class BrowserInfoProvider
    extends $FunctionalProvider<BrowserInfo, BrowserInfo, BrowserInfo>
    with $Provider<BrowserInfo> {
  /// Browser quirks on web, such as iOS needing Add to Home Screen for push.
  BrowserInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserInfoHash();

  @$internal
  @override
  $ProviderElement<BrowserInfo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BrowserInfo create(Ref ref) {
    return browserInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrowserInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrowserInfo>(value),
    );
  }
}

String _$browserInfoHash() => r'200d0c9eb4e2d5356326c00a10240acb3454b56a';

/// Adds events to the person's calendar (SCHED-10).

@ProviderFor(calendarAdder)
final calendarAdderProvider = CalendarAdderProvider._();

/// Adds events to the person's calendar (SCHED-10).

final class CalendarAdderProvider
    extends $FunctionalProvider<CalendarAdder, CalendarAdder, CalendarAdder>
    with $Provider<CalendarAdder> {
  /// Adds events to the person's calendar (SCHED-10).
  CalendarAdderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarAdderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarAdderHash();

  @$internal
  @override
  $ProviderElement<CalendarAdder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CalendarAdder create(Ref ref) {
    return calendarAdder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarAdder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarAdder>(value),
    );
  }
}

String _$calendarAdderHash() => r'ec5fb013f69b18db118fb9c13ec30db1c043b78d';

/// Picks files to upload and saves downloads (DOC-2, DOC-4).

@ProviderFor(fileChooser)
final fileChooserProvider = FileChooserProvider._();

/// Picks files to upload and saves downloads (DOC-2, DOC-4).

final class FileChooserProvider
    extends $FunctionalProvider<FileChooser, FileChooser, FileChooser>
    with $Provider<FileChooser> {
  /// Picks files to upload and saves downloads (DOC-2, DOC-4).
  FileChooserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileChooserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileChooserHash();

  @$internal
  @override
  $ProviderElement<FileChooser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileChooser create(Ref ref) {
    return fileChooser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileChooser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileChooser>(value),
    );
  }
}

String _$fileChooserHash() => r'20ccd176452708f87ec03733eb88f0609b64be74';

/// Builds every Battleplan URL (ARCH §6.6): links people share (an event's
/// Share, SCHED-4), invite links, and email links. Web app links are under
/// `/app`; the paths after it are the app's routes (ARCH §5.4).

@ProviderFor(linkService)
final linkServiceProvider = LinkServiceProvider._();

/// Builds every Battleplan URL (ARCH §6.6): links people share (an event's
/// Share, SCHED-4), invite links, and email links. Web app links are under
/// `/app`; the paths after it are the app's routes (ARCH §5.4).

final class LinkServiceProvider
    extends $FunctionalProvider<LinkService, LinkService, LinkService>
    with $Provider<LinkService> {
  /// Builds every Battleplan URL (ARCH §6.6): links people share (an event's
  /// Share, SCHED-4), invite links, and email links. Web app links are under
  /// `/app`; the paths after it are the app's routes (ARCH §5.4).
  LinkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkServiceHash();

  @$internal
  @override
  $ProviderElement<LinkService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkService create(Ref ref) {
    return linkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkService>(value),
    );
  }
}

String _$linkServiceHash() => r'733247de94a799b422e82325a15227b0e3e56e1e';
