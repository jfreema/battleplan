// The platform settings behind the Privacy Policy's "Our analytics run
// without advertising IDs" (LEGAL-2). They live in native config files the
// Dart tests can't otherwise reach, so these check the files themselves.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analytics without advertising IDs (Privacy Policy, LEGAL-2)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');

    for (final name in [
      'google_analytics_adid_collection_enabled',
      'google_analytics_default_allow_ad_storage',
      'google_analytics_default_allow_ad_user_data',
      'google_analytics_default_allow_ad_personalization_signals',
    ]) {
      test('Android sets $name off', () {
        expect(
          manifest,
          contains('<meta-data android:name="$name" android:value="false" />'),
        );
      });
    }

    for (final permission in [
      'com.google.android.gms.permission.AD_ID',
      'android.permission.ACCESS_ADSERVICES_AD_ID',
      'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
    ]) {
      test('Android removes $permission, which analytics merges in', () {
        expect(manifest, contains('xmlns:tools='));
        expect(
          manifest,
          contains(
            '<uses-permission android:name="$permission" '
            'tools:node="remove" />',
          ),
        );
      });
    }

    final plist = File('ios/Runner/Info.plist')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');

    test('iOS never asks to track, so it gets no IDFA', () {
      // Without this key the app can't show the App Tracking Transparency
      // prompt, and iOS hands every app that hasn't asked an all-zero IDFA.
      expect(plist, isNot(contains('<key>NSUserTrackingUsageDescription')));
    });

    for (final key in [
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE',
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA',
      'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS',
    ]) {
      test('iOS denies $key from the first launch', () {
        expect(plist, contains('<key>$key</key> <false/>'));
      });
    }
  });
}
