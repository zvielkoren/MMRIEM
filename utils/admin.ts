import { doc, updateDoc, getDoc } from "firebase/firestore";
import { db } from "@/config/firebase";
import { UserRole } from "@/types/roles";

export async function setUserRole(userId: string, newRole: UserRole) {
  const userRef = doc(db, "users", userId);
  await updateDoc(userRef, {
    role: newRole,
  });
}

export async function getUserRole(userId: string): Promise<UserRole> {
  const userRef = doc(db, "users", userId);
  const userSnap = await getDoc(userRef);
  return userSnap.data()?.role || "user";
}
