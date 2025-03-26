import {
  View,
  StyleSheet,
  Switch,
  ScrollView,
  TouchableOpacity,
  Alert,
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
import {
  collection,
  query,
  where,
  getDocs,
  deleteDoc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";
import { signOut } from "firebase/auth";

export default function SettingsScreen() {
  const { user, userRole, userData } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const themed = getThemedStyles(isDark);
  const [notifications, setNotifications] = useState(
    userData?.settings?.notifications ?? true
  );
  const [darkMode, setDarkMode] = useState(false);

  const handleLogout = async () => {
    Alert.alert(
      "יציאה מהמערכת",
      "האם אתה בטוח שברצונך להתנתק?",
      [
        { text: "ביטול", style: "cancel" },
        {
          text: "יציאה",
          style: "destructive",
          onPress: async () => {
            try {
              await signOut(auth);
              router.replace("/(auth)/login");
            } catch (error) {
              console.error("Error during logout:", error);
              Alert.alert("שגיאה", "אירעה שגיאה בעת ההתנתקות");
            }
          },
        },
      ],
      { cancelable: true }
    );
  };

  return (
    <ScrollView style={[styles.container, themed.contentBackground]}>
      <View style={[styles.header, themed.border]}>
        <SettingsIcon size={24} color={themed.theme.text} />
        <ThemedText style={[styles.title, themed.text]}>הגדרות</ThemedText>
      </View>

      <View style={[styles.section, themed.surfaceBackground]}>
        <ThemedText style={[styles.sectionTitle, themed.text]}>כללי</ThemedText>

        <View
          style={[
            styles.settingItem,
            { borderBottomColor: themed.theme.border },
          ]}
        >
          <View style={styles.settingLeft}>
            <Bell size={20} color={themed.theme.textSecondary} />
            <ThemedText style={[styles.settingText, themed.text]}>
              התראות
            </ThemedText>
          </View>
          <Switch
            value={notifications}
            onValueChange={setNotifications}
            trackColor={{
              false: themed.theme.border,
              true: themed.theme.primary,
            }}
          />
        </View>

        <View
          style={[
            styles.settingItem,
            { borderBottomColor: themed.theme.border },
          ]}
        >
          <View style={styles.settingLeft}>
            <Moon size={20} color={themed.theme.textSecondary} />
            <ThemedText style={[styles.settingText, themed.text]}>
              מצב כהה
            </ThemedText>
          </View>
          <Switch
            value={isDark}
            onValueChange={toggleTheme}
            trackColor={{
              false: themed.theme.border,
              true: themed.theme.primary,
            }}
          />
        </View>
      </View>

      <View style={styles.section}>
        <ThemedText style={styles.sectionTitle}>חשבון</ThemedText>
        <ThemedText style={styles.userInfo}>
          {userData?.name} | {userRole}
        </ThemedText>
        <ThemedText style={styles.email}>{userData?.email}</ThemedText>
      </View>

      <TouchableOpacity
        style={styles.logoutButton}
        onPress={handleLogout}
        activeOpacity={0.7}
      >
        <LogOut size={20} color="#dc2626" />
        <ThemedText style={styles.logoutText}>התנתק מהמערכת</ThemedText>
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
    marginBottom: 32,
  },
  logoutText: {
    color: "#dc2626",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
});
