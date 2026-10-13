import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/app/services/device_calendar_adder.dart';
import 'package:battleplan/app/services/file_picker_chooser.dart';
import 'package:battleplan/app/services/flutter_time_zones.dart';
import 'package:battleplan/app/services/gal_photo_saver.dart';
import 'package:battleplan/app/services/image_picker_photo_picker.dart';
import 'package:battleplan/app/services/share_plus_sharer.dart';
import 'package:battleplan/app/services/url_launcher_link_opener.dart';
import 'package:battleplan/app/services/web_browser_info.dart';
import 'package:battleplan/app/services/web_photo_drops.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/photo_drops.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/data/functions_admin_repository.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/data/firebase_auth_repository.dart';
import 'package:battleplan/features/auth/data/firestore_user_repository.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/data/firestore_message_repository.dart';
import 'package:battleplan/features/chat/data/prefs_chat_queue_store.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/data/firestore_document_repository.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/data/firestore_group_repository.dart';
import 'package:battleplan/features/groups/data/functions_invite_repository.dart';
import 'package:battleplan/features/groups/data/functions_media_repository.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/data/fcm_push_repository.dart';
import 'package:battleplan/features/notifications/data/firestore_device_repository.dart';
import 'package:battleplan/features/notifications/data/firestore_notification_repository.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/data/firestore_player_repository.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/polls/data/firestore_poll_repository.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/data/firestore_safety_repository.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/data/firestore_event_repository.dart';
import 'package:battleplan/features/schedule/data/firestore_rsvp_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/data/shared_prefs_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one place repositories and services are constructed (ARCH §5.2 rule 4).
List<Override> buildOverrides({
  required AppEnv env,
  required String version,
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required FirebaseFunctions functions,
  required FirebaseStorage storage,
  required FirebaseMessaging? messaging,
  required SharedPreferencesWithCache prefs,
  required Analytics analytics,
  required CrashReporter crashReporter,
  required RemoteConfig remoteConfig,
}) => [
  appEnvProvider.overrideWithValue(env),
  appVersionProvider.overrideWithValue(version),
  analyticsProvider.overrideWithValue(analytics),
  crashReporterProvider.overrideWithValue(crashReporter),
  remoteConfigProvider.overrideWithValue(remoteConfig),
  photoPickerProvider.overrideWithValue(
    const LocationStrippingPhotoPicker(ImagePickerPhotoPicker()),
  ),
  linkOpenerProvider.overrideWithValue(const UrlLauncherLinkOpener()),
  timeZonesProvider.overrideWithValue(const FlutterTimeZones()),
  sharerProvider.overrideWithValue(const SharePlusSharer()),
  calendarAdderProvider.overrideWithValue(const DeviceCalendarAdder()),
  fileChooserProvider.overrideWithValue(const FilePickerChooser()),
  linkServiceProvider.overrideWithValue(LinkService.forEnv(isProd: env.isProd)),
  browserInfoProvider.overrideWithValue(
    kIsWeb ? WebBrowserInfo() : const PlainBrowserInfo(),
  ),
  photoSaverProvider.overrideWithValue(const GalPhotoSaver()),
  photoDropsProvider.overrideWithValue(
    kIsWeb ? const WebPhotoDrops() : const NoPhotoDrops(),
  ),
  playerRepositoryProvider.overrideWithValue(
    FirestorePlayerRepository(firestore, functions),
  ),
  safetyRepositoryProvider.overrideWithValue(
    FirestoreSafetyRepository(firestore, functions),
  ),
  messageRepositoryProvider.overrideWithValue(
    FirestoreMessageRepository(firestore, storage, functions),
  ),
  chatQueueStoreProvider.overrideWithValue(PrefsChatQueueStore(prefs)),
  pollRepositoryProvider.overrideWithValue(
    FirestorePollRepository(firestore, functions),
  ),
  documentRepositoryProvider.overrideWithValue(
    FirestoreDocumentRepository(firestore, storage),
  ),
  eventRepositoryProvider.overrideWithValue(
    FirestoreEventRepository(firestore, functions),
  ),
  rsvpRepositoryProvider.overrideWithValue(FirestoreRsvpRepository(firestore)),
  inviteRepositoryProvider.overrideWithValue(
    FunctionsInviteRepository(functions),
  ),
  mediaRepositoryProvider.overrideWithValue(
    FunctionsMediaRepository(functions),
  ),
  adminRepositoryProvider.overrideWithValue(
    FunctionsAdminRepository(firestore, functions),
  ),
  authRepositoryProvider.overrideWithValue(
    FirebaseAuthRepository(
      auth,
      functions,
      links: LinkService.forEnv(isProd: env.isProd),
    ),
  ),
  userRepositoryProvider.overrideWithValue(
    FirestoreUserRepository(firestore, functions, storage),
  ),
  groupRepositoryProvider.overrideWithValue(
    FirestoreGroupRepository(
      firestore,
      functions,
      storage,
      currentUid: () => auth.currentUser?.uid,
    ),
  ),
  memberRepositoryProvider.overrideWithValue(
    FirestoreMemberRepository(firestore, functions),
  ),
  pushRepositoryProvider.overrideWithValue(
    messaging == null
        ? const UnavailablePushRepository()
        : FcmPushRepository(messaging),
  ),
  deviceRepositoryProvider.overrideWithValue(
    FirestoreDeviceRepository(firestore),
  ),
  notificationRepositoryProvider.overrideWithValue(
    FirestoreNotificationRepository(firestore),
  ),
  deviceAppVersionProvider.overrideWithValue(version),
  localPrefsRepositoryProvider.overrideWithValue(SharedPrefsRepository(prefs)),
];
