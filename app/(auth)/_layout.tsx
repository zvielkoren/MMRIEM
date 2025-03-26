import { Stack } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { Redirect } from "expo-router";

export default function AuthLayout() {
  const { user } = useAuth();

  // If logged in, redirect to calendar
  if (user) {
    return <Redirect href="/(tabs)/calendar" />;
  }

  return (
    <Stack
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="login" />
      <Stack.Screen name="register" />
    </Stack>
  );
}
