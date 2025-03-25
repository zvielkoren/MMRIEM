import { AuthProvider } from "./contexts/AuthContext";
import { ExpoRoot } from "expo-router";
import { useEffect, useState } from "react";
import { View, ActivityIndicator, Text } from "react-native";
import {
  initializeDatabase,
  validateDatabaseStructure,
} from "./utils/dbTemplate";

let hasInitialized = false;

export default function App() {
  const [isInitializing, setIsInitializing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const ctx = require.context("./app");

  useEffect(() => {
    async function checkAndSetupDatabase() {
      try {
        if (!hasInitialized) {
          setIsInitializing(true);
          await initializeDatabase();
          hasInitialized = true;
          setIsInitializing(false);
        }
      } catch (err) {
        console.error("Database setup failed:", err);
        setError("Failed to initialize database");
        setIsInitializing(false);
      }
    }

    checkAndSetupDatabase();
  }, []);

  if (isInitializing) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color="#0066cc" />
        <Text>Initializing database...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View
        style={{
          flex: 1,
          justifyContent: "center",
          alignItems: "center",
          padding: 20,
        }}
      >
        <Text style={{ color: "red", textAlign: "center" }}>{error}</Text>
      </View>
    );
  }

  return (
    <AuthProvider>
      <ExpoRoot context={ctx} />
    </AuthProvider>
  );
}
