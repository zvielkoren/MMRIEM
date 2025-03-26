import React, { useEffect, useState, useCallback } from "react";
import {
  View,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Modal,
  TextInput,
  ScrollView,
  Platform,
} from "react-native";
import {
  useFonts,
  Heebo_400Regular,
  Heebo_700Bold,
} from "@expo-google-fonts/heebo";
import { ThemedText } from "@/components/ThemedText";
import { useAuth } from "@/contexts/AuthContext";
import {
  collection,
  query,
  getDocs,
  where,
  addDoc,
  orderBy,
  limit,
  doc,
  getDoc,
  updateDoc,
  deleteDoc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { Plus, Edit, Trash2 } from "react-native-feather";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";
import { DBUser } from "@/utils/dbTemplate";
import DateTimePicker from "@react-native-community/datetimepicker";
import { USER_GROUPS, UserGroup } from "@/utils/dbTemplate";

interface CalendarEvent {
  id: string;
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  participants: string[];
  createdBy: string;
  status: "active" | "cancelled";
  group?: UserGroup;
  startTime?: string;
  endTime?: string;
}

interface CreateEventModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (event: Omit<CalendarEvent, "id" | "createdBy">) => void;
}

interface EventDetailsModalProps {
  event: CalendarEvent;
  visible: boolean;
  onClose: () => void;
  canEdit: boolean;
  onEdit?: (event: CalendarEvent) => void;
  onDelete?: (event: CalendarEvent) => void;
}

function ParticipantChip({ userId }: { userId: string }) {
  const [userName, setUserName] = useState("");

  useEffect(() => {
    const loadUser = async () => {
      try {
        const userDoc = await getDoc(doc(db, "users", userId));
        if (userDoc.exists()) {
          setUserName(userDoc.data().name);
        }
      } catch (error) {
        console.error("Error loading user:", error);
      }
    };
    loadUser();
  }, [userId]);

  return (
    <View style={styles.participantChip}>
      <ThemedText style={styles.participantName}>
        {userName || "..."}
      </ThemedText>
    </View>
  );
}

function EventDetailsModal({
  event,
  visible,
  onClose,
  canEdit,
  onEdit,
  onDelete,
}: EventDetailsModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState(event);

  const handleSave = () => {
    if (!editData.title || !editData.description) {
      Alert.alert("שגיאה", "יש למלא את כל השדות");
      return;
    }

    onEdit?.(editData);
    setIsEditing(false);
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <View style={styles.modalHeader}>
            <ThemedText style={styles.modalTitle}>{event.title}</ThemedText>
            {canEdit && (
              <View style={styles.headerActions}>
                <TouchableOpacity onPress={() => setIsEditing(true)}>
                  <Edit size={20} color="#0066cc" />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => {
                    Alert.alert(
                      "מחיקת אירוע",
                      "האם אתה בטוח שברצונך למחוק את האירוע?",
                      [
                        { text: "ביטול", style: "cancel" },
                        {
                          text: "מחק",
                          style: "destructive",
                          onPress: () => onDelete?.(event),
                        },
                      ]
                    );
                  }}
                >
                  <Trash2 size={20} color="#dc2626" />
                </TouchableOpacity>
              </View>
            )}
          </View>
          {isEditing ? (
            <>
              <View style={styles.inputGroup}>
                <ThemedText style={styles.label}>כותרת</ThemedText>
                <TextInput
                  style={styles.input}
                  value={editData.title}
                  onChangeText={(text) =>
                    setEditData({ ...editData, title: text })
                  }
                  textAlign="right"
                />
              </View>

              <View style={styles.inputGroup}>
                <ThemedText style={styles.label}>תיאור</ThemedText>
                <TextInput
                  style={[styles.input, { height: 100 }]}
                  value={editData.description}
                  onChangeText={(text) =>
                    setEditData({ ...editData, description: text })
                  }
                  multiline
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
                <TouchableOpacity
                  style={styles.saveButton}
                  onPress={handleSave}
                >
                  <ThemedText style={styles.saveButtonText}>שמור</ThemedText>
                </TouchableOpacity>
              </View>
            </>
          ) : (
            <>
              <View style={styles.detailSection}>
                <ThemedText style={styles.detailLabel}>תאריך:</ThemedText>
                <ThemedText style={styles.detailText}>
                  {formatDate(event.startDate)}
                </ThemedText>
              </View>

              <View style={styles.detailSection}>
                <ThemedText style={styles.detailLabel}>תיאור:</ThemedText>
                <ThemedText style={styles.detailText}>
                  {event.description}
                </ThemedText>
              </View>

              <View style={styles.participantsSection}>
                <ThemedText style={styles.detailLabel}>משתתפים:</ThemedText>
                <View style={styles.participantsList}>
                  {event.participants.map((userId) => (
                    <ParticipantChip key={userId} userId={userId} />
                  ))}
                </View>
              </View>

              <TouchableOpacity style={styles.closeButton} onPress={onClose}>
                <ThemedText style={styles.closeButtonText}>סגור</ThemedText>
              </TouchableOpacity>
            </>
          )}
        </View>
      </View>
    </Modal>
  );
}

function CreateEventModal({
  visible,
  onClose,
  onSubmit,
}: CreateEventModalProps) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [participants, setParticipants] = useState<string[]>([]);
  const [availableUsers, setAvailableUsers] = useState<DBUser[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<UserGroup>("ALL");
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedTime, setSelectedTime] = useState(new Date());
  const [showStartDatePicker, setShowStartDatePicker] = useState(false);
  const [showStartTimePicker, setShowStartTimePicker] = useState(false);
  const [showEndDatePicker, setShowEndDatePicker] = useState(false);
  const [showEndTimePicker, setShowEndTimePicker] = useState(false);

  useEffect(() => {
    loadAvailableUsers();
  }, []);

  const loadAvailableUsers = async () => {
    const usersSnap = await getDocs(collection(db, "users"));
    const users = usersSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    setAvailableUsers(users);
  };

  const handleSubmit = () => {
    if (!title || !description || participants.length === 0) {
      Alert.alert("שגיאה", "נא למלא את כל השדות ולבחור משתתפים");
      return;
    }

    onSubmit({
      title,
      description,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      participants,
      status: "active",
      group: selectedGroup,
      startTime: selectedTime.toISOString(),
      endTime: selectedTime.toISOString(),
    });
  };

  const handleDateChange = (event: any, date?: Date) => {
    setShowDatePicker(false);
    if (date) {
      setSelectedDate(date);
    }
  };

  const handleTimeChange = (event: any, time?: Date) => {
    setShowTimePicker(false);
    if (time) {
      setSelectedTime(time);
    }
  };

  const formatDateDisplay = (date: Date) => {
    return date.toLocaleDateString("he-IL", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
  };

  const formatTimeDisplay = (date: Date) => {
    return date.toLocaleTimeString("he-IL", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const handleDateChangePicker = (
    event: any,
    selectedDate?: Date,
    isStart = true
  ) => {
    if (Platform.OS === "android") {
      setShowStartDatePicker(false);
      setShowEndDatePicker(false);
    }

    if (selectedDate) {
      if (isStart) {
        const newDate = new Date(startDate);
        newDate.setFullYear(selectedDate.getFullYear());
        newDate.setMonth(selectedDate.getMonth());
        newDate.setDate(selectedDate.getDate());
        setStartDate(newDate);

        // Update end date if it's before start date
        if (endDate < newDate) {
          setEndDate(newDate);
        }
      } else {
        const newDate = new Date(endDate);
        newDate.setFullYear(selectedDate.getFullYear());
        newDate.setMonth(selectedDate.getMonth());
        newDate.setDate(selectedDate.getDate());
        setEndDate(newDate);
      }
    }
  };

  const handleTimeChangePicker = (
    event: any,
    selectedDate?: Date,
    isStart = true
  ) => {
    if (Platform.OS === "android") {
      setShowStartTimePicker(false);
      setShowEndTimePicker(false);
    }

    if (selectedDate) {
      if (isStart) {
        const newDate = new Date(startDate);
        newDate.setHours(selectedDate.getHours());
        newDate.setMinutes(selectedDate.getMinutes());
        setStartDate(newDate);

        // Update end time if it's before start time
        if (endDate < newDate) {
          setEndDate(newDate);
        }
      } else {
        const newDate = new Date(endDate);
        newDate.setHours(selectedDate.getHours());
        newDate.setMinutes(selectedDate.getMinutes());
        setEndDate(newDate);
      }
    }
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalContainer}>
        <ScrollView style={styles.modalContent}>
          <ThemedText style={styles.modalTitle}>אירוע חדש</ThemedText>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>כותרת</ThemedText>
            <TextInput
              style={styles.input}
              value={title}
              onChangeText={setTitle}
              placeholder="הזן כותרת"
              textAlign="right"
            />
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>תיאור</ThemedText>
            <TextInput
              style={[styles.input, { height: 100 }]}
              value={description}
              onChangeText={setDescription}
              placeholder="הזן תיאור"
              multiline
              textAlign="right"
            />
          </View>

          <View style={styles.participantsSection}>
            <ThemedText style={styles.label}>משתתפים</ThemedText>
            <ScrollView horizontal>
              {availableUsers.map((user) => (
                <TouchableOpacity
                  key={user.id}
                  style={[
                    styles.participantChip,
                    participants.includes(user.id) &&
                      styles.participantChipSelected,
                  ]}
                  onPress={() => {
                    setParticipants((prev) =>
                      prev.includes(user.id)
                        ? prev.filter((id) => id !== user.id)
                        : [...prev, user.id]
                    );
                  }}
                >
                  <ThemedText>{user.name}</ThemedText>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>קבוצה</ThemedText>
            <ScrollView horizontal>
              {Object.entries(USER_GROUPS).map(([key, label]) => (
                <TouchableOpacity
                  key={key}
                  style={[
                    styles.groupChip,
                    selectedGroup === key && styles.groupChipSelected,
                  ]}
                  onPress={() => setSelectedGroup(key as UserGroup)}
                >
                  <ThemedText
                    style={[
                      styles.groupChipText,
                      selectedGroup === key && styles.groupChipTextSelected,
                    ]}
                  >
                    {label}
                  </ThemedText>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>תאריך ושעת התחלה</ThemedText>
            <View style={styles.dateTimeContainer}>
              <TouchableOpacity
                style={styles.dateTimeButton}
                onPress={() => setShowStartDatePicker(true)}
              >
                <ThemedText>{formatDateDisplay(startDate)}</ThemedText>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.dateTimeButton}
                onPress={() => setShowStartTimePicker(true)}
              >
                <ThemedText>{formatTimeDisplay(startDate)}</ThemedText>
              </TouchableOpacity>
            </View>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={styles.label}>תאריך ושעת סיום</ThemedText>
            <View style={styles.dateTimeContainer}>
              <TouchableOpacity
                style={styles.dateTimeButton}
                onPress={() => setShowEndDatePicker(true)}
              >
                <ThemedText>{formatDateDisplay(endDate)}</ThemedText>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.dateTimeButton}
                onPress={() => setShowEndTimePicker(true)}
              >
                <ThemedText>{formatTimeDisplay(endDate)}</ThemedText>
              </TouchableOpacity>
            </View>
          </View>

          {/* Date/Time Pickers */}
          {(showStartDatePicker || showEndDatePicker) && (
            <DateTimePicker
              value={showStartDatePicker ? startDate : endDate}
              mode="date"
              onChange={(event, date) =>
                handleDateChangePicker(event, date, showStartDatePicker)
              }
              minimumDate={showEndDatePicker ? startDate : new Date()}
            />
          )}

          {(showStartTimePicker || showEndTimePicker) && (
            <DateTimePicker
              value={showStartTimePicker ? startDate : endDate}
              mode="time"
              onChange={(event, date) =>
                handleTimeChangePicker(event, date, showStartTimePicker)
              }
            />
          )}

          <View style={styles.modalActions}>
            <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
              <ThemedText style={styles.cancelButtonText}>ביטול</ThemedText>
            </TouchableOpacity>
            <TouchableOpacity style={styles.saveButton} onPress={handleSubmit}>
              <ThemedText style={styles.saveButtonText}>צור אירוע</ThemedText>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    </Modal>
  );
}

// Add this helper function
const formatDate = (date: string) => {
  try {
    return new Date(date).toLocaleString("he-IL", {
      weekday: "long",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch (error) {
    return date;
  }
};

export default function CalendarScreen() {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const { user, userRole } = useAuth();
  const [modalVisible, setModalVisible] = useState(false);
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(
    null
  );

  const [fontsLoaded, fontError] = useFonts({
    "Heebo-Regular": Heebo_400Regular,
    "Heebo-Bold": Heebo_700Bold,
  });

  useEffect(() => {
    loadEvents();
  }, [user?.uid]); // Add user.uid as dependency

  const loadEvents = async () => {
    if (!user?.uid) return; // Add guard clause

    try {
      setError(null);
      setRefreshing(true);

      const eventsRef = collection(db, "events");
      let q;

      if (userRole === "admin") {
        q = query(eventsRef, where("status", "==", "active"));
      } else {
        q = query(
          eventsRef,
          where("status", "==", "active"),
          where("participants", "array-contains", user.uid)
        );
      }

      const snapshot = await getDocs(q);
      const eventsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as CalendarEvent[];

      // Sort client-side
      eventsData.sort(
        (a, b) =>
          new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
      );

      setEvents(eventsData);
    } catch (error) {
      console.error("Error loading events:", error);
      setError("אירעה שגיאה בטעינת היומן");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  // Add onRefresh handler
  const onRefresh = useCallback(() => {
    loadEvents();
  }, [loadEvents]);

  const createEvent = async (
    eventData: Omit<CalendarEvent, "id" | "createdBy">
  ) => {
    try {
      if (!user?.uid) {
        Alert.alert("שגיאה", "משתמש לא מחובר");
        return;
      }

      const newEvent = {
        ...eventData,
        createdBy: user.uid,
        status: "active" as const,
        createdAt: new Date().toISOString(),
        participants: eventData.participants || [],
      };

      await addDoc(collection(db, "events"), newEvent);
      setModalVisible(false);
      await loadEvents();
      Alert.alert("הצלחה", "האירוע נוצר בהצלחה");
    } catch (error) {
      console.error("Error creating event:", error);
      Alert.alert("שגיאה", "אירעה שגיאה ביצירת האירוע");
    }
  };

  // Add handleEditEvent function
  const handleEditEvent = async (event: CalendarEvent) => {
    try {
      if (!user?.uid) {
        Alert.alert("שגיאה", "משתמש לא מחובר");
        return;
      }

      // Get event reference
      const eventRef = doc(db, "events", event.id);

      // Update event
      await updateDoc(eventRef, {
        ...event,
        updatedAt: new Date().toISOString(),
        lastModifiedBy: user.uid,
      });

      // Refresh events list
      await loadEvents();
      setSelectedEvent(null);
      Alert.alert("הצלחה", "האירוע עודכן בהצלחה");
    } catch (error) {
      console.error("Error editing event:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בעדכון האירוע");
    }
  };

  const handleDeleteEvent = async (event: CalendarEvent) => {
    try {
      if (!user?.uid) {
        Alert.alert("שגיאה", "משתמש לא מחובר");
        return;
      }

      await deleteDoc(doc(db, "events", event.id));
      setSelectedEvent(null);
      await loadEvents();
      Alert.alert("הצלחה", "האירוע נמחק בהצלחה");
    } catch (error) {
      console.error("Error deleting event:", error);
      Alert.alert("שגיאה", "אירעה שגיאה במחיקת האירוע");
    }
  };

  if (loading) {
    return (
      <View style={[styles.container, styles.centerContent]}>
        <ActivityIndicator size="large" color="#0066cc" />
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.container, styles.centerContent]}>
        <ThemedText style={styles.errorText}>{error}</ThemedText>
        <TouchableOpacity style={styles.retryButton} onPress={loadEvents}>
          <ThemedText style={styles.retryText}>נסה שוב</ThemedText>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={[styles.container, themed.contentBackground]}>
      <View style={[styles.header, themed.surfaceBackground]}>
        <ThemedText style={[styles.title, themed.text]}>יומן פעילות</ThemedText>
        {(userRole === "admin" || userRole === "instructor") && (
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => setModalVisible(true)}
          >
            <Plus size={24} color={themed.theme.primary} />
          </TouchableOpacity>
        )}
      </View>
      {events.length === 0 ? (
        <View style={styles.emptyState}>
          <ThemedText style={styles.emptyText}>
            אין אירועים בלוח השנה
          </ThemedText>
        </View>
      ) : (
        <FlatList
          data={events}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TouchableOpacity
              onPress={() => setSelectedEvent(item)}
              style={[styles.eventCard, themed.surfaceBackground]}
            >
              <View style={styles.eventHeader}>
                <ThemedText style={[styles.eventTitle, themed.text]}>
                  {item.title}
                </ThemedText>
                <ThemedText style={[styles.eventTime, themed.textSecondary]}>
                  {formatDate(item.startDate)}
                </ThemedText>
              </View>
              <ThemedText
                style={[styles.eventDescription, themed.textSecondary]}
              >
                {item.description}
              </ThemedText>
              <View style={styles.participantsRow}>
                <ThemedText
                  style={[styles.participantsCount, themed.textSecondary]}
                >
                  {item.participants.length} משתתפים
                </ThemedText>
              </View>
            </TouchableOpacity>
          )}
          refreshing={refreshing}
          onRefresh={onRefresh}
          contentContainerStyle={styles.listContent}
        />
      )}
      {userRole === "admin" && (
        <CreateEventModal
          visible={modalVisible}
          onClose={() => setModalVisible(false)}
          onSubmit={createEvent}
        />
      )}
      {selectedEvent && (
        <EventDetailsModal
          event={selectedEvent}
          visible={!!selectedEvent}
          onClose={() => setSelectedEvent(null)}
          canEdit={userRole === "admin"}
          onEdit={handleEditEvent}
          onDelete={userRole === "admin" ? handleDeleteEvent : undefined}
        />
      )}
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
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 24,
  },
  title: {
    fontFamily: "Heebo-Bold",
    fontSize: 28,
    textAlign: "right",
    color: "#333333",
  },
  subtitle: {
    fontFamily: "Heebo-Regular",
    fontSize: 16,
    textAlign: "right",
    color: "#666666",
    marginTop: 4,
  },
  eventsContainer: {
    marginTop: 24,
  },
  eventsTitle: {
    fontFamily: "Heebo-Bold",
    fontSize: 20,
    textAlign: "right",
    color: "#333333",
    marginBottom: 12,
  },
  eventCard: {
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 8,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  eventTitle: {
    fontFamily: "Heebo-Bold",
    fontSize: 16,
    color: "#333333",
  },
  eventTime: {
    fontFamily: "Heebo-Regular",
    fontSize: 14,
    color: "#666666",
    marginTop: 4,
  },
  eventDescription: {
    fontFamily: "Heebo-Regular",
    fontSize: 14,
    color: "#666666",
  },
  addButton: {
    backgroundColor: "#f0f9ff",
    borderRadius: 8,
    padding: 8,
  },
  centerContent: {
    justifyContent: "center",
    alignItems: "center",
  },
  errorText: {
    fontSize: 16,
    color: "#dc2626",
    marginBottom: 16,
    textAlign: "center",
  },
  retryButton: {
    padding: 12,
    backgroundColor: "#f3f4f6",
    borderRadius: 8,
  },
  retryText: {
    color: "#0066cc",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
  emptyState: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  emptyText: {
    fontSize: 16,
    color: "#666666",
  },
  eventHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 8,
  },
  participantsRow: {
    flexDirection: "row",
    justifyContent: "flex-end",
    marginTop: 8,
  },
  participantsCount: {
    fontSize: 14,
  },
  listContent: {
    paddingBottom: 20,
  },
  modalContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.5)",
  },
  modalContent: {
    width: "90%",
    backgroundColor: "#fff",
    borderRadius: 8,
    padding: 16,
  },
  modalTitle: {
    fontFamily: "Heebo-Bold",
    fontSize: 20,
    marginBottom: 16,
    textAlign: "center",
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontFamily: "Heebo-Regular",
    fontSize: 16,
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 8,
    fontSize: 16,
  },
  modalActions: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  cancelButton: {
    backgroundColor: "#f3f4f6",
    borderRadius: 8,
    padding: 12,
  },
  cancelButtonText: {
    fontFamily: "Heebo-Bold",
    fontSize: 16,
    color: "#333",
  },
  saveButton: {
    backgroundColor: "#0066cc",
    borderRadius: 8,
    padding: 12,
  },
  saveButtonText: {
    fontFamily: "Heebo-Bold",
    fontSize: 16,
    color: "#fff",
  },
  detailSection: {
    marginBottom: 16,
  },
  detailLabel: {
    fontFamily: "Heebo-Bold",
    fontSize: 16,
    marginBottom: 4,
  },
  detailText: {
    fontFamily: "Heebo-Regular",
    fontSize: 16,
  },
  participantsSection: {
    marginBottom: 16,
  },
  participantsList: {
    flexDirection: "row",
    flexWrap: "wrap",
  },
  participantChip: {
    backgroundColor: "#f0f9ff",
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
    margin: 4,
  },
  participantChipSelected: {
    backgroundColor: "#0066cc",
  },
  participantName: {
    fontSize: 14,
    color: "#0066cc",
  },
  closeButton: {
    backgroundColor: "#f3f4f6",
    borderRadius: 8,
    padding: 12,
    alignItems: "center",
  },
  closeButtonText: {
    fontFamily: "Heebo-Bold",
    fontSize: 16,
    color: "#333",
  },
  modalHeader: {
    marginBottom: 16,
    alignItems: "center",
    justifyContent: "space-between",
    flexDirection: "row",
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
  dateButton: {
    backgroundColor: "#f3f4f6",
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  timeButton: {
    backgroundColor: "#f3f4f6",
    padding: 12,
    borderRadius: 8,
  },
  dateTimeContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 8,
  },
  dateTimeButton: {
    flex: 1,
    backgroundColor: "#f3f4f6",
    padding: 12,
    borderRadius: 8,
    alignItems: "center",
  },
  headerActions: {
    flexDirection: "row",
    gap: 16,
    alignItems: "center",
  },
});
