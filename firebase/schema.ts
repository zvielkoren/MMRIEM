import { UserRole } from "@/types/roles";

export interface FirebaseUser {
  uid: string;
  email: string;
  displayName: string;
  role: UserRole;
  metadata: {
    createdAt: string;
    lastLoginAt: string;
  };
  profile: {
    phoneNumber?: string;
    photoURL?: string;
    address?: string;
    birthDate?: string;
  };
  settings: {
    notifications: boolean;
    language: "he" | "en";
    theme: "light" | "dark";
  };
  permissions: {
    canCreateEvents: boolean;
    canEditReports: boolean;
    canManageUsers: boolean;
  };
  status: "active" | "disabled" | "pending";
  lastActivity: string;
  sharedCalendars: string[];
  instructorId?: string; // For regular users
  students?: string[]; // For instructors
}

export const DEFAULT_USER_SETTINGS = {
  notifications: true,
  language: "he",
  theme: "light",
};

export const USER_ROLES_PERMISSIONS = {
  admin: {
    canCreateEvents: true,
    canEditReports: true,
    canManageUsers: true,
  },
  instructor: {
    canCreateEvents: true,
    canEditReports: true,
    canManageUsers: false,
  },
  user: {
    canCreateEvents: false,
    canEditReports: false,
    canManageUsers: false,
  },
};

export function createNewUser(
  uid: string,
  email: string,
  displayName: string,
  role: UserRole = "user"
): FirebaseUser {
  return {
    uid,
    email,
    displayName,
    role,
    metadata: {
      createdAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
    },
    profile: {},
    settings: DEFAULT_USER_SETTINGS,
    permissions: USER_ROLES_PERMISSIONS[role],
    status: "active",
    lastActivity: new Date().toISOString(),
    sharedCalendars: [],
  };
}
