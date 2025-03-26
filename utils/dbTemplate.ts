import {
  collection,
  doc,
  setDoc,
  getDocs,
  query,
  where,
  getDoc,
  updateDoc,
} from "firebase/firestore";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "@/config/firebase";
import { UserRole } from "@/types/roles";
import { FIREBASE_RULES } from "@/firebase/rules";

// Add password constants
const DEFAULT_PASSWORDS = {
  ADMIN: "Admin123!",
  INSTRUCTOR: "Instructor123!",
  USER: "User123!",
} as const;

// Database Collections Template
export const DB_COLLECTIONS = {
  USERS: "users",
  EVENTS: "events",
  REPORTS: "reports",
  CALENDARS: "calendars",
  SETTINGS: "settings",
  SESSIONS: "sessions",
  PROFILE_REQUESTS: "profileEditRequests",
} as const;

const DB_VERSION = "1.0";

// Add groups definition
export const USER_GROUPS = {
  A: "קבוצה א",
  B: "קבוצה ב",
  ALL: "כולם",
} as const;

export type UserGroup = keyof typeof USER_GROUPS;

// Template Data Structures
export interface DBUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  createdAt: string;
  phoneNumber?: string;
  lastLogin?: string;
  settings?: {
    notifications: boolean;
    language: "he" | "en";
  };
  group?: UserGroup;
  notificationToken?: string;
}

interface DBEvent {
  id: string;
  calendarId: string;
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  location?: string;
  createdBy: string;
  participants: string[];
  status: "active" | "cancelled" | "completed";
  reminders: {
    type: "email" | "push";
    time: number; // minutes before event
  }[];
}

interface DBReport {
  id: string;
  userId: string;
  type: "daily" | "weekly" | "monthly";
  content: {
    text: string;
    attachments?: string[];
  };
  instructorId?: string;
  status: "draft" | "submitted" | "reviewed";
  createdAt: string;
  updatedAt: string;
}

// Add Session interface
interface DBSession {
  id: string;
  userId: string;
  deviceInfo: {
    platform: string;
    deviceId?: string;
    browser?: string;
  };
  lastActive: string;
  createdAt: string;
  expiresAt: string;
  isValid: boolean;
}

// Add ProfileEditRequest interface
interface DBProfileEditRequest {
  id: string;
  userId: string;
  userName: string;
  requestedChanges: {
    name?: string;
    phoneNumber?: string;
  };
  status: "pending" | "approved" | "rejected";
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
  reviewedBy?: string;
  reviewedAt?: string;
}

// Add user permissions
export const USER_PERMISSIONS = {
  admin: {
    canViewReports: true,
    canCreateReports: true,
    canViewStaff: true,
    canManageUsers: true,
    canManageEvents: true,
  },
  instructor: {
    canViewReports: true,
    canCreateReports: true,
    canViewStaff: false,
    canManageUsers: false,
    canManageEvents: true,
  },
  user: {
    canViewReports: false,
    canCreateReports: false,
    canViewStaff: false,
    canManageUsers: false,
    canManageEvents: false,
    canViewEvents: true,
  },
} as const;

// Utility function to initialize database with template
export async function initializeDatabase() {
  try {
    // Check current version
    const settingsDoc = await getDoc(
      doc(db, DB_COLLECTIONS.SETTINGS, "general")
    );
    if (settingsDoc.exists() && settingsDoc.data()?.version === DB_VERSION) {
      console.log("Database already initialized with current version");
      return;
    }

    // Test permissions first
    try {
      await getDocs(collection(db, DB_COLLECTIONS.SETTINGS));
    } catch (error: any) {
      if (error.code === "permission-denied") {
        console.error("Please set up Firestore rules first!");
        console.log(
          "Copy these rules to Firebase Console -> Firestore -> Rules:"
        );
        console.log(FIREBASE_RULES);
        return;
      }
      throw error;
    }

    // Check if admin exists
    const adminQuery = query(
      collection(db, DB_COLLECTIONS.USERS),
      where("role", "==", "admin")
    );
    const adminDocs = await getDocs(adminQuery);

    if (adminDocs.empty) {
      // Create default admin
      const adminUser: DBUser = {
        id: "admin",
        email: "admin@example.com",
        name: "מנהל מערכת",
        role: "admin",
        createdAt: new Date().toISOString(),
        settings: {
          notifications: true,
          language: "he",
        },
      };

      await setDoc(doc(db, DB_COLLECTIONS.USERS, adminUser.id), adminUser);
      console.log("Created default admin user");
    }

    // Initialize Users Collection with Sample Data
    const sampleUsers: DBUser[] = [
      {
        id: "admin",
        email: "admin@mmriem.com",
        password: DEFAULT_PASSWORDS.ADMIN, // Will be removed after creation
        name: "מנהל ראשי",
        role: "admin",
        createdAt: new Date().toISOString(),
        settings: {
          notifications: true,
          language: "he",
        },
      },
      {
        id: "instructor1",
        email: "instructor@mmriem.com",
        password: DEFAULT_PASSWORDS.INSTRUCTOR, // Will be removed after creation
        name: "מדריך ראשי",
        role: "instructor",
        createdAt: new Date().toISOString(),
        settings: {
          notifications: true,
          language: "he",
        },
      },
      {
        id: "user1",
        email: "user@mmriem.com",
        password: DEFAULT_PASSWORDS.USER, // Will be removed after creation
        name: "משתמש לדוגמה",
        role: "user",
        createdAt: new Date().toISOString(),
        settings: {
          notifications: true,
          language: "he",
        },
      },
    ];

    // Create users if they don't exist
    for (const user of sampleUsers) {
      try {
        const { password, ...userData } = user;
        const userCredential = await createUserWithEmailAndPassword(
          auth,
          user.email,
          password
        );
        await setDoc(
          doc(db, DB_COLLECTIONS.USERS, userCredential.user.uid),
          userData
        );
        console.log(
          `Created ${user.role} user: ${user.email} (Password: ${password})`
        );
      } catch (error: any) {
        if (error.code === "auth/email-already-in-use") {
          console.log(`User ${user.email} already exists`);
        } else {
          throw error;
        }
      }
    }

    // Create initial settings
    await setDoc(doc(db, DB_COLLECTIONS.SETTINGS, "general"), {
      systemName: "ממריאים מגולן",
      version: DB_VERSION,
      allowRegistration: true,
      defaultUserRole: "user",
      requirements: {
        minPasswordLength: 6,
        requireEmailVerification: true,
      },
    });

    // Initialize profile edit requests collection
    await setDoc(doc(db, DB_COLLECTIONS.SETTINGS, "profileRequests"), {
      requireAdminApproval: true,
      autoRejectOnRoleChange: true,
      notifications: {
        sendEmailOnRequest: true,
        sendEmailOnApproval: true,
      },
    });

    // Add default groups to admin settings
    await setDoc(doc(db, DB_COLLECTIONS.SETTINGS, "groups"), {
      enabled: true,
      requireApproval: false,
      groups: USER_GROUPS,
      defaultGroup: "ALL",
    });

    console.log("Database initialized successfully");
  } catch (error) {
    console.error("Error initializing database:", error);
    throw error;
  }
}

// Add utility function to recreate users table
export async function resetUsersTable() {
  try {
    const usersSnap = await getDocs(collection(db, DB_COLLECTIONS.USERS));
    const batch = db.batch();

    // Delete existing users
    usersSnap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // Reinitialize database
    await initializeDatabase();
    console.log("Users table reset successfully");
  } catch (error) {
    console.error("Error resetting users table:", error);
    throw error;
  }
}

// Utility function to validate database structure
export async function validateDatabaseStructure() {
  const requiredCollections = Object.values(DB_COLLECTIONS);
  const errors: string[] = [];

  for (const collectionName of requiredCollections) {
    try {
      const snapshot = await getDocs(collection(db, collectionName));
      console.log(
        `Collection ${collectionName} exists with ${snapshot.size} documents`
      );
    } catch (error) {
      errors.push(`Missing collection: ${collectionName}`);
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// Add utility function to update user group
export async function updateUserGroup(userId: string, group: UserGroup) {
  try {
    const userRef = doc(db, DB_COLLECTIONS.USERS, userId);
    await updateDoc(userRef, {
      group,
      updatedAt: new Date().toISOString(),
    });
    return true;
  } catch (error) {
    console.error("Error updating user group:", error);
    return false;
  }
}
