import { Platform } from "react-native";
import * as Application from "expo-application";

export async function getDeviceId(): Promise<string> {
  if (Platform.OS === "web") {
    return navigator.userAgent;
  }

  return (
    Application.androidId ||
    (await Application.getIosIdForVendorAsync()) ||
    "unknown"
  );
}
