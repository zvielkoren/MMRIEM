import { Stack } from "expo-router";
import { AuthGuard } from "@/components/AuthGuard";

export default function ProtectedLayout() {
  return (
    <AuthGuard>
      <Stack
        screenOptions={{
          headerShown: false,
          animation: "fade",
        }}
        initialRouteName="(tabs)"
      >
        <Stack.Screen
          name="(tabs)"
          options={{
            headerShown: false,
            gestureEnabled: false,
          }}
        />
      </Stack>
    </AuthGuard>
  );
}
