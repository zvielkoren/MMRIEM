import { Platform } from "react-native";
import * as Application from "expo-application";

export async function getDeviceId(): Promise<string> {
  if (Platform.OS === "web") {
    return navigator.userAgent;
  }

  return (
    (await Application.getAndroidId()) ||
    (await Application.getIosIdForVendorAsync()) ||
    "unknown"
  );
}
