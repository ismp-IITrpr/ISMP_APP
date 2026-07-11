importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCWLm3U7S5CsQyGOUEZVAfVV2ld63KQeJc",
  authDomain: "iit-ropar-ismp-app.firebaseapp.com",
  projectId: "iit-ropar-ismp-app",
  storageBucket: "iit-ropar-ismp-app.firebasestorage.app",
  messagingSenderId: "231730406983",
  appId: "1:231730406983:web:185e40ebf5b65451302e3a",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'ISMP Notification';
  const notificationBody = payload.notification?.body || '';
  const notificationOptions = {
    body: notificationBody,
    icon: '/favicon.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});