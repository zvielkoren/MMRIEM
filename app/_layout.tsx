import { Stack } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { SplashScreen } from "@/components/SplashScreen";

export default function RootLayout() {
  const { loading, user } = useAuth();

  if (loading) {
    return <SplashScreen />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      {!user ? (
        <Stack.Screen
          name="(auth)/login"
          options={{
            title: "התחברות",
          }}
        />
      ) : (
        <Stack.Screen
          name="/index"
          options={{
            title: "יומן",
          }}
        />
      )}
    </Stack>
  );
}
