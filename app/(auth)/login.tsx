import React, { useState } from "react";
import {
  View,
  StyleSheet,
  ActivityIndicator,
  Platform,
  TouchableOpacity,
  Image,
  Alert,
  SafeAreaView,
  KeyboardAvoidingView,
  ScrollView,
} from "react-native";
import { ThemedText } from "@/components/ThemedText";
import { TextInput } from "react-native";
import {
  auth,
  recaptchaVerifier,
  getPhoneProvider,
  phoneAuth,
} from "@/firebase/config";
import {
  signInWithEmailAndPassword,
  PhoneAuthProvider,
  signInWithCredential,
  RecaptchaVerifier,
} from "firebase/auth";
import { useRouter } from "expo-router";
import { db } from "@/config/firebase";
import { Mail, Lock, Phone } from "lucide-react-native";
import { getDeviceId } from "@/utils/device";
import { doc, setDoc } from "firebase/firestore";
import { useAuth } from "../../contexts/AuthContext";
import { Ionicons } from "@expo/vector-icons";

const formatPhoneInput = (input: string): string => {
  // Remove all non-digit characters except the first 0
  const firstChar = input.charAt(0);
  const rest = input.slice(1).replace(/\D/g, "");
  const digits = firstChar === "0" ? "0" + rest : rest;

  // Return only digits
  return digits;
};

const LoginScreen = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [loginMethod, setLoginMethod] = useState<"email" | "phone">("email");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [verificationId, setVerificationId] = useState("");
  const [verificationCode, setVerificationCode] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const router = useRouter();
  const { signInWithPhone, verifyPhoneCode, loading } = useAuth();

  const handlePhoneChange = (text: string) => {
    const formatted = formatPhoneInput(text);
    setPhoneNumber(formatted);
  };

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const validateInputs = () => {
    if (loginMethod === "email") {
      if (!email || !password) {
        setError("נא למלא את כל השדות");
        return false;
      }
      if (!validateEmail(email)) {
        setError("נא להזין כתובת אימייל תקינה");
        return false;
      }
      return true;
    }
    return true;
  };

  const handleLogin = async () => {
    if (!validateInputs()) {
      return;
    }

    try {
      setError("");
      setIsLoading(true);
      console.log("Login attempt with:", email);

      const userCredential = await signInWithEmailAndPassword(
        auth,
        email.trim(),
        password
      );
      console.log("Login successful:", userCredential.user.uid);

      // Create session
      const sessionId = Math.random().toString(36).slice(2);
      await setDoc(doc(db, "sessions", sessionId), {
        id: sessionId,
        userId: userCredential.user.uid,
        deviceInfo: {
          platform: Platform.OS,
          deviceId: await getDeviceId(),
        },
        lastActive: new Date().toISOString(),
        createdAt: new Date().toISOString(),
        expiresAt: new Date(
          Date.now() + 30 * 24 * 60 * 60 * 1000
        ).toISOString(),
        isValid: true,
      });

      router.replace("/(tabs)/profile");
    } catch (error: any) {
      console.error("Login error:", error);
      setError("שגיאה בהתחברות. נסה שוב");
    } finally {
      setIsLoading(false);
    }
  };

  const handlePhoneLogin = async () => {
    try {
      if (!phoneNumber) {
        Alert.alert("שגיאה", "נא להזין מספר טלפון");
        return;
      }

      await signInWithPhone(phoneNumber);
      setIsVerifying(true);
    } catch (error) {
      Alert.alert(
        "שגיאה",
        error instanceof Error ? error.message : "שגיאה בהתחברות"
      );
    }
  };

  const handleVerifyCode = async () => {
    try {
      if (!verificationCode) {
        Alert.alert("שגיאה", "נא להזין קוד אימות");
        return;
      }

      await verifyPhoneCode(verificationCode);
      router.replace("/(tabs)");
    } catch (error) {
      Alert.alert(
        "שגיאה",
        error instanceof Error ? error.message : "שגיאה באימות הקוד"
      );
    }
  };

  const handleRegister = () => {
    router.push("/(auth)/register");
  };

  const handleSubmit = () => {
    if (loginMethod === "email") {
      handleLogin();
    } else if (!isVerifying) {
      handlePhoneLogin();
    } else {
      handleVerifyCode();
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={styles.container}
      >
        <ScrollView contentContainerStyle={styles.scrollView}>
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

            <View style={styles.loginMethodToggle}>
              <TouchableOpacity
                style={[
                  styles.methodButton,
                  loginMethod === "email" && styles.methodButtonActive,
                ]}
                onPress={() => setLoginMethod("email")}
              >
                <ThemedText>התחברות עם אימייל</ThemedText>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.methodButton,
                  loginMethod === "phone" && styles.methodButtonActive,
                ]}
                onPress={() => setLoginMethod("phone")}
              >
                <ThemedText>התחברות עם טלפון</ThemedText>
              </TouchableOpacity>
            </View>

            {loginMethod === "email" ? (
              <>
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
                    onSubmitEditing={handleSubmit}
                    returnKeyType="go"
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
                    onSubmitEditing={handleSubmit}
                    returnKeyType="go"
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
                    <ThemedText style={styles.loginButtonText}>
                      התחבר
                    </ThemedText>
                  )}
                </TouchableOpacity>
              </>
            ) : (
              <>
                {!isVerifying ? (
                  <View style={styles.inputContainer}>
                    <Phone size={20} color="#666666" />
                    <TextInput
                      style={styles.input}
                      placeholder="מספר טלפון"
                      value={phoneNumber}
                      onChangeText={handlePhoneChange}
                      keyboardType="phone-pad"
                      maxLength={12} // 05X-XXX-XXXX
                    />
                  </View>
                ) : (
                  <View style={styles.inputContainer}>
                    <TextInput
                      style={styles.input}
                      placeholder="קוד אימות"
                      value={verificationCode}
                      onChangeText={setVerificationCode}
                      keyboardType="number-pad"
                      maxLength={6}
                      onSubmitEditing={handleSubmit}
                      returnKeyType="go"
                    />
                  </View>
                )}

                <TouchableOpacity
                  style={styles.loginButton}
                  onPress={isVerifying ? handleVerifyCode : handlePhoneLogin}
                  disabled={loading}
                >
                  <ThemedText style={styles.loginButtonText}>
                    {isVerifying ? "אמת קוד" : "קבל קוד אימות"}
                  </ThemedText>
                </TouchableOpacity>

                {isVerifying && (
                  <TouchableOpacity
                    style={styles.backButton}
                    onPress={() => setIsVerifying(false)}
                  >
                    <Ionicons name="arrow-back" size={24} color="#007AFF" />
                    <ThemedText style={styles.backButtonText}>חזרה</ThemedText>
                  </TouchableOpacity>
                )}
              </>
            )}
          </View>

          <View style={styles.footer}>
            <View style={styles.footerContent}>
              <ThemedText style={styles.footerText}>
                עדיין אין לך חשבון?
              </ThemedText>
              <TouchableOpacity onPress={handleRegister}>
                <ThemedText style={styles.registerLink}>הירשם עכשיו</ThemedText>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#ffffff",
  },
  container: {
    flex: 1,
    padding: 20,
  },
  scrollView: {
    flexGrow: 1,
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
  footerContent: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
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
  loginMethodToggle: {
    flexDirection: "row",
    marginBottom: 20,
    backgroundColor: "#f5f5f5",
    borderRadius: 12,
    padding: 4,
  },
  methodButton: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    alignItems: "center",
  },
  methodButtonActive: {
    backgroundColor: "#ffffff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  backButton: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 20,
  },
  backButtonText: {
    color: "#007AFF",
    fontSize: 16,
    marginRight: 5,
  },
});

export default LoginScreen;
