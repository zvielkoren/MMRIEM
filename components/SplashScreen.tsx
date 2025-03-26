import { View, ActivityIndicator, StyleSheet } from "react-native";
import { ThemedText } from "./ThemedText";

export function SplashScreen() {
  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color="#0066cc" />
      <ThemedText style={styles.text}>טוען...</ThemedText>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#fff",
  },
  text: {
    marginTop: 16,
    fontSize: 16,
    fontFamily: "Heebo-Regular",
  },
});
