import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import {
  getAuth,
  signInWithPhoneNumber,
  RecaptchaVerifier,
} from "firebase/auth";
import { Platform } from "react-native";

const firebaseConfig = {
  apiKey: "AIzaSyCn3WB_e2oOFmJGUDITBfLd-4_Pg9H6eQs",
  authDomain: "mamrimegolan.firebaseapp.com",
  projectId: "mamrimegolan",
  storageBucket: "mamrimegolan.firebasestorage.app",
  messagingSenderId: "544706941106",
  appId: "1:544706941106:web:3c49cb49d4e3d90af7f9ab",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

export const phoneAuth = {
  sendVerificationCode: async (phoneNumber: string) => {
    if (Platform.OS !== "web") {
      throw new Error("Phone authentication is only supported on web platform");
    }

    try {
      // Create reCAPTCHA verifier
      const recaptchaContainer = document.createElement("div");
      recaptchaContainer.id = "recaptcha-container";
      document.body.appendChild(recaptchaContainer);

      const recaptchaVerifier = new RecaptchaVerifier(
        auth,
        "recaptcha-container",
        {
          size: "invisible",
          callback: () => {
            console.log("reCAPTCHA verified");
          },
        }
      );

      // Send verification code
      const confirmationResult = await signInWithPhoneNumber(
        auth,
        phoneNumber,
        recaptchaVerifier
      );

      // Clean up
      const container = document.getElementById("recaptcha-container");
      if (container) container.remove();

      return confirmationResult;
    } catch (error) {
      console.error("Phone auth error:", error);
      throw error;
    }
  },
};

export { auth, db };
