import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/config/firebase";
import { UserGroup } from "./dbTemplate";

export async function sendEventNotification(
  eventId: string,
  group?: UserGroup
) {
  try {
    // Query relevant users
    const usersRef = collection(db, "users");
    const q =
      group === "ALL"
        ? query(usersRef, where("notificationToken", "!=", null))
        : query(
            usersRef,
            where("group", "==", group),
            where("notificationToken", "!=", null)
          );

    const snapshot = await getDocs(q);
    const tokens = snapshot.docs
      .map((doc) => doc.data().notificationToken)
      .filter(Boolean);

    // Send push notification to all tokens
    // Implementation depends on your notification service
    // Example using Firebase Cloud Messaging:
    /*
    const message = {
      notification: {
        title: 'אירוע חדש',
        body: 'נוסף אירוע חדש ללוח השנה',
      },
      tokens: tokens,
    };
    await admin.messaging().sendMulticast(message);
    */
  } catch (error) {
    console.error("Error sending notifications:", error);
  }
}
