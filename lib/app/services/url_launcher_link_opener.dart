import 'package:battleplan/core/services/link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

/// `url_launcher` behind [LinkOpener].
class UrlLauncherLinkOpener implements LinkOpener {
  const new();

  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
