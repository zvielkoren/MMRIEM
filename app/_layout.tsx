import { Stack, useRouter, useSegments } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { useEffect } from "react";

export default function RootLayout() {
  const { loading, user } = useAuth();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (!loading) {
      // Force redirect to login if not authenticated
      if (!user) {
        router.replace("/(auth)/login");
        return;
      }

      // Redirect authenticated users from auth pages to main app
      const inAuthGroup = segments[0] === "(auth)";
      if (user && inAuthGroup) {
        router.replace("/profile");
      }
    }
  }, [user, loading]);

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(auth)" />
      <Stack.Screen name="(tabs)" />
    </Stack>
  );
}
