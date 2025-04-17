import { Tabs, Redirect } from "expo-router";
import {
  Calendar,
  ClipboardList,
  Users,
  Settings,
  UserCircle,
} from "lucide-react-native";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { UserRole } from "@/types/roles";
import { useEffect } from "react";
import { ActivityIndicator, View } from "react-native";

const FEATURE_FLAGS = {
  CALENDAR_ENABLED: false,
};

export default function TabLayout() {
  const { userRole, user, refreshAuth, loading } = useAuth();
  const { isDark } = useTheme();

  useEffect(() => {
    const interval = setInterval(refreshAuth, 5 * 60 * 1000); // Every 5 minutes
    return () => clearInterval(interval);
  }, []);

  // Show loading state
  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator
          size="large"
          color={isDark ? "#3b82f6" : "#0066cc"}
        />
      </View>
    );
  }

  // If not logged in or no role, redirect to login
  if (!user || !userRole) {
    return <Redirect href="/(auth)/login" />;
  }

  const isStaffOrAdmin =
    userRole === UserRole.Admin || userRole === UserRole.Staff;

  return (
    <Tabs
      screenOptions={{
        headerShown: true,
        tabBarStyle: {
          backgroundColor: isDark ? "#1f2937" : "#ffffff",
          borderTopColor: isDark ? "#374151" : "#e5e5e5",
        },
        tabBarActiveTintColor: isDark ? "#3b82f6" : "#0066cc",
        tabBarInactiveTintColor: isDark ? "#9ca3af" : "#666666",
      }}
    >
      {/* Calendar - Hidden until feature is enabled */}
      <Tabs.Screen
        name="index"
        options={{
          title: "לוח אירועים",
          tabBarIcon: ({ color, size }) => (
            <Calendar size={size} color={color} />
          ),
          href: FEATURE_FLAGS.CALENDAR_ENABLED ? null : null,
        }}
      />

      {/* Profile - Available to all users */}
      <Tabs.Screen
        name="profile"
        options={{
          title: "פרופיל",
          tabBarIcon: ({ color, size }) => (
            <UserCircle size={size} color={color} />
          ),
        }}
      />

      {/* Staff management - Only for staff and admin */}
      <Tabs.Screen
        name="staff"
        options={{
          title: "צוות",
          tabBarIcon: ({ color, size }) => <Users size={size} color={color} />,
          href: isStaffOrAdmin ? null : null,
        }}
      />

      {/* Reports - Only for staff and admin */}
      <Tabs.Screen
        name="reports"
        options={{
          title: "דוחות",
          tabBarIcon: ({ color, size }) => (
            <ClipboardList size={size} color={color} />
          ),
          href: isStaffOrAdmin ? null : null,
        }}
      />

      {/* Settings - Available to all users */}
      <Tabs.Screen
        name="settings"
        options={{
          title: "הגדרות",
          tabBarIcon: ({ color, size }) => (
            <Settings size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
