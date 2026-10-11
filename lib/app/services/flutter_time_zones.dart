import 'package:battleplan/core/services/time_zones.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// `flutter_timezone` behind [TimeZones].
class FlutterTimeZones implements TimeZones {
  const new();

  @override
  Future<String> deviceTimeZone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      return 'America/Chicago';
    }
  }

  @override
  Future<List<String>> available() async {
    try {
      final zones = await FlutterTimezone.getAvailableTimezones();
      return [for (final z in zones) z.identifier]..sort();
    } on Object {
      return [await deviceTimeZone()];
    }
  }
}
