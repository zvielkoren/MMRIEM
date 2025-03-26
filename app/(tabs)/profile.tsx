import {
  View,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Modal,
  Alert,
} from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import { ThemedText } from "@/components/ThemedText";
import {
  UserCircle,
  Mail,
  Phone,
  Calendar,
  ShieldCheck,
  Edit,
} from "lucide-react-native";
import { ROLE_LABELS } from "@/types/roles";
import { useState, useEffect } from "react";
import {
  doc,
  updateDoc,
  addDoc,
  collection,
  query,
  where,
  limit,
  getDocs,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { USER_GROUPS, UserGroup } from "@/utils/dbTemplate";

interface ProfileEditRequest {
  userId: string;
  userName: string;
  requestedChanges: {
    name?: string;
    phoneNumber?: string;
  };
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  updatedAt: string;
}

function GroupSelector({
  currentGroup,
  onGroupChange,
  isAdmin, // Add this prop
}: {
  currentGroup?: UserGroup;
  onGroupChange: (group: UserGroup) => void;
  isAdmin: boolean;
}) {
  // Only render if admin
  if (!isAdmin) {
    return (
      <View style={styles.section}>
        <ThemedText style={styles.sectionTitle}>קבוצה</ThemedText>
        <ThemedText style={styles.infoText}>
          {currentGroup ? USER_GROUPS[currentGroup] : "לא משויך לקבוצה"}
        </ThemedText>
      </View>
    );
  }

  return (
    <View style={styles.groupSelector}>
      <ThemedText style={styles.sectionTitle}>קבוצה</ThemedText>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {Object.entries(USER_GROUPS).map(([key, label]) => (
          <TouchableOpacity
            key={key}
            style={[
              styles.groupChip,
              currentGroup === key && styles.groupChipSelected,
            ]}
            onPress={() => onGroupChange(key as UserGroup)}
          >
            <ThemedText
              style={[
                styles.groupChipText,
                currentGroup === key && styles.groupChipTextSelected,
              ]}
            >
              {label}
            </ThemedText>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

export default function ProfileScreen() {
  const { userData, userRole, user } = useAuth(); // Add user from useAuth
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({
    name: "",
    phoneNumber: "",
  });
  const [editRequest, setEditRequest] = useState<ProfileEditRequest | null>(
    null
  );

  useEffect(() => {
    // Load any pending edit request
    const loadPendingRequest = async () => {
      try {
        const requestsRef = collection(db, "profileEditRequests");
        const q = query(
          requestsRef,
          where("userId", "==", userData?.id),
          where("status", "==", "pending"),
          limit(1)
        );

        const snapshot = await getDocs(q);
        if (!snapshot.empty) {
          setEditRequest(snapshot.docs[0].data() as ProfileEditRequest);
        }
      } catch (error) {
        console.error("Error loading pending request:", error);
      }
    };

    if (userData?.id) {
      loadPendingRequest();
    }
  }, [userData?.id]);

  if (!userData) return null;

  // Add function to check for existing requests
  const checkExistingRequests = async () => {
    try {
      if (!user?.uid) return false; // Add guard clause

      const requestsRef = collection(db, "profileEditRequests");
      const q = query(
        requestsRef,
        where("userId", "==", user.uid), // Use user.uid instead of userData.id
        where("status", "==", "pending"),
        limit(1)
      );

      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        setEditRequest(snapshot.docs[0].data() as ProfileEditRequest);
        return true;
      }
      return false;
    } catch (error) {
      console.error("Error checking requests:", error);
      return false;
    }
  };

  const handleEdit = async () => {
    try {
      if (!user?.uid) {
        Alert.alert("שגיאה", "משתמש לא מחובר");
        return;
      }

      // Validation checks
      if (!editData.name || editData.name.trim().length < 2) {
        Alert.alert("שגיאה", "נא להזין שם תקין");
        return;
      }

      // Get actual changes
      const changes: { name?: string; phoneNumber?: string } = {};

      if (editData.name !== userData?.name) {
        changes.name = editData.name.trim();
      }

      if (editData.phoneNumber !== userData?.phoneNumber) {
        changes.phoneNumber = editData.phoneNumber.trim();
      }

      // Check if there are any changes
      if (Object.keys(changes).length === 0) {
        Alert.alert("שגיאה", "לא בוצעו שינויים");
        return;
      }

      // Create request object
      const request = {
        userId: user.uid,
        userName: userData?.name || "",
        requestedChanges: changes,
        status: "pending" as const,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const docRef = await addDoc(
        collection(db, "profileEditRequests"),
        request
      );
      setEditRequest({ ...request, id: docRef.id });
      setIsEditing(false);
      Alert.alert("בקשה נשלחה", "בקשת העדכון נשלחה לאישור מנהל");
    } catch (error) {
      console.error("Error updating profile:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בשמירת הפרטים");
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.avatarContainer}>
          <UserCircle size={80} color="#0066cc" />
        </View>
        <ThemedText style={styles.name}>{userData.name}</ThemedText>
        <View style={styles.roleContainer}>
          <ShieldCheck size={16} color="#ffffff" />
          <ThemedText style={styles.role}>
            {ROLE_LABELS[userRole || "user"]}
          </ThemedText>
        </View>
      </View>

      <TouchableOpacity
        style={styles.editButton}
        onPress={() => {
          setEditData({
            name: userData.name,
            phoneNumber: userData.phoneNumber || "",
          });
          setIsEditing(true);
        }}
      >
        <Edit size={20} color="#0066cc" />
        <ThemedText style={styles.editButtonText}>ערוך פרטים</ThemedText>
      </TouchableOpacity>

      <Modal visible={isEditing} animationType="slide" transparent>
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <ThemedText style={styles.modalTitle}>עריכת פרטים</ThemedText>

            <View style={styles.inputGroup}>
              <ThemedText style={styles.label}>שם מלא</ThemedText>
              <TextInput
                style={styles.input}
                value={editData.name}
                onChangeText={(text) =>
                  setEditData((prev) => ({ ...prev, name: text }))
                }
                textAlign="right"
              />
            </View>

            <View style={styles.inputGroup}>
              <ThemedText style={styles.label}>מספר טלפון</ThemedText>
              <TextInput
                style={styles.input}
                value={editData.phoneNumber}
                onChangeText={(text) =>
                  setEditData((prev) => ({ ...prev, phoneNumber: text }))
                }
                keyboardType="phone-pad"
                textAlign="right"
              />
            </View>

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() => setIsEditing(false)}
              >
                <ThemedText style={styles.cancelButtonText}>ביטול</ThemedText>
              </TouchableOpacity>
              <TouchableOpacity style={styles.saveButton} onPress={handleEdit}>
                <ThemedText style={styles.saveButtonText}>שמור</ThemedText>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <View style={styles.section}>
        <ThemedText style={styles.sectionTitle}>פרטי משתמש</ThemedText>

        <View style={styles.infoRow}>
          <Mail size={20} color="#666666" />
          <ThemedText style={styles.infoText}>{userData.email}</ThemedText>
        </View>

        <View style={styles.infoRow}>
          <Phone size={20} color="#666666" />
          <ThemedText style={styles.infoText}>
            {userData.phoneNumber || "לא הוגדר מספר טלפון"}
          </ThemedText>
        </View>

        <View style={styles.infoRow}>
          <Calendar size={20} color="#666666" />
          <ThemedText style={styles.infoText}>
            נרשם: {new Date(userData.createdAt).toLocaleDateString("he-IL")}
          </ThemedText>
        </View>
      </View>

      {userRole === "instructor" && (
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>נתוני מדריך</ThemedText>
          <ThemedText style={styles.statsText}>
            חניכים פעילים: {userData.students?.length || 0}
          </ThemedText>
          <ThemedText style={styles.statsText}>
            דוחות החודש: {0} {/* TODO: Add reports count */}
          </ThemedText>
        </View>
      )}

      {editRequest && editRequest.status === "pending" && (
        <View style={styles.section}>
          <ThemedText style={styles.sectionTitle}>
            בקשת עדכון ממתינה לאישור
          </ThemedText>
          <ThemedText style={styles.infoText}>
            {editRequest.requestedChanges.name &&
              `שם חדש: ${editRequest.requestedChanges.name}`}
          </ThemedText>
          <ThemedText style={styles.infoText}>
            {editRequest.requestedChanges.phoneNumber &&
              `טלפון חדש: ${editRequest.requestedChanges.phoneNumber}`}
          </ThemedText>
        </View>
      )}

      {userData?.group && (
        <GroupSelector
          currentGroup={userData.group}
          onGroupChange={async (newGroup) => {
            if (userRole !== "admin") return; // Add this check
            try {
              await updateDoc(doc(db, "users", userData.id), {
                group: newGroup,
                updatedAt: new Date().toISOString(),
              });
              // Reload user data
              await loadUserData();
              Alert.alert("הצלחה", "הקבוצה עודכנה בהצלחה");
            } catch (error) {
              console.error("Error updating group:", error);
              Alert.alert("שגיאה", "אירעה שגיאה בעדכון הקבוצה");
            }
          }}
          isAdmin={userRole === "admin"}
        />
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f5f5f5",
  },
  header: {
    backgroundColor: "#ffffff",
    paddingVertical: 32,
    alignItems: "center",
    borderBottomWidth: 1,
    borderBottomColor: "#e5e5e5",
  },
  avatarContainer: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: "#f0f9ff",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 16,
  },
  name: {
    fontSize: 24,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginBottom: 8,
  },
  roleContainer: {
    backgroundColor: "#0066cc",
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  role: {
    color: "#ffffff",
    fontSize: 14,
    fontFamily: "Heebo-Bold",
  },
  editButton: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
    backgroundColor: "#e0f7ff",
    borderRadius: 8,
    margin: 16,
  },
  editButtonText: {
    color: "#0066cc",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    marginLeft: 8,
  },
  section: {
    backgroundColor: "#ffffff",
    margin: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginBottom: 16,
    textAlign: "right",
  },
  infoRow: {
    flexDirection: "row-reverse",
    alignItems: "center",
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#f0f0f0",
    gap: 12,
  },
  infoText: {
    fontSize: 16,
    color: "#333333",
    flex: 1,
    textAlign: "right",
  },
  statsText: {
    fontSize: 16,
    color: "#666666",
    textAlign: "right",
    marginBottom: 8,
  },
  modalContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.5)",
  },
  modalContent: {
    width: "80%",
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 16,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  modalTitle: {
    fontSize: 18,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginBottom: 16,
    textAlign: "center",
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: "#e0e0e0",
    borderRadius: 8,
    padding: 10,
    fontSize: 16,
    color: "#333333",
  },
  modalActions: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  cancelButton: {
    backgroundColor: "#e0e0e0",
    padding: 10,
    borderRadius: 8,
  },
  cancelButtonText: {
    color: "#333333",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
  saveButton: {
    backgroundColor: "#0066cc",
    padding: 10,
    borderRadius: 8,
  },
  saveButtonText: {
    color: "#ffffff",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
  groupSelector: {
    marginVertical: 8,
  },
  groupChip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: "#f3f4f6",
    marginRight: 8,
  },
  groupChipSelected: {
    backgroundColor: "#0066cc",
  },
  groupChipText: {
    color: "#666666",
    fontSize: 14,
    fontFamily: "Heebo-Bold",
  },
  groupChipTextSelected: {
    color: "#ffffff",
  },
});
