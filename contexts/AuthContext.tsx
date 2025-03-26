import React, { createContext, useContext, useEffect, useState } from "react";
import { auth, db } from "../config/firebase";
import { User as FirebaseUser } from "firebase/auth";
import { doc, getDoc, updateDoc } from "firebase/firestore";
import { UserRole } from "@/types/roles";
import { DBUser } from "@/utils/dbTemplate";

interface AuthContextType {
  user: FirebaseUser | null;
  loading: boolean;
  userRole: UserRole | null;
  userData: DBUser | null;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  userRole: null,
  userData: null,
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<UserRole | null>(null);
  const [userData, setUserData] = useState<DBUser | null>(null);

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (user) => {
      setLoading(true);
      if (user) {
        try {
          // Get user data from Firestore
          const userDoc = await getDoc(doc(db, "users", user.uid));

          if (userDoc.exists()) {
            const userData = userDoc.data() as DBUser;
            setUserRole(userData?.role || "user");
            setUserData(userData);
            setUser(user);

            // Update last login
            await updateDoc(doc(db, "users", user.uid), {
              lastLogin: new Date().toISOString(),
            });
          } else {
            // User document doesn't exist - sign out
            await auth.signOut();
            setUser(null);
            setUserRole(null);
            setUserData(null);
          }
        } catch (error) {
          console.error("Error loading user data:", error);
          // On error, keep user signed out
          await auth.signOut();
          setUser(null);
          setUserRole(null);
          setUserData(null);
        }
      } else {
        setUser(null);
        setUserRole(null);
        setUserData(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, userRole, userData }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
