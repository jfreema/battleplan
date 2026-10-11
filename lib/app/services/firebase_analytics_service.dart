import 'package:battleplan/core/services/analytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Google Analytics for Firebase, with no advertising IDs (LEGAL-2).
class FirebaseAnalyticsService implements Analytics {
  new(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
