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

export default function TabLayout() {
  const { userRole, user } = useAuth();
  const { isDark } = useTheme();

  // If not logged in, redirect to login
  if (!user) {
    return <Redirect href="/(auth)/login" />;
  }

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
      <Tabs.Screen
        name="profile"
        options={{
          title: "פרופיל",
          tabBarIcon: ({ color, size }) => (
            <UserCircle size={size} color={color} />
          ),
        }}
      />

      <Tabs.Screen
        name="index"
        options={{
          title: "יומן",
          tabBarIcon: ({ color, size }) => (
            <Calendar size={size} color={color} />
          ),
        }}
      />

      {userRole === "admin" && (
        <Tabs.Screen
          name="reports"
          options={{
            title: "דוחות",
            tabBarIcon: ({ color, size }) => (
              <ClipboardList size={size} color={color} />
            ),
          }}
        />
      )}

      {userRole === "admin" && (
        <Tabs.Screen
          name="staff"
          options={{
            title: "צוות",
            tabBarIcon: ({ color, size }) => (
              <Users size={size} color={color} />
            ),
          }}
        />
      )}

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
