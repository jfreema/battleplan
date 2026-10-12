import 'package:battleplan/core/services/photo_picker.dart';

/// Photos pasted or dragged onto the page (CHAT-2, web). Each paste or drop
/// arrives as one list, up to 10 photos, already resized for upload like
/// picked ones (CHAT-3).
abstract interface class PhotoDrops {
  /// Listening turns it on; while nothing listens, the page handles pastes
  /// and drops as usual.
  Stream<List<PickedPhoto>> get photos;
}

/// Phones and tests: photos come from the picker only.
class NoPhotoDrops implements PhotoDrops {
  const new();

  @override
  Stream<List<PickedPhoto>> get photos => const Stream.empty();
}
