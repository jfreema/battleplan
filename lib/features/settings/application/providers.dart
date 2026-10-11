import 'package:battleplan/core/constants.g.dart';
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
  ThemePreference build() =>
      ref.watch(localPrefsRepositoryProvider).themePreference;

  Future<void> set(ThemePreference value) async {
    state = value;
    await ref.read(localPrefsRepositoryProvider).setThemePreference(value);
  }
}
