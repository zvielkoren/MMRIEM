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
import { ThemedText } from "@/components/ThemedText";
import { useAuth } from "@/contexts/AuthContext";
import {
  collection,
  query,
  getDocs,
  where,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { Calendar, Plus, Edit, Trash2 } from "lucide-react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";
import DateTimePicker from "@react-native-community/datetimepicker";
import { USER_GROUPS, UserGroup } from "@/utils/dbTemplate";
import {
  useFonts,
  Heebo_400Regular,
  Heebo_700Bold,
} from "@expo-google-fonts/heebo";

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
}

interface CreateEventModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (event: Omit<CalendarEvent, "id" | "createdBy">) => void;
}

function CreateEventModal({
  visible,
  onClose,
  onSubmit,
}: CreateEventModalProps) {
  // ...existing state...
  const [showStartDatePicker, setShowStartDatePicker] = useState(false);
  const [showEndDatePicker, setShowEndDatePicker] = useState(false);
  const [showStartTimePicker, setShowStartTimePicker] = useState(false);
  const [showEndTimePicker, setShowEndTimePicker] = useState(false);

  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());

  const formatDateDisplay = (date: Date) => {
    return date.toLocaleDateString("he-IL", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const handleDateTimeChange = (
    event: any,
    selectedDate?: Date,
    isStart = true,
    isTime = false
  ) => {
    if (Platform.OS === "android") {
      setShowStartDatePicker(false);
      setShowEndDatePicker(false);
      setShowStartTimePicker(false);
      setShowEndTimePicker(false);
    }

    if (selectedDate) {
      const targetDate = isStart ? new Date(startDate) : new Date(endDate);

      if (isTime) {
        targetDate.setHours(selectedDate.getHours());
        targetDate.setMinutes(selectedDate.getMinutes());
      } else {
        targetDate.setFullYear(selectedDate.getFullYear());
        targetDate.setMonth(selectedDate.getMonth());
        targetDate.setDate(selectedDate.getDate());
      }

      if (isStart) {
        setStartDate(targetDate);
        if (endDate < targetDate) {
          setEndDate(targetDate);
        }
      } else {
        if (targetDate >= startDate) {
          setEndDate(targetDate);
        } else {
          Alert.alert("שגיאה", "זמן הסיום חייב להיות אחרי זמן ההתחלה");
        }
      }
    }
  };

  // ...rest of component...
}

export default function CalendarScreen() {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const { user, userRole } = useAuth();
  const [modalVisible, setModalVisible] = useState(false);
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);

  useEffect(() => {
    loadEvents();
  }, [user?.uid]);

  const loadEvents = async () => {
    if (!user?.uid) return;

    try {
      const eventsRef = collection(db, "events");
      let q = query(eventsRef, where("status", "==", "active"));

      const snapshot = await getDocs(q);
      const eventsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as CalendarEvent[];

      setEvents(
        eventsData.sort(
          (a, b) =>
            new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
        )
      );
    } catch (error) {
      console.error("Error loading events:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בטעינת היומן");
    } finally {
      setLoading(false);
    }
  };

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

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#0066cc" />
      </View>
    );
  }

  return (
    <View style={[styles.container, themed.contentBackground]}>
      <View style={styles.header}>
        <Calendar size={24} color={themed.theme.text} />
        <ThemedText style={styles.title}>לוח אירועים</ThemedText>
      </View>

      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.eventCard}>
            <ThemedText style={styles.eventTitle}>{item.title}</ThemedText>
            <ThemedText style={styles.eventDate}>
              {new Date(item.startDate).toLocaleDateString("he-IL")}
            </ThemedText>
          </TouchableOpacity>
        )}
      />

      {(userRole === "admin" || userRole === "instructor") && (
        <TouchableOpacity
          style={styles.fab}
          onPress={() => setModalVisible(true)}
        >
          <Plus size={24} color="#fff" />
        </TouchableOpacity>
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
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
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
  eventCard: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  eventTitle: {
    fontSize: 16,
    fontFamily: "Heebo-Bold",
    color: "#333",
  },
  eventDate: {
    fontSize: 14,
    color: "#666",
    marginTop: 4,
  },
  fab: {
    position: "absolute",
    bottom: 24,
    right: 24,
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
});
function setStartDate(targetDate: Date) {
    throw new Error("Function not implemented.");
}

