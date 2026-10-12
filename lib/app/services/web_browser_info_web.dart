import 'package:web/web.dart' as web;

/// Every iPhone and iPad browser is Safari underneath, and web push there
/// works only for a web app opened from the Home Screen (NOTIF-9, iOS
/// 16.4+). iPads ask for desktop sites, so they look like a Mac with touch.
bool pushNeedsHomeScreen() {
  final navigator = web.window.navigator;
  final ua = navigator.userAgent;
  final ios =
      RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && navigator.maxTouchPoints > 1);
  if (!ios) return false;
  return !web.window.matchMedia('(display-mode: standalone)').matches;
}
