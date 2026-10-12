import 'package:battleplan/app/services/web_photo_drops_stub.dart'
    if (dart.library.js_interop) 'package:battleplan/app/services/web_photo_drops_web.dart'
    as platform;
import 'package:battleplan/core/photo_location.dart';
import 'package:battleplan/core/services/photo_drops.dart';
import 'package:battleplan/core/services/photo_picker.dart';

/// Images pasted into, or dragged onto, the browser window (CHAT-2), behind
/// [PhotoDrops]. Each is resized to at most 2048 px and re-encoded as JPEG
/// at quality 85, as picked photos are (CHAT-3), with any location removed.
class WebPhotoDrops implements PhotoDrops {
  const new();

  @override
  Stream<List<PickedPhoto>> get photos => platform
      .photoDrops(maxEdge: 2048, quality: 0.85, limit: 10)
      .map(
        (list) => [
          for (final p in list)
            (bytes: stripPhotoLocation(p.bytes), contentType: p.contentType),
        ],
      )
      .where((list) => list.isNotEmpty);
}
