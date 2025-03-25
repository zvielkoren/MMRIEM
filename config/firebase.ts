import { initializeApp, getApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";
import { getFunctions } from "firebase/functions";
import { getMessaging, isSupported } from "firebase/messaging";

if (!process.env.EXPO_PUBLIC_FIREBASE_API_KEY) {
  console.error("Firebase API Key is missing!");
}

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
};

console.log("Firebase Config:", {
  ...firebaseConfig,
  apiKey: firebaseConfig.apiKey ? "********************" : "MISSING",
});

// Initialize Firebase
let app;
if (!getApps().length) {
  app = initializeApp(firebaseConfig);
} else {
  app = getApp();
}

export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);
export const functions = getFunctions(app);

// Initialize messaging only if supported (web)
export const initializeMessaging = async () => {
  if (await isSupported()) {
    return getMessaging(app);
  }
  return null;
};

export const isFirebaseInitialized = () => getApps().length > 0;
