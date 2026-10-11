import 'package:battleplan/app/bootstrap.dart';
import 'package:battleplan/app/firebase_options_dev.dart';
import 'package:battleplan/core/env.dart';

/// Dev flavor: `app.getbattleplan.dev`, project battleplan-dev-ecce4.
/// Add --dart-define=USE_EMULATORS=true to run against the Emulator Suite.
void main() => bootstrap(
  flavor: AppFlavor.dev,
  cloudOptions: () => DefaultFirebaseOptions.currentPlatform,
);
