import 'package:battleplan/app/services/browser_photo_drops_stub.dart'
    if (dart.library.js_interop) 'package:battleplan/app/services/browser_photo_drops_web.dart'
    as platform;
import 'package:battleplan/core/services/photo_drops.dart';

/// Photos pasted or dropped onto the web page (SPEC §4.2), or none on
/// phones.
PhotoDrops browserPhotoDrops() => platform.browserPhotoDrops();
