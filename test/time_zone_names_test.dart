// Time zones by the names people know them by (the owner's request,
// 2026-10-26): the US and Canada's first, as "Central Time (Chicago)",
// then the rest by their offset from GMT, with the IANA ID kept.
import 'package:battleplan/core/services/time_zone_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Winter in the north, so Europe is on standard time.
  final january = DateTime.utc(2026, 1, 15);

  test('the US and Canada by name and city', () {
    expect(TimeZoneNames.label('America/Chicago'), 'Central Time (Chicago)');
    expect(TimeZoneNames.label('America/New_York'), 'Eastern Time (New York)');
    expect(TimeZoneNames.label('America/Phoenix'), 'Mountain Time (Phoenix)');
    expect(TimeZoneNames.label('America/Toronto'), 'Eastern Time (Toronto)');
    expect(
      TimeZoneNames.label('America/St_Johns'),
      "Newfoundland Time (St. John's)",
    );
    expect(
      TimeZoneNames.label('America/Indiana/Knox'),
      'Central Time (Knox, Indiana)',
    );
    expect(TimeZoneNames.label('Pacific/Honolulu'), 'Hawaii Time (Honolulu)');
  });

  test('the rest by city and offset from GMT', () {
    String at(String zone) => TimeZoneNames.label(zone, at: january);
    expect(at('Europe/Berlin'), 'Berlin (GMT+1)');
    expect(at('Asia/Kolkata'), 'Kolkata (GMT+5:30)');
    expect(at('Asia/Kathmandu'), 'Kathmandu (GMT+5:45)');
    expect(at('America/Caracas'), 'Caracas (GMT-4)');
    expect(at('Europe/London'), 'London (GMT)');
    expect(at('UTC'), 'UTC (GMT)');
    expect(
      at('America/Argentina/Buenos_Aires'),
      'Buenos Aires, Argentina (GMT-3)',
    );
    expect(
      TimeZoneNames.gmt(const Duration(hours: -3, minutes: -30)),
      'GMT-3:30',
    );
  });

  test('lists the US and Canada first, then by offset, without old names', () {
    final listed = TimeZoneNames.ordered([
      'Europe/Berlin',
      'Asia/Tokyo',
      'America/Los_Angeles',
      'US/Central',
      'Etc/GMT+5',
      'Asia/Calcutta',
      'Asia/Kolkata',
      'America/Sao_Paulo',
      'America/Chicago',
      'America/Toronto',
      'America/New_York',
      'UTC',
    ], at: january);
    expect(listed, [
      'America/New_York',
      'America/Toronto',
      'America/Chicago',
      'America/Los_Angeles',
      'America/Sao_Paulo',
      'UTC',
      'Europe/Berlin',
      'Asia/Kolkata',
      'Asia/Tokyo',
    ]);
    // A team already on an old name keeps it in the list.
    expect(
      TimeZoneNames.ordered(['Asia/Kolkata'], keep: ['Asia/Calcutta']),
      containsAll(['Asia/Kolkata', 'Asia/Calcutta']),
    );
  });

  test('search finds a zone by its name, city, or ID', () {
    for (final typed in ['central', 'Chicago', 'america/chi', 'CENTRAL TIME']) {
      expect(
        TimeZoneNames.matches('America/Chicago', typed),
        isTrue,
        reason: typed,
      );
    }
    expect(TimeZoneNames.matches('America/Chicago', 'pacific'), isFalse);
    expect(TimeZoneNames.matches('America/New_York', 'new york'), isTrue);
    expect(
      TimeZoneNames.matches('Europe/Berlin', 'GMT+1', at: january),
      isTrue,
    );
    expect(TimeZoneNames.matches('Europe/Berlin', ''), isTrue);
  });
}
