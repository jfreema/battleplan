// Firebase config for battleplan-dev-ecce4, registered with `firebase apps:create`
// (iOS and Android app ID app.getbattleplan.dev). These values identify the project;
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
    apiKey: 'AIzaSyD51q1vNPHWfcuQDKm4F6uMioCw26sFb5k',
    appId: '1:814215990622:web:3310d0ee6e5209729f13cf',
    messagingSenderId: '814215990622',
    projectId: 'battleplan-dev-ecce4',
    storageBucket: 'battleplan-dev-ecce4.firebasestorage.app',
    authDomain: 'battleplan-dev-ecce4.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCafMsUIqk8oNpk-6dXyylTcLJL2JULtss',
    appId: '1:814215990622:ios:280d7d7f0ed26ab89f13cf',
    messagingSenderId: '814215990622',
    projectId: 'battleplan-dev-ecce4',
    storageBucket: 'battleplan-dev-ecce4.firebasestorage.app',
    iosBundleId: 'app.getbattleplan.dev',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB16Kn4YRJmAZkhRqaJTB0hAzzAzmKDXp4',
    appId: '1:814215990622:android:e7acfa294cb3e6fd9f13cf',
    messagingSenderId: '814215990622',
    projectId: 'battleplan-dev-ecce4',
    storageBucket: 'battleplan-dev-ecce4.firebasestorage.app',
  );
}
