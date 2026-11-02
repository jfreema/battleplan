// The zone names the app's smaller `timezone` database leaves out, which
// phones and browsers still report (timeZoneLinks): each one works, with
// the times the full database gives it.
import 'package:battleplan/core/services/time_zone_links.dart';
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as small;
import 'package:timezone/data/latest_all.dart' as full;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('a zone the small database leaves out shows its own time', () {
    // 6:00 PM UTC on Wed, Jul 1.
    final at = DateTime.utc(2026, 7, 1, 18);
    expect(ZonedTime.isKnown('Europe/Amsterdam'), isTrue);
    expect(ZonedTime.wallClock('Europe/Amsterdam', at).hour, 20);
    expect(ZonedTime.wallClock('America/Nassau', at).hour, 14);
    expect(ZonedTime.abbreviation('Asia/Calcutta', at), 'IST');
    expect(
      TimeZoneNames.label('Europe/Amsterdam', at: at),
      'Amsterdam (GMT+2)',
    );
    expect(TimeZoneNames.label('UTC', at: at), 'UTC (GMT)');
  });

  // Last: it leaves the full database loaded.
  test('every name in the full database is in the small one or links to a '
      'zone in it with the same times', () {
    small.initializeTimeZones();
    final known = Map.of(tz.timeZoneDatabase.locations);
    full.initializeTimeZones();
    final all = Map.of(tz.timeZoneDatabase.locations);

    // The offset and abbreviation twice a month, 1990 through 2040.
    String times(tz.Location zone) => [
      for (var year = 1990; year <= 2040; year++)
        for (var month = 1; month <= 12; month++)
          for (final day in [1, 15])
            switch (tz.TZDateTime.from(
              DateTime.utc(year, month, day, 12),
              zone,
            )) {
              final t => '${t.timeZoneOffset.inMinutes} ${t.timeZoneName}',
            },
    ].join(', ');

    for (final MapEntry(key: name, value: zone) in all.entries) {
      if (known.containsKey(name)) continue;
      final link = timeZoneLinks[name];
      expect(link, isNotNull, reason: '$name is missing from timeZoneLinks');
      expect(known.containsKey(link), isTrue, reason: '$name links to $link');
      expect(times(zone), times(known[link]!), reason: '$name and $link');
    }
    for (final MapEntry(key: name, value: link) in timeZoneLinks.entries) {
      expect(known.containsKey(link), isTrue, reason: '$name links to $link');
    }
  });
}
