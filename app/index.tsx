import { Redirect } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";

export default function Index() {
  const { user } = useAuth();

  // Always redirect to login if no user, or to calendar if logged in
  return <Redirect href={user ? "/(tabs)/calendar" : "/(auth)/login"} />;
}
