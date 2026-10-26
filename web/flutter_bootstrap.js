{{flutter_js}}
{{flutter_build_config}}

// Loads the app without Flutter's own service worker, which is deprecated
// and only unregisters itself. The web app lives under /app/ (D40) and the
// push worker, firebase-messaging-sw.js, is registered with the /app/ scope
// (ARCH §6.6); Flutter's worker would take over that scope and unregister it.
//
// The engine's fallback fonts (Roboto, the emoji, and Noto for other
// scripts) come from our own site, under /app/fonts/fallback/, instead of
// fonts.gstatic.com (ARCH §5.5): tools/build_hosting.sh puts them there.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: new URL('fonts/fallback/', document.baseURI).href,
  },
});
