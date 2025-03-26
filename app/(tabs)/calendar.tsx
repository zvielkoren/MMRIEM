import React, { useEffect, useState, useCallback } from "react";
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
// ...existing imports...

function CreateEventModal({
  visible,
  onClose,
  onSubmit,
}: CreateEventModalProps) {
  // ...existing state...

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

// ...rest of file...

export default function CalendarScreen() {
  // Copy all the code from the CalendarScreen component in index.tsx
  // ...existing CalendarScreen code...
}

const styles = StyleSheet.create({
  // Copy all styles from index.tsx
  // ...existing styles...
});
