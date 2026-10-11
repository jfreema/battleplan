import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Firebase Remote Config behind [RemoteConfig]. Fetches at most hourly and
/// never blocks launch: on any failure the defaults stay in place.
class FirebaseRemoteConfigService implements RemoteConfig {
  new(this._config);

  final FirebaseRemoteConfig _config;

  static const _minVersionKey = 'min_supported_version';

  @override
  Future<void> refresh() async {
    try {
      await _config.setDefaults(const {_minVersionKey: '0.0.0'});
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _config.fetchAndActivate();
    } on Object catch (e) {
      // Keep the defaults; never block launch on Remote Config.
      Log.warn('Remote Config fetch failed', e);
    }
  }

  @override
  String get minSupportedVersion => _config.getString(_minVersionKey);
}
