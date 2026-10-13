import 'package:battleplan/core/links.dart';
import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/file_chooser.dart';
import 'package:battleplan/core/services/link_opener.dart';
import 'package:battleplan/core/services/photo_drops.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/photo_saver.dart';
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

/// Photos pasted or dropped onto the web page (CHAT-2, SPEC §4.2); none on
/// phones.
@Riverpod(keepAlive: true)
PhotoDrops photoDrops(Ref ref) => const NoPhotoDrops();

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

/// Picks files to upload and saves downloads (DOC-2, DOC-4).
@Riverpod(keepAlive: true)
FileChooser fileChooser(Ref ref) => const NoopFileChooser();

/// Builds every Battleplan URL (ARCH §6.6): links people share (an event's
/// Share, SCHED-4), invite links, and email links. Web app links are under
/// `/app`; the paths after it are the app's routes (ARCH §5.4).
@Riverpod(keepAlive: true)
LinkService linkService(Ref ref) => const LinkService(LinkService.prodHost);

/// Saves chat photos to the phone's photo library (CHAT-3).
@Riverpod(keepAlive: true)
PhotoSaver photoSaver(Ref ref) => const NoPhotoSaver();
