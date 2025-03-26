import { Stack } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { SplashScreen } from "@/components/SplashScreen";
import { StatusBar } from "expo-status-bar";

export default function RootLayout() {
  const { loading } = useAuth();

  if (loading) {
    return <SplashScreen />;
  }

  return (
    <>
      <StatusBar style="auto" />
      <Stack
        screenOptions={{
          headerShown: false,
        }}
      >
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(tabs)" />
      </Stack>
    </>
  );
}
