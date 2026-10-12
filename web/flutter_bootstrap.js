{{flutter_js}}
{{flutter_build_config}}

// Loads the app without Flutter's own service worker, which is deprecated
// and only unregisters itself. The web app lives under /app/ (D40) and the
// push worker, firebase-messaging-sw.js, is registered with the /app/ scope
// (ARCH §6.6); Flutter's worker would take over that scope and unregister it.
_flutter.loader.load();
