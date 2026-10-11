import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Options for the local Emulator Suite. A `demo-` project ID tells the
/// emulators there's no real project behind it, so nothing can reach the
/// cloud. The keys are placeholders, not secrets.
const emulatorProjectId = 'demo-battleplan';

/// The native SDKs check the app ID's shape (`1:<number>:<platform>:<hex>`),
/// so each platform gets its own placeholder.
FirebaseOptions emulatorFirebaseOptions() {
  final platform = kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
          _ => 'android',
        };
  return FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForLocalEmulatorsOnly00000',
    appId: '1:123456789012:$platform:0123456789abcdef',
    messagingSenderId: '123456789012',
    projectId: emulatorProjectId,
    storageBucket: '$emulatorProjectId.appspot.com',
    authDomain: '$emulatorProjectId.firebaseapp.com',
    iosBundleId: 'app.getbattleplan.dev',
  );
}
