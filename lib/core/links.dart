/// The one place the app builds Battleplan URLs (ARCH §6.6, D40).
///
/// The website is served at the root of the domain and the web app under
/// `/app`. Invite links stay short at `/join/<CODE>`; everything that opens
/// the app (shared events, email sign-in, notification clicks) goes to
/// `/app/...`. Hosting redirects `/join`, `/activate`, and `/g` into `/app`
/// in browsers, and the native apps drop the `/app` prefix before routing
/// ([stripAppPrefix]).
class LinkService {
  const new(this.host);

  /// The service for a flavor.
  factory forEnv({required bool isProd}) =>
      LinkService(isProd ? prodHost : devHost);

  /// Our domain in prod, the dev Hosting domain otherwise.
  final String host;

  /// The prod domain.
  static const prodHost = 'getbattleplan.app';

  /// The dev Hosting domain.
  static const devHost = 'battleplan-dev-ecce4.web.app';

  /// Where the web app lives on the domain.
  static const appPrefix = '/app';

  /// The web app's root, `https://<host>/app/`.
  Uri get appRoot => app('/');

  /// `https://<host>/app<route>` for an app route like `/g/abc/chat`.
  Uri app(String route) {
    final r = Uri.parse(route.startsWith('/') ? route : '/$route');
    return Uri(
      scheme: 'https',
      host: host,
      path: '$appPrefix${r.path}',
      query: r.hasQuery ? r.query : null,
    );
  }

  /// `https://<host>/join/<CODE>` (INV-2): short, for links and QR codes.
  Uri join(String code) =>
      Uri(scheme: 'https', host: host, path: '/join/$code');

  /// Where an emailed sign-in link lands (the Auth `ActionCodeSettings`
  /// url).
  Uri get activate => app('/activate');

  /// A website page at the root of the domain, like `/privacy`.
  Uri site(String page) => Uri(
    scheme: 'https',
    host: host,
    path: page.startsWith('/') ? page : '/$page',
  );

  /// Whether [host] is a custom domain. Firebase accepts only a custom
  /// Hosting domain as an email link's `linkDomain` (M0 spike 2).
  bool get isCustomDomain =>
      !host.endsWith('.web.app') && !host.endsWith('.firebaseapp.com');
}

/// A deep link with the `/app` prefix removed, or null when it has none.
///
/// Universal Links and App Links deliver the full path, so a link like
/// `https://getbattleplan.app/app/g/a/chat` arrives as `/app/g/a/chat`; the
/// router's routes have no prefix. On the web the base href (`/app/`) already
/// takes it off.
Uri? stripAppPrefix(Uri uri) {
  const prefix = LinkService.appPrefix;
  final path = uri.path;
  if (path != prefix && !path.startsWith('$prefix/')) return null;
  final rest = path.substring(prefix.length);
  return uri.replace(path: rest.isEmpty ? '/' : rest);
}
