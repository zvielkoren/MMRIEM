import { Slot } from "expo-router";
import { Redirect, Stack } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { SplashScreen } from "@/components/SplashScreen";

export default function RootLayout() {
  const { loading, user } = useAuth();

  if (loading) {
    return <SplashScreen />;
  }

  if (!user) {
    return <Redirect href="/(auth)/login" />;
  }

  return <Slot />;
}
