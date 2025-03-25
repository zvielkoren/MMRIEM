import { View, StyleSheet, FlatList } from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import { collection, query, getDocs } from "firebase/firestore";
import { db } from "@/config/firebase";
import { useState, useEffect } from "react";
import { ThemedText } from "@/components/ThemedText";
import { DBUser } from "@/utils/dbTemplate";
import { Users } from "lucide-react-native";

export default function StaffScreen() {
  const [users, setUsers] = useState<DBUser[]>([]);
  const { userRole } = useAuth();

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    const usersSnap = await getDocs(query(collection(db, "users")));
    const userData = usersSnap.docs.map(
      (doc) => ({ ...doc.data(), id: doc.id } as DBUser)
    );
    setUsers(userData);
  };

  const RoleLabel = ({ role }: { role: string }) => (
    <View
      style={[
        styles.roleTag,
        {
          backgroundColor:
            role === "admin"
              ? "#dc2626"
              : role === "instructor"
              ? "#2563eb"
              : "#4b5563",
        },
      ]}
    >
      <ThemedText style={styles.roleText}>{role}</ThemedText>
    </View>
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Users size={24} color="#333" />
        <ThemedText style={styles.title}>ניהול צוות</ThemedText>
      </View>

      <FlatList
        data={users}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.userCard}>
            <View>
              <ThemedText style={styles.userName}>{item.name}</ThemedText>
              <ThemedText style={styles.userEmail}>{item.email}</ThemedText>
            </View>
            <RoleLabel role={item.role} />
          </View>
        )}
      />
    </View>
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
  userCard: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  userName: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    color: "#333",
  },
  userEmail: {
    fontSize: 14,
    color: "#666",
    marginTop: 4,
  },
  roleTag: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  roleText: {
    color: "#fff",
    fontSize: 12,
    fontFamily: "Heebo-Bold",
  },
});
