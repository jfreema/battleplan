import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Whether this browser has Web Share for [uri] (`navigator.share`, and
/// `navigator.canShare` where it exists). Desktop Firefox, for one, has
/// neither, and then the caller copies the link instead (SPEC §4.2).
bool canWebShareLink(Uri uri) {
  try {
    final navigator = web.window.navigator;
    final object = navigator as JSObject;
    if (!object.has('share')) return false;
    if (!object.has('canShare')) return true;
    return navigator.canShare(web.ShareData(url: uri.toString()));
  } on Object {
    return false;
  }
}
