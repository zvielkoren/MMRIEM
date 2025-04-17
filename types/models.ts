import { UserRole } from "./roles";

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  sharedCalendars: string[];
}

export interface Calendar {
  id: string;
  owner: string;
  name: string;
  events: string[];
}

export interface Event {
  id: string;
  calendarId: string;
  title: string;
  description: string;
  date: Date;
  participants: string[];
  reminders: string[];
}

export interface JournalReport {
  id: string;
  userId: string;
  journalText: string;
  instructorSignature?: string;
  timestamp: Date;
  completed: boolean;
}
