import { Stack, useRouter, useSegments } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { useEffect } from "react";
import { View, ActivityIndicator } from "react-native";

export default function RootLayout() {
  const { loading, user } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      if (!loading) {
        if (!user) {
          // Force redirect to login
          await router.replace({
            pathname: "/(auth)/login",
            params: { refresh: Date.now() },
          });
        } else if (segments[0] === "(auth)") {
          // Force redirect to tabs if authenticated
          await router.replace({
            pathname: "/(tabs)",
            params: { refresh: Date.now() },
          });
        }
      }
    };

    checkAuth();
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
      <Stack.Screen name="(auth)" options={{ animation: "none" }} />
      <Stack.Screen name="(tabs)" options={{ animation: "none" }} />
    </Stack>
  );
}
