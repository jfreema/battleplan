import 'package:battleplan/core/photo_location.dart';
import 'package:battleplan/core/services/photo_picker.dart';

/// Photos pasted or dragged onto the page, the web's other two ways to add
/// photos beside the file picker (SPEC §4.2 parity table: "File picker,
/// drag and drop, or paste"). Phones have none.
abstract interface class PhotoDrops {
  /// Each paste or drop's images, resized and compressed like picked chat
  /// photos (CHAT-3). Files that aren't images are left out.
  Stream<List<PickedPhoto>> get photos;

  /// True while files are dragged over the page, false when they leave or
  /// land.
  Stream<bool> get dragging;
}

/// Phones and tests: nothing is ever pasted or dropped.
class NoPhotoDrops implements PhotoDrops {
  const new();

  @override
  Stream<List<PickedPhoto>> get photos => const Stream.empty();

  @override
  Stream<bool> get dragging => const Stream.empty();
}

/// Removes each photo's location before anything uploads it (Privacy
/// Policy; ARCH §6.8), as [LocationStrippingPhotoPicker] does for picked
/// ones.
class LocationStrippingPhotoDrops implements PhotoDrops {
  const new(this._inner);

  final PhotoDrops _inner;

  @override
  Stream<List<PickedPhoto>> get photos => _inner.photos.map(
    (list) => [
      for (final p in list)
        (bytes: stripPhotoLocation(p.bytes), contentType: p.contentType),
    ],
  );

  @override
  Stream<bool> get dragging => _inner.dragging;
}
