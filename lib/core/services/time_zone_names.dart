import 'package:battleplan/core/services/time_zones.dart';

/// Time zones by the names people know them by (the owner's request,
/// 2026-10-26): "Central Time (Chicago)" for the US and Canada's, which
/// list first, and the city with its offset from GMT for the rest
/// ("Berlin (GMT+1)", "Kolkata (GMT+5:30)"). The IANA ID ("America/Chicago")
/// is what's stored; these are only shown.
abstract final class TimeZoneNames {
  /// The US and Canada's zones by the name each goes by, in the order
  /// they're listed: Eastern to Hawaii, then Atlantic and Newfoundland,
  /// each with its main US city first and its main Canadian one next.
  static const Map<String, List<String>> _northAmerica = {
    'Eastern Time': [
      'America/New_York',
      'America/Toronto',
      'America/Detroit',
      'America/Indiana/Indianapolis',
      'America/Kentucky/Louisville',
      'America/Iqaluit',
      'America/Atikokan',
      'America/Indiana/Marengo',
      'America/Indiana/Petersburg',
      'America/Indiana/Vevay',
      'America/Indiana/Vincennes',
      'America/Indiana/Winamac',
      'America/Kentucky/Monticello',
      'America/Nipigon',
      'America/Pangnirtung',
      'America/Thunder_Bay',
    ],
    'Central Time': [
      'America/Chicago',
      'America/Winnipeg',
      'America/Regina',
      'America/Swift_Current',
      'America/Indiana/Knox',
      'America/Indiana/Tell_City',
      'America/Menominee',
      'America/North_Dakota/Beulah',
      'America/North_Dakota/Center',
      'America/North_Dakota/New_Salem',
      'America/Rainy_River',
      'America/Rankin_Inlet',
      'America/Resolute',
    ],
    'Mountain Time': [
      'America/Denver',
      'America/Edmonton',
      'America/Phoenix',
      'America/Boise',
      'America/Cambridge_Bay',
      'America/Creston',
      'America/Dawson',
      'America/Dawson_Creek',
      'America/Fort_Nelson',
      'America/Inuvik',
      'America/Whitehorse',
      'America/Yellowknife',
    ],
    'Pacific Time': ['America/Los_Angeles', 'America/Vancouver'],
    'Alaska Time': [
      'America/Anchorage',
      'America/Juneau',
      'America/Metlakatla',
      'America/Nome',
      'America/Sitka',
      'America/Yakutat',
    ],
    'Hawaii Time': ['Pacific/Honolulu'],
    'Hawaii-Aleutian Time': ['America/Adak'],
    'Atlantic Time': [
      'America/Puerto_Rico',
      'America/Halifax',
      'America/Blanc-Sablon',
      'America/Glace_Bay',
      'America/Goose_Bay',
      'America/Moncton',
    ],
    'Newfoundland Time': ['America/St_Johns'],
  };

  static final Map<String, String> _nameOf = {
    for (final MapEntry(key: name, value: zones) in _northAmerica.entries)
      for (final z in zones) z: name,
  };

  /// Where a zone's city is spelled other than its ID's.
  static const _cities = {
    'America/St_Johns': "St. John's",
    'America/Indiana/Indianapolis': 'Indianapolis',
    'America/Kentucky/Louisville': 'Louisville',
  };

  /// The regions whose zones are listed; the rest are old names and plain
  /// offsets (US/Central, Etc/GMT+5).
  static const _regions = {
    'Africa',
    'America',
    'Antarctica',
    'Asia',
    'Atlantic',
    'Australia',
    'Europe',
    'Indian',
    'Pacific',
  };

  /// Old names for zones listed under their current ones, left out so no
  /// place is listed twice.
  static const _oldNames = {
    'Africa/Asmera',
    'Africa/Timbuktu',
    'America/Atka',
    'America/Buenos_Aires',
    'America/Catamarca',
    'America/Cordoba',
    'America/Ensenada',
    'America/Fort_Wayne',
    'America/Indianapolis',
    'America/Jujuy',
    'America/Knox_IN',
    'America/Louisville',
    'America/Mendoza',
    'America/Montreal',
    'America/Porto_Acre',
    'America/Rosario',
    'America/Santa_Isabel',
    'America/Shiprock',
    'America/Virgin',
    'Antarctica/South_Pole',
    'Asia/Ashkhabad',
    'Asia/Calcutta',
    'Asia/Chungking',
    'Asia/Dacca',
    'Asia/Harbin',
    'Asia/Istanbul',
    'Asia/Kashgar',
    'Asia/Katmandu',
    'Asia/Macao',
    'Asia/Rangoon',
    'Asia/Saigon',
    'Asia/Tel_Aviv',
    'Asia/Thimbu',
    'Asia/Ujung_Pandang',
    'Asia/Ulan_Bator',
    'Atlantic/Faeroe',
    'Atlantic/Jan_Mayen',
    'Australia/ACT',
    'Australia/Canberra',
    'Australia/LHI',
    'Australia/NSW',
    'Australia/North',
    'Australia/Queensland',
    'Australia/South',
    'Australia/Tasmania',
    'Australia/Victoria',
    'Australia/West',
    'Australia/Yancowinna',
    'Europe/Belfast',
    'Europe/Kiev',
    'Europe/Nicosia',
    'Europe/Tiraspol',
    'Europe/Uzhgorod',
    'Europe/Zaporozhye',
    'Pacific/Enderbury',
    'Pacific/Johnston',
    'Pacific/Ponape',
    'Pacific/Samoa',
    'Pacific/Truk',
    'Pacific/Yap',
  };

  /// [zone]'s city: "Chicago", "Buenos Aires, Argentina", "Knox, Indiana".
  static String city(String zone) {
    final known = _cities[zone];
    if (known != null) return known;
    final parts = zone.split('/').map((p) => p.replaceAll('_', ' ')).toList();
    if (parts.length >= 3) return '${parts.last}, ${parts[parts.length - 2]}';
    return parts.last;
  }

  /// What [zone] is shown as: "Central Time (Chicago)" in the US and
  /// Canada, otherwise its city and its offset at [at] (now when null),
  /// "Berlin (GMT+1)", or "UTC (GMT)".
  static String label(String zone, {DateTime? at}) {
    final name = _nameOf[zone];
    if (name != null) return '$name (${city(zone)})';
    return '${city(zone)} (${gmt(ZonedTime.offsetAt(zone, at ?? DateTime.now()))})';
  }

  /// [offset] as "GMT", "GMT+1", "GMT-3:30", or "GMT+5:45".
  static String gmt(Duration offset) {
    if (offset == Duration.zero) return 'GMT';
    final minutes = offset.inMinutes.abs();
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final sign = offset.isNegative ? '-' : '+';
    return 'GMT$sign$hours${rest == 0 ? '' : ':${rest.toString().padLeft(2, '0')}'}';
  }

  /// [zones] in the order to list them: the US and Canada's first, then the
  /// rest by their offset at [at] (now when null) and city. Old names and
  /// plain offsets are left out, except any in [keep] (the zone a team or
  /// event already has), which is always listed.
  static List<String> ordered(
    Iterable<String> zones, {
    Iterable<String> keep = const [],
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final kept = keep.toSet();
    final all = {
      for (final z in [...zones, ...kept])
        if (kept.contains(z) || _listed(z)) z,
    };
    final first = [
      for (final group in _northAmerica.values)
        for (final z in group)
          if (all.contains(z)) z,
    ];
    final rest = all.difference(first.toSet()).toList()
      ..sort((a, b) {
        final byOffset = ZonedTime.offsetAt(
          a,
          now,
        ).compareTo(ZonedTime.offsetAt(b, now));
        return byOffset != 0 ? byOffset : city(a).compareTo(city(b));
      });
    return [...first, ...rest];
  }

  /// Whether [zone] matches what was typed: its name, city, or ID, so
  /// "central", "chicago", and "america/chi" all find America/Chicago.
  static bool matches(String zone, String query, {DateTime? at}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label(zone, at: at).toLowerCase().contains(q) ||
        zone.toLowerCase().contains(q.replaceAll(' ', '_'));
  }

  static bool _listed(String zone) =>
      zone == 'UTC' ||
      (zone.contains('/') &&
          _regions.contains(zone.split('/').first) &&
          !_oldNames.contains(zone));
}
