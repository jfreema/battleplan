import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/link_opener.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/sharer.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

/// Platform services screens use directly. Declared in core/ so presentation
/// code can reach them; implementations are wired in app/providers.dart.

/// Picks profile photos.
@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Opens web and mailto links.
@Riverpod(keepAlive: true)
LinkOpener linkOpener(Ref ref) => const NoopLinkOpener();

/// The device's time zone and the list to pick from.
@Riverpod(keepAlive: true)
TimeZones timeZones(Ref ref) => const FixedTimeZones();

/// Shares links through the system share sheet.
@Riverpod(keepAlive: true)
Sharer sharer(Ref ref) => const NoopSharer();

/// Browser quirks on web, such as iOS needing Add to Home Screen for push.
@Riverpod(keepAlive: true)
BrowserInfo browserInfo(Ref ref) => const PlainBrowserInfo();

/// Adds events to the person's calendar (SCHED-10).
@Riverpod(keepAlive: true)
CalendarAdder calendarAdder(Ref ref) => const NoopCalendarAdder();

/// Where the web app lives, for links people share (an event's Share,
/// SCHED-4). Paths under it are the app's routes (ARCH §5.4).
@Riverpod(keepAlive: true)
Uri appWebBase(Ref ref) => Uri.parse('https://getbattleplan.app/app');
