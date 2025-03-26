import { UserRole } from "@/types/roles";

export const FIREBASE_RULES_VERSION = "2";

export interface CollectionPermissions {
  read: boolean;
  write: boolean;
  delete?: boolean;
  update?: boolean;
}

export function checkPermissions(
  userRole: UserRole | null,
  collection: string
): CollectionPermissions {
  if (!userRole) return { read: false, write: false };

  switch (collection) {
    case "users":
      return {
        read: true,
        write: userRole === "admin",
        update: true,
        delete: userRole === "admin",
      };

    case "settings":
      return {
        read: true,
        write: userRole === "admin",
        delete: userRole === "admin",
      };

    case "events":
      return {
        read: true,
        write: userRole === "admin" || userRole === "instructor",
        update: userRole === "admin" || userRole === "instructor",
        delete: userRole === "admin",
      };

    case "reports":
      return {
        read: userRole === "admin" || userRole === "instructor",
        write: userRole === "admin" || userRole === "instructor",
        update: userRole === "admin" || userRole === "instructor",
        delete: userRole === "admin",
      };

    case "sessions":
      return {
        read: userRole === "admin",
        write: true, // Allow creating own session
        delete: userRole === "admin",
      };

    default:
      return { read: false, write: false };
  }
}

export const FIREBASE_RULES = `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
     
    function isAdmin() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // User collection rules
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
    }
    
    // Settings collection rules
    match /settings/{settingId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Events collection rules
    match /events/{eventId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && 
        (isAdmin() || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'instructor');
    }
    
    // Reports collection rules
    match /reports/{reportId} {
      allow read, write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'instructor']);
    }
    
    // Sessions collection rules
    match /sessions/{sessionId} {
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow read, delete: if isAdmin();
    }
  }
}`;
