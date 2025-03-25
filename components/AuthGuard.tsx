import { useRouter } from "expo-router";
import React, { useEffect } from "react";
import { useAuth } from "../contexts/AuthContext";
import { View, ActivityIndicator } from "react-native";

export const AuthGuard: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.replace("/login");
    }
  }, [user, loading]);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return user ? <>{children}</> : null;
};
