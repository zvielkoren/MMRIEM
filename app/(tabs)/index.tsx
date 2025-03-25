import { View, StyleSheet } from "react-native";
import {
  useFonts,
  Heebo_400Regular,
  Heebo_700Bold,
} from "@expo-google-fonts/heebo";
import { useEffect, useState } from "react";
import { SplashScreen } from "expo-router";
import { Calendar } from "react-native-calendars";
import { ThemedText } from "@/components/ThemedText";
import { useAuth } from "@/contexts/AuthContext";
import { collection, query, getDocs, where } from "firebase/firestore";
import { db } from "@/config/firebase";

export default function CalendarScreen() {
  const [events, setEvents] = useState<any[]>([]);
  const { user } = useAuth();
  const [selectedDate, setSelectedDate] = useState(
    new Date().toISOString().split("T")[0]
  );

  const [fontsLoaded, fontError] = useFonts({
    "Heebo-Regular": Heebo_400Regular,
    "Heebo-Bold": Heebo_700Bold,
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    if (!user) return;
    const eventsRef = collection(db, "events");
    const eventsQuery = query(
      eventsRef,
      where("participants", "array-contains", user.uid)
    );
    const snapshot = await getDocs(eventsQuery);
    setEvents(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
  };

  const markedDates = events.reduce(
    (acc, event) => ({
      ...acc,
      [event.startDate.split("T")[0]]: { marked: true, dotColor: "#0066cc" },
    }),
    {
      [selectedDate]: { selected: true, selectedColor: "#0066cc" },
    }
  );

  if (!fontsLoaded && !fontError) {
    return null;
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <ThemedText style={styles.title}>יומן פעילות</ThemedText>
        <ThemedText style={styles.subtitle}>
          תכנון ומעקב אחר פעילויות
        </ThemedText>
      </View>

      <View style={styles.calendarContainer}>
        <Calendar
          style={styles.calendar}
          markedDates={markedDates}
          onDayPress={(day) => setSelectedDate(day.dateString)}
          theme={{
            textDayFontFamily: "Heebo-Regular",
            textMonthFontFamily: "Heebo-Bold",
            textDayHeaderFontFamily: "Heebo-Regular",
            todayTextColor: "#0066cc",
            selectedDayBackgroundColor: "#0066cc",
          }}
        />
      </View>

      <View style={styles.eventsContainer}>
        <ThemedText style={styles.eventsTitle}>אירועים היום</ThemedText>
        {events
          .filter((event) => event.startDate.startsWith(selectedDate))
          .map((event) => (
            <View key={event.id} style={styles.eventCard}>
              <ThemedText style={styles.eventTitle}>{event.title}</ThemedText>
              <ThemedText style={styles.eventTime}>
                {new Date(event.startDate).toLocaleTimeString("he-IL")}
              </ThemedText>
            </View>
          ))}
      </View>
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
  calendarContainer: {
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  calendar: {
    borderRadius: 12,
  },
  eventsContainer: {
    marginTop: 24,
  },
  eventsTitle: {
    fontFamily: "Heebo-Bold",
    fontSize: 20,
    marginBottom: 12,
    textAlign: "right",
    color: "#333333",
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
  },
});
