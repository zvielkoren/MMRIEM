import React from "react";
import { View, StyleSheet } from "react-native";
import { Calendar as RNCalendar } from "react-native-calendars";
import { Event } from "../../types/models";

interface CalendarViewProps {
  events: Event[];
  onDayPress: (date: Date) => void;
}

export const CalendarView: React.FC<CalendarViewProps> = ({
  events,
  onDayPress,
}) => {
  return (
    <View style={styles.container}>
      <RNCalendar
        onDayPress={(day) => onDayPress(new Date(day.timestamp))}
        markedDates={events.reduce(
          (acc, event) => ({
            ...acc,
            [event.date.toISOString().split("T")[0]]: { marked: true },
          }),
          {}
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
