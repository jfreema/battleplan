/// Analytics facade (ARCH §5.2 rule 8, §9). Event names come from ARCH §9;
/// parameters never include message content or personal data.
abstract interface class Analytics {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  Future<void> setUserId(String? uid);
}

class NoopAnalytics implements Analytics {
  const new();

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}

  @override
  Future<void> setUserId(String? uid) async {}
}
