importScripts(
  "https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.x.x/firebase-messaging-compat.js"
);

firebase.initializeApp({
  // Copy your firebase config here
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icon.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
