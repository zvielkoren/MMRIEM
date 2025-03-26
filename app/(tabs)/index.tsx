import {
  View,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
} from "react-native";
import {
  useFonts,
  Heebo_400Regular,
  Heebo_700Bold,
} from "@expo-google-fonts/heebo";
import { useEffect, useState } from "react";
import { ThemedText } from "@/components/ThemedText";
import { useAuth } from "@/contexts/AuthContext";
import {
  collection,
  query,
  getDocs,
  where,
  addDoc,
  orderBy,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { Plus } from "react-native-feather";
import { useTheme } from "@/contexts/ThemeContext";
import { getThemedStyles } from "@/utils/theme";

interface CalendarEvent {
  id: string;
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  participants: string[];
  createdBy: string;
  status: "active" | "cancelled";
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
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);

  // ...rest of modal implementation...
}

export default function CalendarScreen() {
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const { user, userRole } = useAuth();
  const [modalVisible, setModalVisible] = useState(false);
  const { isDark } = useTheme();
  const themed = getThemedStyles(isDark);

  const [fontsLoaded, fontError] = useFonts({
    "Heebo-Regular": Heebo_400Regular,
    "Heebo-Bold": Heebo_700Bold,
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const eventsRef = collection(db, "events");
      let q;

      if (userRole === "admin") {
        // Admins see all events
        q = query(eventsRef, orderBy("createdAt", "desc"));
      } else {
        // Users see only events they're part of
        q = query(
          eventsRef,
          where("status", "==", "active"),
          where("participants", "array-contains", user?.uid)
        );
      }

      const snapshot = await getDocs(q);
      const eventsData = snapshot.docs.map(
        (doc) =>
          ({
            id: doc.id,
            ...doc.data(),
          } as CalendarEvent)
      );

      setEvents(eventsData);
    } catch (error) {
      console.error("Error loading events:", error);
      Alert.alert("שגיאה", "אירעה שגיאה בטעינת היומן");
    }
  };

  const createEvent = async (
    eventData: Omit<CalendarEvent, "id" | "createdBy">
  ) => {
    try {
      const newEvent = {
        ...eventData,
        createdBy: user?.uid,
        status: "active",
        createdAt: new Date().toISOString(),
      };

      await addDoc(collection(db, "events"), newEvent);
      await loadEvents();
      Alert.alert("הצלחה", "האירוע נוצר בהצלחה");
    } catch (error) {
      console.error("Error creating event:", error);
      Alert.alert("שגיאה", "אירעה שגיאה ביצירת האירוע");
    }
  };

  if (!fontsLoaded && !fontError) {
    return null;
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

      <FlatList
        data={events}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={[styles.eventCard, themed.surfaceBackground]}>
            <ThemedText style={[styles.eventTitle, themed.text]}>
              {item.title}
            </ThemedText>
            <ThemedText style={[styles.eventDescription, themed.textSecondary]}>
              {item.description}
            </ThemedText>
            <ThemedText style={[styles.eventTime, themed.textSecondary]}>
              {new Date(item.startDate).toLocaleString("he-IL")}
            </ThemedText>
          </View>
        )}
      />

      {userRole === "admin" && (
        <CreateEventModal
          visible={modalVisible}
          onClose={() => setModalVisible(false)}
          onSubmit={createEvent}
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
});
