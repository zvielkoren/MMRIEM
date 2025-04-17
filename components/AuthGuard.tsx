import React from "react";
import { useAuth } from "../contexts/AuthContext";
import { Redirect, useSegments } from "expo-router";
import { UserRole } from "@/types/roles";
import { View, Text, StyleSheet } from "react-native";
import { ActivityIndicator } from "react-native";

const protectedRoutes: Record<string, UserRole[]> = {
  "/(tabs)/staff": [UserRole.Admin, UserRole.Staff],
  "/(tabs)/reports": [UserRole.Admin, UserRole.Staff],
  "/(tabs)/profile": [UserRole.Admin, UserRole.Staff, UserRole.User],
  "/(tabs)/settings": [UserRole.Admin, UserRole.Staff, UserRole.User],
  "/(tabs)/calendar": [UserRole.Admin, UserRole.Staff, UserRole.User],
};

export const AuthGuard: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { user, loading, userRole, isOnline } = useAuth();
  const segments = useSegments();

  if (loading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#0000ff" />
      </View>
    );
  }

  if (!isOnline) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>אין חיבור לאינטרנט</Text>
      </View>
    );
  }

  // Check if the current route is protected
  const currentRoute = segments.join("/");
  const requiredRoles = protectedRoutes[currentRoute];

  // If the route is not in the protected routes list, allow access
  if (!requiredRoles) {
    return <>{children}</>;
  }

  // If user is not logged in, redirect to login
  if (!user) {
    return <Redirect href="/(auth)/login" />;
  }

  // If user is logged in but doesn't have the required role, redirect to unauthorized
  if (!userRole || !requiredRoles.includes(userRole)) {
    return <Redirect href="/unauthorized" />;
  }

  // If user has the required role, allow access
  return <>{children}</>;
};

export const getVisibleTabs = (userRole: UserRole | null): string[] => {
  if (!userRole) {
    return [];
  }

  const visibleTabs: string[] = [];

  for (const [route, roles] of Object.entries(protectedRoutes)) {
    if (roles.includes(userRole)) {
      visibleTabs.push(route);
    }
  }

  return visibleTabs;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#ffffff",
  },
  errorText: {
    fontSize: 18,
    color: "#ff0000",
    textAlign: "center",
  },
});
