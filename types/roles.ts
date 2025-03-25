export type UserRole = "user" | "instructor" | "admin";

export const ROLES: { [key in UserRole]: UserRole } = {
  user: "user",
  instructor: "instructor",
  admin: "admin",
};

export const ROLE_LABELS: { [key in UserRole]: string } = {
  user: "משתמש",
  instructor: "מדריך",
  admin: "מנהל",
};
