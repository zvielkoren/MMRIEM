import { Stack } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { Redirect } from "expo-router";

export default function AuthLayout() {
  const { user } = useAuth();

  // Redirect to calendar if already logged in
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
