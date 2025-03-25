import {
  View,
  StyleSheet,
  Switch,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import { useState } from "react";
import { ThemedText } from "@/components/ThemedText";
import {
  Settings as SettingsIcon,
  Bell,
  Moon,
  LogOut,
} from "lucide-react-native";
import { auth } from "@/config/firebase";
import { router } from "expo-router";

export default function SettingsScreen() {
  const { userRole, userData } = useAuth();
  const [notifications, setNotifications] = useState(
    userData?.settings?.notifications ?? true
  );
  const [darkMode, setDarkMode] = useState(false);

  const handleLogout = async () => {
    await auth.signOut();
    router.replace("/(auth)/login");
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <SettingsIcon size={24} color="#333" />
        <ThemedText style={styles.title}>הגדרות</ThemedText>
      </View>

      <View style={styles.section}>
        <ThemedText style={styles.sectionTitle}>כללי</ThemedText>

        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Bell size={20} color="#666" />
            <ThemedText style={styles.settingText}>התראות</ThemedText>
          </View>
          <Switch value={notifications} onValueChange={setNotifications} />
        </View>

        <View style={styles.settingItem}>
          <View style={styles.settingLeft}>
            <Moon size={20} color="#666" />
            <ThemedText style={styles.settingText}>מצב כהה</ThemedText>
          </View>
          <Switch value={darkMode} onValueChange={setDarkMode} />
        </View>
      </View>

      <View style={styles.section}>
        <ThemedText style={styles.sectionTitle}>חשבון</ThemedText>
        <ThemedText style={styles.userInfo}>
          {userData?.name} | {userRole}
        </ThemedText>
        <ThemedText style={styles.email}>{userData?.email}</ThemedText>
      </View>

      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <LogOut size={20} color="#dc2626" />
        <ThemedText style={styles.logoutText}>התנתק</ThemedText>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
    padding: 16,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontFamily: "Heebo-Bold",
    color: "#333",
  },
  section: {
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: "Heebo-Bold",
    color: "#333",
    marginBottom: 16,
  },
  settingItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#f0f0f0",
  },
  settingLeft: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  settingText: {
    fontSize: 16,
    color: "#333",
  },
  userInfo: {
    fontSize: 16,
    color: "#333",
    fontFamily: "Heebo-Bold",
  },
  email: {
    fontSize: 14,
    color: "#666",
    marginTop: 4,
  },
  logoutButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    padding: 16,
    backgroundColor: "#fee2e2",
    borderRadius: 12,
    justifyContent: "center",
    marginTop: 24,
  },
  logoutText: {
    color: "#dc2626",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
});
