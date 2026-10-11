import 'package:battleplan/app/bootstrap.dart';
import 'package:battleplan/app/firebase_options_prod.dart';
import 'package:battleplan/core/env.dart';

/// Prod flavor: `app.getbattleplan`, project battleplan-prod.
void main() => bootstrap(
  flavor: AppFlavor.prod,
  cloudOptions: () => DefaultFirebaseOptions.currentPlatform,
);
