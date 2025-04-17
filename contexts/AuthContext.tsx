import React, { createContext, useContext, useEffect, useState } from "react";
import { auth, db } from "../config/firebase";
import {
  User as FirebaseUser,
  PhoneAuthProvider,
  signInWithCredential,
} from "firebase/auth";
import { doc, getDoc, updateDoc } from "firebase/firestore";
import { UserRole } from "@/types/roles";
import { DBUser } from "@/utils/dbTemplate";
import * as Network from "expo-network";
import * as WebBrowser from "expo-web-browser";
import { Platform } from "react-native";

interface AuthContextType {
  user: FirebaseUser | null;
  loading: boolean;
  userRole: UserRole | null;
  userData: DBUser | null;
  error: string | null;
  isOnline: boolean;
  refreshAuth: () => Promise<void>;
  hasPermission: (requiredRole: UserRole | UserRole[]) => boolean;
  signInWithPhone: (phoneNumber: string) => Promise<void>;
  verifyPhoneCode: (verificationId: string, code: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  userRole: null,
  userData: null,
  error: null,
  isOnline: true,
  refreshAuth: async () => {},
  hasPermission: () => false,
  signInWithPhone: async () => {},
  verifyPhoneCode: async () => {},
});

const formatPhoneNumber = (phoneNumber: string): string => {
  // Remove all non-digit characters
  const digits = phoneNumber.replace(/\D/g, "");

  // If number already has country code, return as is
  if (digits.startsWith("972")) {
    return `+${digits}`;
  }

  // If number starts with 0, remove it and add country code
  if (digits.startsWith("0")) {
    return `+972${digits.slice(1)}`;
  }

  // If number is 9 digits, assume it's an Israeli number without 0
  if (digits.length === 9) {
    return `+972${digits}`;
  }

  // If number is 10 digits, assume it's an Israeli number with 0
  if (digits.length === 10) {
    return `+972${digits.slice(1)}`;
  }

  // If we can't determine the format, return the original number
  return phoneNumber;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<UserRole | null>(null);
  const [userData, setUserData] = useState<DBUser | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isOnline, setIsOnline] = useState(true);
  const [verificationId, setVerificationId] = useState<string | null>(null);

  const hasPermission = (requiredRole: UserRole | UserRole[]): boolean => {
    if (!userRole) return false;

    if (Array.isArray(requiredRole)) {
      return requiredRole.includes(userRole);
    }

    return userRole === requiredRole;
  };

  const refreshAuth = async () => {
    try {
      setLoading(true);
      setError(null);
      const currentUser = auth.currentUser;

      if (currentUser) {
        const userDoc = await getDoc(doc(db, "users", currentUser.uid));
        if (userDoc.exists()) {
          const userData = userDoc.data() as DBUser;
          setUser(currentUser);
          setUserRole(userData.role);
          setUserData(userData);

          await updateDoc(doc(db, "users", currentUser.uid), {
            lastLogin: new Date().toISOString(),
          });
        } else {
          throw new Error("משתמש לא נמצא");
        }
      }
    } catch (error) {
      setError(error instanceof Error ? error.message : "אירעה שגיאה");
      await auth.signOut();
      setUser(null);
      setUserRole(null);
      setUserData(null);
    } finally {
      setLoading(false);
    }
  };

  const signInWithPhone = async (phoneNumber: string) => {
    try {
      setLoading(true);
      setError(null);

      const formattedPhone = formatPhoneNumber(phoneNumber);
      console.log("Formatted phone number:", formattedPhone);

      if (Platform.OS === "web") {
        // Use reCAPTCHA for web
        const provider = new PhoneAuthProvider(auth);
        const verificationId = await provider.verifyPhoneNumber(
          formattedPhone,
          window.recaptchaVerifier
        );
        setVerificationId(verificationId);
      } else {
        // Use native phone auth for mobile
        const provider = new PhoneAuthProvider(auth);
        const verificationId = await provider.verifyPhoneNumber(formattedPhone);
        setVerificationId(verificationId);
      }
    } catch (error) {
      setError(
        error instanceof Error ? error.message : "שגיאה בהתחברות עם טלפון"
      );
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const verifyPhoneCode = async (verificationId: string, code: string) => {
    try {
      setLoading(true);
      setError(null);

      const credential = PhoneAuthProvider.credential(verificationId, code);
      const userCredential = await signInWithCredential(auth, credential);

      // Check if user exists in Firestore
      const userDoc = await getDoc(doc(db, "users", userCredential.user.uid));

      if (!userDoc.exists()) {
        // Create new user document if doesn't exist
        const newUser = await createNewUser(
          userCredential,
          userCredential.user.phoneNumber!
        );
        setUserData(newUser);
      } else {
        const userData = userDoc.data() as DBUser;
        setUserData(userData);
      }

      setUser(userCredential.user);
      setUserRole(userData?.role || UserRole.User);
    } catch (error) {
      setError(error instanceof Error ? error.message : "שגיאה באימות הקוד");
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const createNewUser = async (
    userCredential: FirebaseUser,
    phoneNumber: string
  ) => {
    const newUser: DBUser = {
      uid: userCredential.uid,
      phoneNumber,
      role: UserRole.User,
      createdAt: new Date().toISOString(),
      lastLogin: new Date().toISOString(),
    };

    await updateDoc(doc(db, "users", userCredential.uid), newUser);
    return newUser;
  };

  useEffect(() => {
    const checkNetwork = async () => {
      try {
        const networkState = await Network.getNetworkStateAsync();
        setIsOnline(networkState.isConnected);
      } catch (error) {
        console.warn("שגיאה בבדיקת חיבור:", error);
        setIsOnline(false);
      }
    };

    const networkInterval = setInterval(checkNetwork, 5000);
    checkNetwork();

    return () => clearInterval(networkInterval);
  }, []);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const unsubscribe = auth.onAuthStateChanged(async (firebaseUser) => {
      try {
        if (firebaseUser) {
          const userDoc = await getDoc(doc(db, "users", firebaseUser.uid));

          if (userDoc.exists()) {
            const userData = userDoc.data() as DBUser;
            setUser(firebaseUser);
            setUserRole(userData.role);
            setUserData(userData);

            await updateDoc(doc(db, "users", firebaseUser.uid), {
              lastLogin: new Date().toISOString(),
            });
          } else {
            throw new Error("משתמש לא נמצא");
          }
        } else {
          setUser(null);
          setUserRole(null);
          setUserData(null);
        }
      } catch (error) {
        setError(error instanceof Error ? error.message : "אירעה שגיאה");
        await auth.signOut();
        setUser(null);
        setUserRole(null);
        setUserData(null);
      } finally {
        setLoading(false);
      }
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        userRole,
        userData,
        error,
        isOnline,
        refreshAuth,
        hasPermission,
        signInWithPhone,
        verifyPhoneCode,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
