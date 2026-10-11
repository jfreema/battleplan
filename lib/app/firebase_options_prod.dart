// Firebase config for battleplan-prod, registered with `firebase apps:create`
// (iOS and Android app ID app.getbattleplan). These values identify the project;
// they aren't secrets. Security comes from rules and App Check.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  /// The options for the platform the app is running on.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ios,
      TargetPlatform.android => android,
      _ => throw UnsupportedError('Battleplan runs on iOS, Android, and web.'),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC2n-Z1n3z_D0RtAOfEiPzZ1uE6p69OQRQ',
    appId: '1:628123687470:web:5d93d89461b02b9fe85dbf',
    messagingSenderId: '628123687470',
    projectId: 'battleplan-prod',
    storageBucket: 'battleplan-prod.firebasestorage.app',
    authDomain: 'battleplan-prod.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOKHxobTrFyJv3YBx4uv4Wy-u6ndG02RI',
    appId: '1:628123687470:ios:8dee8cfc2cca397ae85dbf',
    messagingSenderId: '628123687470',
    projectId: 'battleplan-prod',
    storageBucket: 'battleplan-prod.firebasestorage.app',
    iosBundleId: 'app.getbattleplan',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsIls7XnLDcEcfG9X6N1pRsr78v6VV2f0',
    appId: '1:628123687470:android:020d78b0253aa1c4e85dbf',
    messagingSenderId: '628123687470',
    projectId: 'battleplan-prod',
    storageBucket: 'battleplan-prod.firebasestorage.app',
  );
}
