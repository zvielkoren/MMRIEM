import {
  View,
  StyleSheet,
  FlatList,
  Alert,
  Modal,
  TouchableOpacity,
  ActivityIndicator,
} from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import {
  collection,
  query,
  getDocs,
  updateDoc,
  doc,
  where,
  addDoc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { useState, useEffect } from "react";
import { ThemedText } from "@/components/ThemedText";
import { DBUser } from "@/utils/dbTemplate";
import { Users } from "lucide-react-native";
import { UserRole, ROLE_LABELS } from "@/types/roles";
import { ThemedButton } from "@/components/ThemedButton";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";

interface UserDetailsModalProps {
  user: DBUser;
  visible: boolean;
  onClose: () => void;
  onUpdateRole: (userId: string, newRole: UserRole) => void;
}

function UserDetailsModal({
  user,
  visible,
  onClose,
  onUpdateRole,
}: UserDetailsModalProps) {
  const availableRoles = Object.entries(ROLE_LABELS);

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ThemedText style={styles.modalTitle}>פרטי משתמש</ThemedText>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>שם:</ThemedText>
            <ThemedText style={styles.detailText}>{user.name}</ThemedText>
          </View>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>אימייל:</ThemedText>
            <ThemedText style={styles.detailText}>{user.email}</ThemedText>
          </View>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>תפקיד:</ThemedText>
            <View style={styles.roleButtonsContainer}>
              {availableRoles.map(([role, label]) => (
                <TouchableOpacity
                  key={role}
                  style={[
                    styles.roleButton,
                    user.role === role && styles.roleButtonSelected,
                  ]}
                  onPress={() => {
                    Alert.alert(
                      "שינוי תפקיד",
                      `האם אתה בטוח שברצונך לשנות את תפקיד המשתמש ל${label}?`,
                      [
                        { text: "ביטול", style: "cancel" },
                        {
                          text: "אישור",
                          style: "destructive",
                          onPress: () =>
                            onUpdateRole(user.id, role as UserRole),
                        },
                      ]
                    );
                  }}
                >
                  <ThemedText
                    style={[
                      styles.roleButtonText,
                      user.role === role && styles.roleButtonTextSelected,
                    ]}
                  >
                    {label}
                  </ThemedText>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <ThemedText style={styles.closeButtonText}>סגור</ThemedText>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

function ProfileRequestsModal({
  visible,
  onClose,
}: {
  visible: boolean;
  onClose: () => void;
}) {
  const [requests, setRequests] = useState<ProfileEditRequest[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRequests();
  }, [visible]);

  const loadRequests = async () => {
    try {
      const snapshot = await getDocs(
        query(
          collection(db, "profileEditRequests"),
          where("status", "==", "pending")
        )
      );
      setRequests(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    } catch (error) {
      console.error("Error loading requests:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleRequest = async (requestId: string, approved: boolean) => {
    try {
      const request = requests.find((r) => r.id === requestId);
      if (!request) return;

      if (approved) {
        // Update user profile
        await updateDoc(doc(db, "users", request.userId), {
          ...request.requestedChanges,
          updatedAt: new Date().toISOString(),
        });
      }

      // Update request status
      await updateDoc(doc(db, "profileEditRequests", requestId), {
        status: approved ? "approved" : "rejected",
        updatedAt: new Date().toISOString(),
      });

      await loadRequests();
    } catch (error) {
      console.error("Error handling request:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בטיפול בבקשה");
    }
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ThemedText style={styles.modalTitle}>בקשות עדכון פרופיל</ThemedText>

          {loading ? (
            <ActivityIndicator />
          ) : requests.length === 0 ? (
            <ThemedText style={styles.emptyText}>אין בקשות ממתינות</ThemedText>
          ) : (
            <FlatList
              data={requests}
              renderItem={({ item }) => (
                <View style={styles.requestItem}>
                  <View>
                    <ThemedText style={styles.userName}>
                      {item.userName}
                    </ThemedText>
                    {item.requestedChanges.name && (
                      <ThemedText>
                        שם חדש: {item.requestedChanges.name}
                      </ThemedText>
                    )}
                    {item.requestedChanges.phoneNumber && (
                      <ThemedText>
                        טלפון חדש: {item.requestedChanges.phoneNumber}
                      </ThemedText>
                    )}
                  </View>
                  <View style={styles.requestActions}>
                    <ThemedButton
                      title="אשר"
                      variant="primary"
                      onPress={() => handleRequest(item.id, true)}
                    />
                    <ThemedButton
                      title="דחה"
                      variant="danger"
                      onPress={() => handleRequest(item.id, false)}
                    />
                  </View>
                </View>
              )}
            />
          )}

          <ThemedButton title="סגור" variant="secondary" onPress={onClose} />
        </View>
      </View>
    </Modal>
  );
}

export default function StaffScreen() {
  const [users, setUsers] = useState<DBUser[]>([]);
  const { userRole, user } = useAuth();
  const [selectedUser, setSelectedUser] = useState<DBUser | null>(null);
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);
  const [requestsModalVisible, setRequestsModalVisible] = useState(false);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const usersSnap = await getDocs(query(collection(db, "users")));
      const userData = usersSnap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as DBUser[];
      setUsers(userData);
    } catch (error) {
      console.error("Error loading users:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בטעינת רשימת המשתמשים");
    }
  };

  const handleUpdateRole = async (userId: string, newRole: UserRole) => {
    try {
      const userRef = doc(db, "users", userId);

      await updateDoc(userRef, {
        role: newRole,
        updatedAt: new Date().toISOString(),
        lastModifiedBy: user?.uid,
      });

      // Log role change
      await addDoc(collection(db, "roleChanges"), {
        userId,
        oldRole: selectedUser?.role,
        newRole,
        changedBy: user?.uid,
        timestamp: new Date().toISOString(),
      });

      // Refresh users list
      await loadUsers();

      // Close modal and show success message
      setSelectedUser(null);
      Alert.alert("הצלחה", "תפקיד המשתמש עודכן בהצלחה");
    } catch (error) {
      console.error("Error updating role:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בעדכון התפקיד");
    }
  };

  // Update RoleLabel component to use ROLE_LABELS
  const RoleLabel = ({ role }: { role: UserRole }) => (
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
      <ThemedText style={styles.roleText}>{ROLE_LABELS[role]}</ThemedText>
    </View>
  );

  return (
    <View style={[styles.container, themed.contentBackground]}>
      <View style={styles.header}>
        <Users size={24} color="#333" />
        <ThemedText style={styles.title}>ניהול צוות</ThemedText>
      </View>

      <FlatList
        data={users}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.userCard}
            onPress={() => setSelectedUser(item)}
          >
            <View>
              <ThemedText style={styles.userName}>{item.name}</ThemedText>
              <ThemedText style={styles.userEmail}>{item.email}</ThemedText>
            </View>
            <RoleLabel role={item.role} />
          </TouchableOpacity>
        )}
      />

      {selectedUser && (
        <UserDetailsModal
          user={selectedUser}
          visible={!!selectedUser}
          onClose={() => setSelectedUser(null)}
          onUpdateRole={(userId, newRole) => {
            Alert.alert(
              "שינוי תפקיד",
              `האם אתה בטוח שברצונך לשנות את תפקיד המשתמש ל${ROLE_LABELS[newRole]}?`,
              [
                { text: "ביטול", style: "cancel" },
                {
                  text: "אישור",
                  style: "destructive",
                  onPress: () => handleUpdateRole(userId, newRole),
                },
              ]
            );
          }}
        />
      )}

      {userRole === "admin" && (
        <ThemedButton
          title="בקשות עדכון פרופיל"
          variant="primary"
          onPress={() => setRequestsModalVisible(true)}
        />
      )}

      <ProfileRequestsModal
        visible={requestsModalVisible}
        onClose={() => setRequestsModalVisible(false)}
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
  modalContainer: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.5)",
    justifyContent: "center",
    padding: 20,
  },
  modalContent: {
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 20,
  },
  modalTitle: {
    fontSize: 24,
    fontFamily: "Heebo-Bold",
    textAlign: "center",
    marginBottom: 20,
  },
  detailRow: {
    marginBottom: 16,
  },
  detailLabel: {
    fontSize: 14,
    color: "#666",
    marginBottom: 4,
    textAlign: "right",
  },
  detailText: {
    fontSize: 16,
    color: "#333",
    textAlign: "right",
    fontFamily: "Heebo-Bold",
  },
  roleButtonsContainer: {
    flexDirection: "row",
    justifyContent: "flex-end",
    flexWrap: "wrap",
    gap: 8,
    marginTop: 8,
  },
  roleButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: "#f3f4f6",
    minWidth: 80,
    alignItems: "center",
  },
  roleButtonSelected: {
    backgroundColor: "#0066cc",
  },
  roleButtonText: {
    color: "#666666",
    fontSize: 14,
    fontFamily: "Heebo-Bold",
  },
  roleButtonTextSelected: {
    color: "#ffffff",
  },
  closeButton: {
    backgroundColor: "#f3f4f6",
    padding: 12,
    borderRadius: 8,
    marginTop: 16,
  },
  closeButtonText: {
    textAlign: "center",
    color: "#666",
    fontFamily: "Heebo-Bold",
  },
  requestItem: {
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
  requestActions: {
    flexDirection: "row",
    gap: 8,
  },
  emptyText: {
    textAlign: "center",
    color: "#666",
    fontFamily: "Heebo-Bold",
  },
});
