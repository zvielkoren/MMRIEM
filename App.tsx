import { ThemeProvider } from "./contexts/ThemeContext";
import { AuthProvider } from "./contexts/AuthContext";
import { ExpoRoot } from "expo-router";
import { useEffect } from "react";
import { View } from "react-native";
import { SplashScreen } from "@/components/SplashScreen";

export default function App() {
  const ctx = require.context("./app");

  return (
    <ThemeProvider>
      <AuthProvider>
        <ExpoRoot context={ctx} fallback={() => <SplashScreen />} />
      </AuthProvider>
    </ThemeProvider>
  );
}
