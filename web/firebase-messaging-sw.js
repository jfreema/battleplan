// Web push service worker (ARCH §6.5). The browser runs this in the
// background so notifications arrive even with the tab closed. Firebase's
// messaging SDK finds it at this exact path.
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

// Messages with a `notification` payload are shown by the SDK itself.
firebase.messaging();
