import 'package:battleplan/app/services/web_browser_info_stub.dart'
    if (dart.library.js_interop) 'package:battleplan/app/services/web_browser_info_web.dart'
    as platform;
import 'package:battleplan/core/services/browser_info.dart';

/// The browser's user agent and display mode behind [BrowserInfo]. Read
/// once: neither changes while the page is open.
class WebBrowserInfo implements BrowserInfo {
  new() : pushNeedsHomeScreen = platform.pushNeedsHomeScreen();

  @override
  final bool pushNeedsHomeScreen;
}
