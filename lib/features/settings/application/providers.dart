import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
LocalPrefsRepository localPrefsRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// System, light, or dark (SPEC SET-2). Applies instantly and is remembered.
@Riverpod(keepAlive: true)
class ThemePreferenceController extends _$ThemePreferenceController {
  @override
  ThemePreference build() {
    // The account's setting follows the person to new devices (SET-2): when
    // the profile arrives or changes, it wins over this device's copy.
    ref.listen(myProfileProvider, (_, next) {
      final synced = next.value?.themeMode;
      if (synced != null && synced != state) unawaited(_saveLocal(synced));
    });
    return ref.watch(localPrefsRepositoryProvider).themePreference;
  }

  Future<void> _saveLocal(ThemePreference value) async {
    state = value;
    await ref.read(localPrefsRepositoryProvider).setThemePreference(value);
  }

  /// Applies at once, is remembered on this device, and syncs to the account.
  Future<void> set(ThemePreference value) async {
    await _saveLocal(value);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    try {
      await ref.read(userRepositoryProvider).setThemeMode(uid, value);
    } on Object catch (e) {
      Log.warn('Theme sync failed', e);
    }
  }
}
