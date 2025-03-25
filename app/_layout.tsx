import { Stack } from "expo-router";
import { useEffect } from "react";
import { isFirebaseInitialized } from "../config/firebase";

export default function RootLayout() {
  useEffect(() => {
    // Verify Firebase initialization on app start
    if (!isFirebaseInitialized()) {
      console.error("Firebase not initialized!");
    }
  }, []);

  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: "#f4511e",
        },
        headerTintColor: "#fff",
        headerTitleStyle: {
          fontWeight: "bold",
        },
      }}
    />
  );
}
