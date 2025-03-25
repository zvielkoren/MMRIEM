import { useEffect } from "react";
import { Redirect, Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { I18nManager } from "react-native";
import { useFrameworkReady } from "@/hooks/useFrameworkReady";
import { AuthProvider } from "@/contexts/AuthContext";
import { useAuth } from "@/contexts/AuthContext";

I18nManager.allowRTL(true);
I18nManager.forceRTL(true);

function RootLayoutNav() {
  const { user, loading } = useAuth();

  if (loading) {
    return null;
  }

  if (!user) {
    return <Redirect href="/login" />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="login" options={{ headerShown: false }} />
      <Stack.Screen name="(protected)" options={{ headerShown: false }} />
    </Stack>
  );
}

export default function RootLayout() {
  useFrameworkReady();

  useEffect(() => {
    window.frameworkReady?.();
  }, []);

  return (
    <AuthProvider>
      <RootLayoutNav />
      <StatusBar style="auto" />
    </AuthProvider>
  );
}
