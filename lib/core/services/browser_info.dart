/// What the app needs to know about the browser it runs in. Web only; on
/// phones and in tests every answer is "no" (ARCH §5.2 rule 8).
abstract interface class BrowserInfo {
  /// True on an iPhone or iPad browser tab, where web push works only once
  /// the app is added to the Home Screen (NOTIF-9).
  bool get pushNeedsHomeScreen;
}

/// Not a browser, or one without quirks the app cares about.
class PlainBrowserInfo implements BrowserInfo {
  const new();

  @override
  bool get pushNeedsHomeScreen => false;
}
