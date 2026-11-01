/// Download links for stored files, by path, kept for the app's run
/// (ARCH §5.6): a file's link doesn't change while it exists, and every
/// upload gets a new path, so asking Storage again only costs a round trip
/// before each photo, avatar, or logo can load. Concurrent asks for the
/// same path share one request; a failed one isn't kept.
class UrlCache {
  final _urls = <String, Future<String?>>{};

  /// The link for [path], from [fetch] the first time.
  Future<String?> get(String path, Future<String?> Function() fetch) =>
      _urls[path] ??= _fetch(path, fetch);

  Future<String?> _fetch(String path, Future<String?> Function() fetch) async {
    try {
      final url = await fetch();
      if (url == null) _forget(path);
      return url;
    } on Object {
      _forget(path);
      rethrow;
    }
  }

  void _forget(String path) => _urls.removeWhere((key, _) => key == path);
}
