export enum UserRole {
  User = "user",
  Instructor = "instructor",
  Admin = "admin",
}

export const ROLES: { [key in UserRole]: UserRole } = {
  [UserRole.User]: UserRole.User,
  [UserRole.Instructor]: UserRole.Instructor,
  [UserRole.Admin]: UserRole.Admin,
};

export const ROLE_LABELS: { [key in UserRole]: string } = {
  [UserRole.User]: "משתמש",
  [UserRole.Instructor]: "מדריך",
  [UserRole.Admin]: "מנהל",
};
