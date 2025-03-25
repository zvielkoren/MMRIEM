import { Stack } from "expo-router";
import { AuthGuard } from "@/components/AuthGuard";

export default function ProtectedLayout() {
  return (
    <AuthGuard>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack>
    </AuthGuard>
  );
}
