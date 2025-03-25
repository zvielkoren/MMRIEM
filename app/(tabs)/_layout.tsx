import { Tabs } from "expo-router";
import { Calendar, ClipboardList, Users, Settings } from "lucide-react-native";
import { AuthGuard } from "@/components/AuthGuard";
import { useAuth } from "@/contexts/AuthContext";

export default function TabLayout() {
  const { userRole } = useAuth();

  return (
    <AuthGuard>
      <Tabs
        screenOptions={{
          headerShown: true,
          tabBarStyle: {
            backgroundColor: "#ffffff",
            borderTopColor: "#e5e5e5",
          },
          tabBarActiveTintColor: "#0066cc",
          tabBarInactiveTintColor: "#666666",
        }}
      >
        <Tabs.Screen
          name="index"
          options={{
            title: "יומן",
            headerTitle: "יומן",
            tabBarIcon: ({ color, size }) => (
              <Calendar size={size} color={color} />
            ),
          }}
        />
        <Tabs.Screen
          name="reports"
          options={{
            title: "דוחות",
            headerTitle: "דוחות",
            tabBarIcon: ({ color, size }) => (
              <ClipboardList size={size} color={color} />
            ),
          }}
        />
        {userRole === "admin" && (
          <Tabs.Screen
            name="staff"
            options={{
              title: "צוות",
              headerTitle: "ניהול צוות",
              tabBarIcon: ({ color, size }) => (
                <Users size={size} color={color} />
              ),
            }}
          />
        )}
        {(userRole === "admin" || userRole === "instructor") && (
          <Tabs.Screen
            name="settings"
            options={{
              title: "הגדרות",
              headerTitle: "הגדרות",
              tabBarIcon: ({ color, size }) => (
                <Settings size={size} color={color} />
              ),
            }}
          />
        )}
      </Tabs>
    </AuthGuard>
  );
}
