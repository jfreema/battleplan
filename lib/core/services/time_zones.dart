import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The device's time zone and the list to choose from (ARCH §5.2 rule 9:
/// one time-zone utility). IDs are IANA names like "America/Chicago".
abstract interface class TimeZones {
  Future<String> deviceTimeZone();

  Future<List<String>> available();
}

/// Fallback when the platform can't say (tests, unsupported platforms).
class FixedTimeZones implements TimeZones {
  const new([this.zone = 'America/Chicago']);

  final String zone;

  @override
  Future<String> deviceTimeZone() async => zone;

  @override
  Future<List<String>> available() async => [zone];
}

/// Wall-clock time in a named zone (SCHED-9, ARCH §6.2): an event's "6:00
/// PM in America/Chicago" turned into an instant, and back, with the
/// `timezone` database. Pure Dart, so domain code uses it too. The database
/// loads on first use (about 250 KB of data, read once).
abstract final class ZonedTime {
  static bool _loaded = false;

  /// Loads the zone database. Called at startup; every method below also
  /// calls it, so tests and early callers never see an empty database.
  static void ensureInitialized() {
    if (_loaded) return;
    tzdata.initializeTimeZones();
    _loaded = true;
  }

  static tz.Location _zone(String zone) {
    ensureInitialized();
    try {
      return tz.getLocation(zone);
    } on Object {
      return tz.UTC;
    }
  }

  /// Whether [zone] is a zone the database knows.
  static bool isKnown(String zone) {
    ensureInitialized();
    return tz.timeZoneDatabase.locations.containsKey(zone);
  }

  /// The instant [minutes] after midnight on [date] (only its year, month,
  /// and day count) in [zone]. A time that doesn't exist that day, inside a
  /// spring-forward gap, moves past the gap.
  static DateTime instantOf(String zone, DateTime date, int minutes) =>
      tz.TZDateTime(
        _zone(zone),
        date.year,
        date.month,
        date.day,
        minutes ~/ 60,
        minutes % 60,
      ).toUtc().native;

  /// [instant] as wall-clock time in [zone]. Its fields (year to minute)
  /// read in that zone, so date formatting shows that zone's time.
  static DateTime wallClock(String zone, DateTime instant) =>
      tz.TZDateTime.from(instant, _zone(zone));

  /// The zone's abbreviation at [instant]: "CDT", "CST", or "+03" where
  /// the database has no letters.
  static String abbreviation(String zone, DateTime instant) =>
      tz.TZDateTime.from(instant, _zone(zone)).timeZoneName;

  /// The zone's offset from UTC at [instant].
  static Duration offsetAt(String zone, DateTime instant) =>
      tz.TZDateTime.from(instant, _zone(zone)).timeZoneOffset;
}
