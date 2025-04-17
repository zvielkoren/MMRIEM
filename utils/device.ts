import { Platform } from "react-native";
import * as Application from "expo-application";
import * as Device from "expo-device";

export const getDeviceId = async (): Promise<string> => {
  try {
    if (Platform.OS === "android") {
      const androidId = await Application.getAndroidId();
      return androidId || Device.modelName || "unknown-android";
    } else if (Platform.OS === "ios") {
      const iosId = await Application.getIosIdForVendorAsync();
      return iosId || Device.modelName || "unknown-ios";
    }
    return Device.modelName || "unknown";
  } catch (error) {
    console.warn("Failed to get device ID:", error);
    return Device.modelName || "unknown";
  }
};
