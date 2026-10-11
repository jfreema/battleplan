/// Opens links outside the app: web pages in the browser, `mailto:` in the
/// mail app (ARCH §5.2 rule 8).
abstract interface class LinkOpener {
  Future<bool> open(Uri uri);
}

class NoopLinkOpener implements LinkOpener {
  const new();

  @override
  Future<bool> open(Uri uri) async => false;
}
