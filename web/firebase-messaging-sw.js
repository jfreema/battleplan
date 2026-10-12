// Web push service worker (ARCH §6.5). The browser runs this in the
// background so notifications arrive even with the tab closed. The web app
// is under /app/ (D40), so this is served at /app/firebase-messaging-sw.js
// and the app registers it with the /app/ scope (FcmPushRepository passes
// its path to getToken; Firebase's default path is the domain root).
//
// The config is the dev project's web app (lib/app/firebase_options_dev.dart).
// Prod gets its own when prod hosting is set up (roadmap task 116). These
// values identify the project; they aren't secrets.
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD51q1vNPHWfcuQDKm4F6uMioCw26sFb5k',
  appId: '1:814215990622:web:3310d0ee6e5209729f13cf',
  messagingSenderId: '814215990622',
  projectId: 'battleplan-dev-ecce4',
  storageBucket: 'battleplan-dev-ecce4.firebasestorage.app',
});

// A tap opens the app at the notification's route (NOTIF-6). The website
// shares this origin (D40), so the SDK's own click handler, which focuses
// any same-origin tab without navigating it, could bring up a website page
// instead. This runs first: it uses an app tab (inside this worker's /app/
// scope) and opens the route there, or opens a new tab.
self.addEventListener('notificationclick', (event) => {
  const msg = event.notification.data && event.notification.data.FCM_MSG;
  const link = msg && ((msg.fcmOptions && msg.fcmOptions.link) ||
    (msg.notification && msg.notification.click_action));
  if (!link) return;
  event.stopImmediatePropagation();
  event.notification.close();
  event.waitUntil((async () => {
    const url = new URL(link, self.location.href).href;
    const windows = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    const app = windows.find((w) => w.url.startsWith(self.registration.scope));
    if (!app) return clients.openWindow(url);
    await app.focus();
    return app.navigate(url).catch(() => clients.openWindow(url));
  })());
});

// Messages with a `notification` payload are shown by the SDK itself.
firebase.messaging();
