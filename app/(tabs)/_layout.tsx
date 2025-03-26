import { Tabs } from "expo-router";
import {
  Calendar,
  ClipboardList,
  Users,
  Settings,
  UserCircle,
} from "lucide-react-native";
import { AuthGuard } from "@/components/AuthGuard";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";

export default function TabLayout() {
  const { userRole } = useAuth();
  const { isDark } = useTheme();

  const screenOptions = {
    headerShown: true,
    tabBarStyle: {
      backgroundColor: isDark ? "#1f2937" : "#ffffff",
      borderTopColor: isDark ? "#374151" : "#e5e5e5",
    },
    tabBarActiveTintColor: isDark ? "#3b82f6" : "#0066cc",
    tabBarInactiveTintColor: isDark ? "#9ca3af" : "#666666",
    headerStyle: {
      backgroundColor: isDark ? "#1f2937" : "#ffffff",
    },
    headerTintColor: isDark ? "#ffffff" : "#333333",
  };

  // Define tab visibility based on role
  const tabVisibility = {
    index: true, // Calendar always visible
    reports: userRole === "admin" || userRole === "instructor",
    staff: userRole === "admin",
    settings: true,
    profile: true,
  };

  // Remove filtered tabs entirely instead of just hiding them
  const availableTabs = Object.entries(tabVisibility)
    .filter(([_, isVisible]) => isVisible)
    .map(([name]) => name);

  const defaultScreenOptions = {
    index: {
      title: "יומן",
      headerTitle: "יומן",
      tabBarIcon: ({ color, size }) => <Calendar size={size} color={color} />,
    },
    reports: {
      title: "דוחות",
      headerTitle: "דוחות פעילות",
      tabBarIcon: ({ color, size }) => (
        <ClipboardList size={size} color={color} />
      ),
    },
    staff: {
      title: "צוות",
      headerTitle: "ניהול צוות",
      tabBarIcon: ({ color, size }) => <Users size={size} color={color} />,
    },
    settings: {
      title: "הגדרות",
      headerTitle: "הגדרות",
      tabBarIcon: ({ color, size }) => <Settings size={size} color={color} />,
    },
    profile: {
      title: "פרופיל",
      headerTitle: "פרופיל",
      tabBarIcon: ({ color, size }) => <UserCircle size={size} color={color} />,
    },
  };

  return (
    <AuthGuard>
      <Tabs screenOptions={screenOptions}>
        {availableTabs.map((name) => (
          <Tabs.Screen
            key={name}
            name={name}
            options={{
              ...defaultScreenOptions[name],
              href: name,
            }}
          />
        ))}
      </Tabs>
    </AuthGuard>
  );
}
