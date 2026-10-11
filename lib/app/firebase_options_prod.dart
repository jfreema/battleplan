// Placeholder until `flutterfire configure` overwrites this file with the
// real config for battleplan-prod. See docs/DEVELOPMENT.md.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'No Firebase config for battleplan-prod yet. Run the app with '
    '--dart-define=USE_EMULATORS=true, or run flutterfire configure.',
  );
}
