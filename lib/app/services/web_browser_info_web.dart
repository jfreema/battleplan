import 'package:web/web.dart' as web;

/// Every iPhone and iPad browser is Safari underneath, and web push there
/// works only for a web app opened from the Home Screen (NOTIF-9, iOS
/// 16.4+). iPads ask for desktop sites, so they look like a Mac with touch.
bool pushNeedsHomeScreen() {
  if (!_ios()) return false;
  return !web.window.matchMedia('(display-mode: standalone)').matches;
}

/// A phone or tablet's browser, where the app can be installed (INV-7):
/// an iPhone, an iPad (which asks for desktop sites, so looks like a Mac
/// with touch), or Android.
bool onPhone() => _ios() || web.window.navigator.userAgent.contains('Android');

bool _ios() {
  final navigator = web.window.navigator;
  final ua = navigator.userAgent;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && navigator.maxTouchPoints > 1);
}
