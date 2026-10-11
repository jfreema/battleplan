/// Shares a link through the system share sheet, or Web Share in browsers
/// (SPEC §4.2). Returns false if sharing isn't available here, so the caller
/// can copy the link instead.
abstract interface class Sharer {
  Future<bool> shareLink(Uri uri, {String? subject});
}

class NoopSharer implements Sharer {
  const new();

  @override
  Future<bool> shareLink(Uri uri, {String? subject}) async => false;
}
