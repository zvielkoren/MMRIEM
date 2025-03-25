import { useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import NetInfo from "@react-native-community/netinfo";
import { db } from "../config/firebase";

export const useOfflineSync = <T>(collection: string, id: string) => {
  const [data, setData] = useState<T | null>(null);
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsOnline(!!state.isConnected);
    });

    return () => unsubscribe();
  }, []);

  const saveLocally = async (data: T) => {
    try {
      await AsyncStorage.setItem(`${collection}_${id}`, JSON.stringify(data));
    } catch (error) {
      console.error("Error saving locally:", error);
    }
  };

  const syncToFirebase = async () => {
    if (!isOnline) return;

    try {
      const localData = await AsyncStorage.getItem(`${collection}_${id}`);
      if (localData) {
        // Sync to Firebase
        // Implementation depends on your specific needs
      }
    } catch (error) {
      console.error("Error syncing to Firebase:", error);
    }
  };

  return { data, saveLocally, syncToFirebase, isOnline };
};
