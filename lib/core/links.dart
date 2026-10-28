/// The one place the app builds Battleplan URLs (ARCH §6.6, D40).
///
/// The website is served at the root of the domain and the web app under
/// `/app`. Invite links stay short at `/join/<CODE>`; everything that opens
/// the app (shared events, email sign-in, notification clicks) goes to
/// `/app/...`. Hosting redirects `/join`, `/activate`, `/emaillogin`, and
/// `/g` into `/app` in browsers, and the native apps drop the `/app` prefix
/// before routing ([stripAppPrefix]).
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

  /// Email sign-in (AUTH-2), short: `https://<host>/emaillogin`, which
  /// Hosting redirects into the web app and the phone apps open. Nothing
  /// links to it; the app shows it only to people who use a password.
  Uri get emailLogin => site('/emaillogin');

  /// [emailLogin] to read, without `https://`: `getbattleplan.app/emaillogin`.
  String get emailLoginText => '$host${emailLogin.path}';

  /// A website page at the root of the domain, like `/privacy`.
  Uri site(String page) => Uri(
    scheme: 'https',
    host: host,
    path: page.startsWith('/') ? page : '/$page',
  );

  /// A shared play's public link (BOARD-6): `https://<host>/p/<shareId>`,
  /// which Hosting hands to the `playPage` function.
  Uri play(String shareId) => site('/p/$shareId');

  /// A calendar link's feed (SCHED-11): `https://<host>/cal/<token>.ics`,
  /// which Hosting hands to the `calendarFeed` function (ARCH §6.15).
  Uri calendarFeed(String token) => site('/cal/$token.ics');

  /// The same feed as `webcal://`, which Apple Calendar subscribes to.
  Uri calendarWebcal(String token) =>
      calendarFeed(token).replace(scheme: 'webcal');

  /// Google Calendar's page that adds the feed. It's on Google's website:
  /// the phone app can't add a calendar from a link.
  Uri googleCalendarAdd(String token) => Uri.https(
    'calendar.google.com',
    '/calendar/r',
    {'cid': calendarWebcal(token).toString()},
  );

  /// Outlook's page that adds the feed as a calendar named [name].
  Uri outlookAdd(String token, String name) => Uri.https(
    'outlook.live.com',
    '/calendar/0/addfromweb',
    {'url': calendarFeed(token).toString(), 'name': name},
  );

  /// The iPhone app's App Store listing (NOTIF-9), through `/ios` on our
  /// domain, which Hosting redirects to the listing (firebase.json), so the
  /// link in installed apps never has to change.
  Uri get iosApp => site('/ios');

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
