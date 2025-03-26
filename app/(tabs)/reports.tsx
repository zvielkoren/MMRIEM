import {
  View,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
  Modal,
  TextInput,
  ScrollView,
  ActivityIndicator,
} from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import {
  collection,
  query,
  getDocs,
  where,
  orderBy,
  addDoc,
  updateDoc,
  doc,
  getDoc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { useState, useEffect } from "react";
import { ThemedText } from "@/components/ThemedText";
import {
  ClipboardList,
  Plus,
  ChevronLeft,
  Users,
  FileText,
} from "lucide-react-native";

interface Report {
  id: string;
  userId: string;
  studentId?: string;
  instructorId: string;
  type: "daily" | "weekly" | "monthly";
  content: {
    text: string;
    attachments?: string[];
    notes?: string;
  };
  status: "draft" | "submitted" | "reviewed";
  createdAt: string;
  updatedAt: string;
}

interface DBUser {
  id: string;
  name: string;
}

interface CreateReportModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (data: {
    text: string;
    type: Report["type"];
    userId?: string;
    instructorId: string;
    status: Report["status"];
  }) => void;
}

function CreateReportModal({
  visible,
  onClose,
  onSubmit,
}: CreateReportModalProps) {
  const [text, setText] = useState("");
  const [type, setType] = useState<Report["type"]>("daily");
  const [selectedUser, setSelectedUser] = useState<string>();
  const [users, setUsers] = useState<DBUser[]>([]);
  const { user } = useAuth();

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

  const handleSubmit = async () => {
    if (!text || !selectedUser) {
      Alert.alert("שגיאה", "נא להזין את כל הפרטים");
      return;
    }

    try {
      await onSubmit({
        text,
        type,
        userId: selectedUser,
        instructorId: user?.uid || "",
        status: "draft",
      });
      setText("");
      setSelectedUser(undefined);
      onClose();
    } catch (error) {
      Alert.alert("שגיאה", "אירעה שגיאה בשמירת הדוח");
    }
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ThemedText style={styles.modalTitle}>דוח חדש</ThemedText>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>סוג דוח</ThemedText>
            <View style={styles.typeSelector}>
              {["daily", "weekly", "monthly"].map((t) => (
                <TouchableOpacity
                  key={t}
                  style={[
                    styles.typeButton,
                    type === t && styles.typeButtonSelected,
                  ]}
                  onPress={() => setType(t as Report["type"])}
                >
                  <ThemedText
                    style={[
                      styles.typeButtonText,
                      type === t && styles.typeButtonTextSelected,
                    ]}
                  >
                    {t === "daily"
                      ? "יומי"
                      : t === "weekly"
                      ? "שבועי"
                      : "חודשי"}
                  </ThemedText>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>חניך</ThemedText>
            <ScrollView horizontal style={styles.usersScroll}>
              {users.map((user) => (
                <TouchableOpacity
                  key={user.id}
                  style={[
                    styles.userChip,
                    selectedUser === user.id && styles.userChipSelected,
                  ]}
                  onPress={() => setSelectedUser(user.id)}
                >
                  <Users
                    size={16}
                    color={selectedUser === user.id ? "#fff" : "#666"}
                  />
                  <ThemedText
                    style={[
                      styles.userChipText,
                      selectedUser === user.id && styles.userChipTextSelected,
                    ]}
                  >
                    {user.name}
                  </ThemedText>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>תוכן הדוח</ThemedText>
            <TextInput
              style={styles.textArea}
              multiline
              numberOfLines={4}
              value={text}
              onChangeText={setText}
              placeholder="הכנס את תוכן הדוח כאן..."
              textAlign="right"
            />
          </View>

          <View style={styles.modalActions}>
            <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
              <ThemedText style={styles.cancelButtonText}>ביטול</ThemedText>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.submitButton}
              onPress={handleSubmit}
            >
              <ThemedText style={styles.submitButtonText}>שמור</ThemedText>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

interface ReportDetailsModalProps {
  report: Report;
  visible: boolean;
  onClose: () => void;
  onStatusChange: (report: Report) => void;
  getStatusColor: (status: Report["status"]) => string; // Add this prop
  getStatusText: (status: Report["status"]) => string; // Add this prop
}

function ReportDetailsModal({
  report,
  visible,
  onClose,
  onStatusChange,
  getStatusColor, // Add this prop
  getStatusText, // Add this prop
}: ReportDetailsModalProps) {
  const [userName, setUserName] = useState("");
  const [instructorName, setInstructorName] = useState(""); // Add this
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDetails = async () => {
      try {
        const [userDoc, instructorDoc] = await Promise.all([
          getDoc(doc(db, "users", report.userId)),
          getDoc(doc(db, "users", report.instructorId)),
        ]);

        if (userDoc.exists()) {
          setUserName(userDoc.data().name);
        }
        if (instructorDoc.exists()) {
          setInstructorName(instructorDoc.data().name);
        }
      } catch (error) {
        console.error("Error fetching details:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDetails();
  }, [report.userId, report.instructorId]);

  if (loading) {
    return (
      <Modal visible={visible} animationType="slide" transparent>
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <ActivityIndicator size="large" color="#0066cc" />
          </View>
        </View>
      </Modal>
    );
  }

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ThemedText style={styles.modalTitle}>פרטי דוח</ThemedText>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>חניך:</ThemedText>
            <ThemedText style={styles.detailText}>{userName}</ThemedText>
          </View>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>סוג דוח:</ThemedText>
            <ThemedText style={styles.detailText}>
              {report.type === "daily"
                ? "יומי"
                : report.type === "weekly"
                ? "שבועי"
                : "חודשי"}
            </ThemedText>
          </View>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>תאריך יצירה:</ThemedText>
            <ThemedText style={styles.detailText}>
              {new Date(report.createdAt).toLocaleDateString("he-IL")}
            </ThemedText>
          </View>

          <View style={styles.detailRow}>
            <ThemedText style={styles.detailLabel}>נכתב על ידי:</ThemedText>
            <ThemedText style={styles.detailText}>{instructorName}</ThemedText>
          </View>

          <View style={styles.contentBox}>
            <ThemedText style={styles.contentLabel}>תוכן הדוח:</ThemedText>
            <ThemedText style={styles.contentText}>
              {report.content.text}
            </ThemedText>
          </View>

          <TouchableOpacity
            style={[
              styles.statusButton,
              { backgroundColor: getStatusColor(report.status) },
            ]}
            onPress={() => onStatusChange(report)}
          >
            <FileText size={20} color="#fff" />
            <ThemedText style={styles.statusButtonText}>
              {report.status === "draft" ? "הגש דוח" : "החזר לטיוטה"}
            </ThemedText>
          </TouchableOpacity>

          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <ThemedText style={styles.closeButtonText}>סגור</ThemedText>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

export default function ReportsScreen() {
  const [reports, setReports] = useState<Report[]>([]);
  const { user, userRole } = useAuth();
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);

  useEffect(() => {
    loadReports();
  }, []);

  const loadReports = async () => {
    try {
      const reportsRef = collection(db, "reports");
      let q;

      if (userRole === "admin") {
        q = query(reportsRef, orderBy("createdAt", "desc"));
      } else if (userRole === "instructor") {
        q = query(reportsRef, where("instructorId", "==", user?.uid));
      }

      const snapshot = await getDocs(q);
      const reportsData = snapshot.docs.map(
        (doc) =>
          ({
            id: doc.id,
            ...doc.data(),
          } as Report)
      );

      // Sort client-side for instructor reports
      if (userRole === "instructor") {
        reportsData.sort(
          (a, b) =>
            new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
      }

      setReports(reportsData);
    } catch (error) {
      console.error("Error loading reports:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בטעינת הדוחות");
    }
  };

  const createNewReport = async (data: {
    text: string;
    type: Report["type"];
    userId?: string;
    instructorId: string;
    status: Report["status"];
  }) => {
    try {
      const newReport = {
        userId: data.userId || user?.uid,
        instructorId: data.instructorId,
        type: data.type,
        content: {
          text: data.text,
          attachments: [],
          notes: "",
        },
        status: data.status,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const docRef = await addDoc(collection(db, "reports"), newReport);

      // Update report with ID
      await updateDoc(doc(db, "reports", docRef.id), {
        id: docRef.id,
      });

      await loadReports(); // Refresh the list
      Alert.alert("הצלחה", "הדוח נשמר בהצלחה");
    } catch (error) {
      console.error("Error creating report:", error);
      Alert.alert("שגיאה", "אירעה שגיאה ביצירת הדוח");
    }
  };

  const toggleReportStatus = async (report: Report) => {
    try {
      const newStatus = report.status === "draft" ? "submitted" : "draft";
      await updateDoc(doc(db, "reports", report.id), {
        status: newStatus,
        updatedAt: new Date().toISOString(),
      });
      await loadReports(); // Refresh list
      Alert.alert("הצלחה", "סטטוס הדוח עודכן בהצלחה");
    } catch (error) {
      console.error("Error updating report status:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בעדכון הסטטוס");
    }
  };

  const getStatusColor = (status: Report["status"]) => {
    switch (status) {
      case "draft":
        return "#6b7280";
      case "submitted":
        return "#2563eb";
      case "reviewed":
        return "#059669";
      default:
        return "#6b7280";
    }
  };

  const getStatusText = (status: Report["status"]) => {
    switch (status) {
      case "draft":
        return "טיוטה";
      case "submitted":
        return "הוגש";
      case "reviewed":
        return "נבדק";
      default:
        return status;
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <ClipboardList size={24} color="#333" />
        <ThemedText style={styles.title}>דוחות פעילות</ThemedText>
      </View>

      <FlatList
        data={reports}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.reportCard}
            onPress={() => setSelectedReport(item)}
          >
            <View>
              <ThemedText style={styles.reportTitle}>
                דוח{" "}
                {item.type === "daily"
                  ? "יומי"
                  : item.type === "weekly"
                  ? "שבועי"
                  : "חודשי"}
              </ThemedText>
              <ThemedText style={styles.reportDate}>
                {new Date(item.createdAt).toLocaleDateString("he-IL")}
              </ThemedText>
            </View>

            <View style={styles.actionContainer}>
              <TouchableOpacity
                style={[
                  styles.statusTag,
                  { backgroundColor: getStatusColor(item.status) },
                ]}
                onPress={() => toggleReportStatus(item)}
              >
                <ThemedText style={styles.statusText}>
                  {getStatusText(item.status)}
                </ThemedText>
                <ChevronLeft size={16} color="#fff" />
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        )}
      />

      <CreateReportModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        onSubmit={createNewReport}
      />

      {selectedReport && (
        <ReportDetailsModal
          report={selectedReport}
          visible={!!selectedReport}
          onClose={() => setSelectedReport(null)}
          onStatusChange={toggleReportStatus}
          getStatusColor={getStatusColor} // Pass the function
          getStatusText={getStatusText} // Pass the function
        />
      )}

      <TouchableOpacity
        style={styles.fab}
        onPress={() => setModalVisible(true)}
      >
        <Plus size={24} color="#fff" />
      </TouchableOpacity>
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
  reportCard: {
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
  reportTitle: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    color: "#333",
  },
  reportDate: {
    fontSize: 14,
    color: "#666",
    marginTop: 4,
  },
  statusTag: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    gap: 4,
  },
  statusText: {
    color: "#fff",
    fontSize: 12,
    fontFamily: "Heebo-Bold",
  },
  fab: {
    position: "absolute",
    bottom: 24,
    left: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: "#0066cc",
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
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
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    marginBottom: 8,
    textAlign: "right",
  },
  textArea: {
    borderWidth: 1,
    borderColor: "#e5e5e5",
    borderRadius: 8,
    padding: 12,
    height: 100,
    textAlignVertical: "top",
  },
  typeSelector: {
    flexDirection: "row",
    gap: 8,
    justifyContent: "flex-end",
  },
  typeButton: {
    padding: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#e5e5e5",
  },
  typeButtonSelected: {
    backgroundColor: "#0066cc",
    borderColor: "#0066cc",
  },
  typeButtonText: {
    color: "#666",
  },
  typeButtonTextSelected: {
    color: "#fff",
  },
  usersScroll: {
    maxHeight: 100,
  },
  userChip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    padding: 8,
    borderRadius: 16,
    backgroundColor: "#f5f5f5",
    marginRight: 8,
  },
  userChipSelected: {
    backgroundColor: "#0066cc",
  },
  userChipText: {
    color: "#666",
  },
  userChipTextSelected: {
    color: "#fff",
  },
  modalActions: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 20,
  },
  cancelButton: {
    flex: 1,
    padding: 12,
    marginRight: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#e5e5e5",
  },
  submitButton: {
    flex: 1,
    padding: 12,
    marginLeft: 8,
    borderRadius: 8,
    backgroundColor: "#0066cc",
  },
  cancelButtonText: {
    textAlign: "center",
    color: "#666",
  },
  submitButtonText: {
    textAlign: "center",
    color: "#fff",
    fontFamily: "Heebo-Bold",
  },
  actionContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  detailRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  detailLabel: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    color: "#333",
  },
  detailText: {
    fontSize: 16,
    color: "#333",
    fontFamily: "Heebo-Bold",
    textAlign: "left",
  },
  contentBox: {
    backgroundColor: "#f5f5f5",
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  contentLabel: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    color: "#333",
    marginBottom: 8,
  },
  contentText: {
    fontSize: 16,
    color: "#666",
  },
  statusButton: {
    flexDirection: "row",
    alignItems: "center",
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  statusButtonText: {
    color: "#fff",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    marginLeft: 8,
  },
  closeButton: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: "#e5e5e5",
  },
  closeButtonText: {
    textAlign: "center",
    color: "#333",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
});
