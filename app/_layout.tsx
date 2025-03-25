import { Stack, useRouter, useSegments } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { useEffect } from "react";
import { View, ActivityIndicator } from "react-native";

export default function RootLayout() {
  const { loading, user } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (!loading) {
      // Force immediate redirect based on auth state
      if (!user) {
        router.replace("/(auth)/login");
      } else if (segments[0] === "(auth)") {
        router.replace("/profile");
      }
    }
  }, [user, loading, segments]);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color="#0066cc" />
      </View>
    );
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(auth)" />
      <Stack.Screen name="(tabs)" />
    </Stack>
  );
}
