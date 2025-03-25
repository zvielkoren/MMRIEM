import {
  collection,
  doc,
  setDoc,
  getDocs,
  query,
  where,
  getDoc,
} from "firebase/firestore";
import { db } from "@/config/firebase";
import { UserRole } from "@/types/roles";

// Database Collections Template
export const DB_COLLECTIONS = {
  USERS: "users",
  EVENTS: "events",
  REPORTS: "reports",
  CALENDARS: "calendars",
  SETTINGS: "settings",
} as const;

const DB_VERSION = "1.0";

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
        console.log(`
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read their own data
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && (request.auth.uid == userId || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Allow authenticated users to read events
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'instructor']);
    }
    
    // Allow authenticated users to read and write reports
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Allow admin to manage settings
    match /settings/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}`);
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

    console.log("Database initialized successfully");
  } catch (error) {
    console.error("Error initializing database:", error);
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
