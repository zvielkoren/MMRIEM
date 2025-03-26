import React, { useState } from "react";
import {
  View,
  StyleSheet,
  ActivityIndicator,
  Platform,
  TouchableOpacity,
  Image,
} from "react-native";
import { ThemedText } from "@/components/ThemedText";
import { TextInput } from "react-native";
import { auth } from "@/config/firebase";
import { signInWithEmailAndPassword } from "firebase/auth";
import { useRouter } from "expo-router";
import { doc, setDoc } from "firebase/firestore";
import { db } from "@/config/firebase";
import { Mail, Lock } from "lucide-react-native";
import { getDeviceId } from "@/utils/device";

export default function LoginScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const validateInputs = () => {
    if (!email || !password) {
      setError("נא למלא את כל השדות");
      return false;
    }
    if (!email.includes("@")) {
      setError("נא להזין כתובת אימייל תקינה");
      return false;
    }
    return true;
  };

  const createSession = async (userId: string) => {
    const sessionId = Math.random().toString(36).slice(2);
    await setDoc(doc(db, "sessions", sessionId), {
      id: sessionId,
      userId,
      deviceInfo: {
        platform: Platform.OS,
        deviceId: await getDeviceId(),
      },
      lastActive: new Date().toISOString(),
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      isValid: true,
    });
  };

  const handleLogin = async () => {
    try {
      setError("");
      if (!validateInputs()) return;

      setIsLoading(true);
      const userCredential = await signInWithEmailAndPassword(
        auth,
        email.trim(),
        password
      );
      await createSession(userCredential.user.uid);
      router.replace("/(tabs)/calendar");
    } catch (err: any) {
      switch (err.code) {
        case "auth/invalid-email":
          setError("פורמט אימייל לא תקין");
          break;
        case "auth/user-disabled":
          setError("המשתמש חסום");
          break;
        case "auth/user-not-found":
          setError("משתמש לא קיים");
          break;
        case "auth/wrong-password":
          setError("סיסמה שגויה");
          break;
        default:
          setError("שגיאה בהתחברות. נסה שוב");
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegister = () => {
    router.push("/(auth)/register");
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Image
          source={require("@/assets/images/logo.png")}
          style={styles.logo}
          resizeMode="contain"
        />
        <ThemedText style={styles.title}>ברוכים הבאים</ThemedText>
        <ThemedText style={styles.subtitle}>התחבר למערכת</ThemedText>
      </View>

      <View style={styles.form}>
        {error && <ThemedText style={styles.error}>{error}</ThemedText>}

        <View style={styles.inputContainer}>
          <Mail size={20} color="#666666" />
          <TextInput
            style={styles.input}
            placeholder="אימייל"
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
            keyboardType="email-address"
            editable={!isLoading}
          />
        </View>

        <View style={styles.inputContainer}>
          <Lock size={20} color="#666666" />
          <TextInput
            style={styles.input}
            placeholder="סיסמה"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            editable={!isLoading}
          />
        </View>

        <TouchableOpacity
          style={styles.loginButton}
          onPress={handleLogin}
          disabled={isLoading}
        >
          {isLoading ? (
            <ActivityIndicator color="#ffffff" />
          ) : (
            <ThemedText style={styles.loginButtonText}>התחבר</ThemedText>
          )}
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <ThemedText style={styles.footerText}>עדיין אין לך חשבון? </ThemedText>
        <TouchableOpacity onPress={handleRegister}>
          <ThemedText style={styles.registerLink}>הירשם עכשיו</ThemedText>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#ffffff",
    padding: 20,
  },
  header: {
    alignItems: "center",
    marginVertical: 40,
  },
  logo: {
    width: 120,
    height: 120,
    marginBottom: 16,
  },
  title: {
    fontSize: 32,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: "#666666",
    fontFamily: "Heebo-Regular",
  },
  form: {
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 16,
  },
  inputContainer: {
    flexDirection: "row-reverse",
    alignItems: "center",
    backgroundColor: "#f5f5f5",
    borderRadius: 12,
    paddingHorizontal: 16,
    marginBottom: 16,
    height: 56,
  },
  input: {
    flex: 1,
    height: "100%",
    marginRight: 12,
    fontFamily: "Heebo-Regular",
    textAlign: "right",
    fontSize: 16,
  },
  loginButton: {
    backgroundColor: "#0066cc",
    borderRadius: 12,
    height: 56,
    justifyContent: "center",
    alignItems: "center",
    marginTop: 24,
  },
  loginButtonText: {
    color: "#ffffff",
    fontSize: 18,
    fontFamily: "Heebo-Bold",
  },
  error: {
    color: "#dc2626",
    textAlign: "center",
    marginBottom: 16,
    fontFamily: "Heebo-Regular",
  },
  footer: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    paddingVertical: 20,
  },
  footerText: {
    color: "#666666",
    fontSize: 16,
    fontFamily: "Heebo-Regular",
  },
  registerLink: {
    color: "#0066cc",
    fontSize: 16,
    fontFamily: "Heebo-Bold",
  },
});
