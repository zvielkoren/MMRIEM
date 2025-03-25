import { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Image,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  SafeAreaView,
} from "react-native";
import { Link, router } from "expo-router";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { auth, db } from "@/firebase.config";
import { UserPlus, Mail, Lock, User } from "lucide-react-native";

export default function RegisterScreen() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [role, setRole] = useState<UserRole>("user");

  const handleRegister = async () => {
    try {
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        email,
        password
      );

      // Create user document with role
      await setDoc(doc(db, "users", userCredential.user.uid), {
        email,
        name,
        role,
        createdAt: new Date().toISOString(),
      });

      router.replace("/(tabs)");
    } catch (err) {
      setError("שגיאה בהרשמה. אנא בדקו את הפרטים ונסו שוב.");
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={styles.container}
      >
        <ScrollView contentContainerStyle={styles.scrollView}>
          <Image
            source={{
              uri: "https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?w=800",
            }}
            style={styles.backgroundImage}
          />
          <View style={styles.formContainer}>
            <View style={styles.header}>
              <UserPlus size={32} color="#0066cc" />
              <Text style={styles.title}>הרשמה</Text>
              <Text style={styles.subtitle}>צור חשבון חדש</Text>
            </View>

            <View style={styles.inputContainer}>
              <User size={20} color="#666666" />
              <TextInput
                style={styles.input}
                placeholder="שם מלא"
                value={name}
                onChangeText={setName}
                textContentType="name"
                autoComplete="name"
              />
            </View>

            <View style={styles.inputContainer}>
              <Mail size={20} color="#666666" />
              <TextInput
                style={styles.input}
                placeholder="אימייל"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
                textContentType="emailAddress"
                autoComplete="email"
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
                textContentType="newPassword"
                autoComplete="new-password"
              />
            </View>

            <View style={styles.inputContainer}>
              <Picker
                selectedValue={role}
                onValueChange={(value) => setRole(value)}
                style={styles.input}
              >
                {Object.entries(ROLE_LABELS).map(([key, label]) => (
                  <Picker.Item key={key} label={label} value={key} />
                ))}
              </Picker>
            </View>

            {error ? <Text style={styles.error}>{error}</Text> : null}

            <TouchableOpacity
              style={styles.button}
              onPress={handleRegister}
              activeOpacity={0.8}
            >
              <Text style={styles.buttonText}>הרשמה</Text>
            </TouchableOpacity>

            <View style={styles.footer}>
              <Text style={styles.footerText}>כבר יש לך חשבון? </Text>
              <Link href="/login" style={styles.link}>
                התחבר כאן
              </Link>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#ffffff",
  },
  container: {
    flex: 1,
  },
  scrollView: {
    flexGrow: 1,
  },
  backgroundImage: {
    width: "100%",
    height: Platform.OS === "web" ? 300 : 250,
    resizeMode: "cover",
  },
  formContainer: {
    flex: 1,
    backgroundColor: "#ffffff",
    borderTopRightRadius: 30,
    borderTopLeftRadius: 30,
    marginTop: -30,
    padding: 24,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: -3,
    },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
  },
  header: {
    alignItems: "center",
    marginBottom: 32,
    marginTop: 16,
  },
  title: {
    fontSize: 28,
    fontFamily: "Heebo-Bold",
    color: "#333333",
    marginTop: 16,
  },
  subtitle: {
    fontSize: 16,
    color: "#666666",
    marginTop: 8,
    fontFamily: "Heebo-Regular",
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
  button: {
    backgroundColor: "#0066cc",
    borderRadius: 12,
    height: 56,
    justifyContent: "center",
    alignItems: "center",
    marginTop: 16,
    shadowColor: "#0066cc",
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 3,
  },
  buttonText: {
    color: "#ffffff",
    fontSize: 18,
    fontFamily: "Heebo-Bold",
  },
  error: {
    color: "#dc2626",
    textAlign: "right",
    marginBottom: 16,
    fontFamily: "Heebo-Regular",
    fontSize: 14,
  },
  footer: {
    flexDirection: "row-reverse",
    justifyContent: "center",
    marginTop: 24,
    paddingVertical: 16,
  },
  footerText: {
    color: "#666666",
    fontFamily: "Heebo-Regular",
    fontSize: 16,
  },
  link: {
    color: "#0066cc",
    fontFamily: "Heebo-Bold",
    fontSize: 16,
  },
});
