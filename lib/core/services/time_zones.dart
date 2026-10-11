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
