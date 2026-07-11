import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

interface EventData {
  title: string;
  date: string;
  time: string;
  venue: string;
  targetAudience?: string[];
  type?: string;
  club?: string;
}

interface UserData {
  degree?: string;
  groupNo?: number | string;
  fcmToken?: string;
  role?: string;
}

interface SendNotificationData {
  rollNo: string;
  title: string;
  description: string;
  iconType: string;
  notificationType: string;
}

function parseEventDateTime(date: string, time: string): Date | null {
  try {
    const [day, month, year] = date.split("/");
    let hours = 0;
    let minutes = 0;
    const timeLower = time.toLowerCase();

    if (timeLower.includes("am") || timeLower.includes("pm")) {
      const timePart = timeLower.replace(/\s*(am|pm)/, "");
      const period = timeLower.includes("pm") ? "pm" : "am";
      const [h, m] = timePart.split(":");
      hours = parseInt(h);
      minutes = parseInt(m || "0");
      if (period === "pm" && hours !== 12) hours += 12;
      if (period === "am" && hours === 12) hours = 0;
    } else {
      const [h, m] = time.split(":");
      hours = parseInt(h);
      minutes = parseInt(m || "0");
    }

    return new Date(parseInt(year), parseInt(month) - 1, parseInt(day), hours, minutes);
  } catch {
    return null;
  }
}

function normalizeDegree(degree: string): string {
  return degree.replace(/[^a-zA-Z0-9]/gi, "").toLowerCase();
}

function isStudentTargeted(
  studentDegree: string | undefined,
  studentGroup: number | string | undefined,
  targetAudience: string[] | undefined
): boolean {
  if (!targetAudience || targetAudience.length === 0) return false;
  const sDegree = normalizeDegree(studentDegree || "");
  const sGroup =
    typeof studentGroup === "number"
      ? studentGroup
      : parseInt(studentGroup?.toString() || "0", 10);

  for (const target of targetAudience) {
    const parts = target.split("-");
    if (parts.length !== 2) continue;
    const tDegree = normalizeDegree(parts[0]);
    const tGroup = parseInt(parts[1], 10);
    const degreeMatch = tDegree === normalizeDegree("All") || tDegree === sDegree;
    if (degreeMatch && sGroup === tGroup) return true;
  }
  return false;
}

async function sendCombinedNotification(
  rollNo: string,
  title: string,
  description: string,
  iconType: string,
  notificationType: string,
  eventId?: string,
  eventDateTime?: FirebaseFirestore.Timestamp
) {
  const notifRef = admin.firestore().collection("notifications").doc();
  await notifRef.set({
    userRollNo: rollNo,
    title,
    description,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
    iconType,
    notificationType: notificationType || "info",
    eventId: eventId || "",
    eventDateTime: eventDateTime || null,
    reminderTiming: notificationType === "reminder" ? (iconType === "1hr" ? "1hr" : "15min") : "",
  });

  const userDoc = await admin.firestore().collection("users").doc(rollNo).get();
  const fcmToken = (userDoc.data() as UserData | undefined)?.fcmToken;
  if (!fcmToken) return;

  const message: admin.messaging.Message = {
    token: fcmToken,
    notification: { title, body: description },
    data: {
      type: notificationType,
      eventId: eventId || "",
      iconType,
    },
    android: { priority: "high", notification: { channelId: "default" } },
    apns: { payload: { aps: { sound: "default" } } },
  };
  try {
    await admin.messaging().send(message);
  } catch (e) {
    console.error(`FCM send error for ${rollNo}:`, e);
  }
}

// ==================== CLOUD FUNCTIONS ====================

// 1. Called from Flutter after attendance submit
export const sendAttendancePush = functions.https.onCall(
  async (data: SendData) => {
    const { rollNo, title, description, iconType, notificationType } = data;
    await sendCombinedNotification(rollNo, title, description, iconType, notificationType);
    return { success: true };
  }
);

// 2. Triggered when event is created — schedules reminders
export const scheduleEventReminders = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snap) => {
    const event = snap.data() as EventData;
    const eventDate = parseEventDateTime(event.date, event.time);
    if (!eventDate) return;

    const now = Date.now();
    const scheduleReminder = async (minutesBefore: number, timing: string) => {
      const triggerTime = eventDate!.getTime() - minutesBefore * 60 * 1000;
      if (triggerTime <= now) return;

      await admin.firestore().collection("reminder_tasks").add({
        eventId: snap.id,
        timing,
        executeAt: admin.firestore.Timestamp.fromMillis(triggerTime),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    await scheduleReminder(60, "1hr");
    await scheduleReminder(15, "15min");
  });

// 3. Processes pending reminders (call this via Cloud Scheduler every minute)
export const processReminders = functions.https.onCall(async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await admin
    .firestore()
    .collection("reminder_tasks")
    .where("executeAt", "<=", now)
    .limit(50)
    .get();

  let processed = 0;
  for (const doc of snapshot.docs) {
    const task = doc.data();
    const eventDoc = await admin.firestore().collection("events").doc(task.eventId).get();
    if (!eventDoc.exists) {
      await doc.ref.delete();
      continue;
    }

    const event = eventDoc.data() as EventData;
    const timingLabel = task.timing === "1hr" ? "1 hour" : "15 minutes";
    const eventDate = parseEventDateTime(event.date, event.time);

    const studentsSnapshot = await admin.firestore().collection("users").get();
    for (const studentDoc of studentsSnapshot.docs) {
      const student = studentDoc.data() as UserData;
      if (student.role === "rep") continue;

      if (isStudentTargeted(student.degree, student.groupNo, event.targetAudience)) {
        await sendCombinedNotification(
          studentDoc.id.trim().toUpperCase(),
          `Reminder: ${event.title}`,
          `${event.title} starts in ${timingLabel} at ${event.venue}`,
          "event",
          "reminder",
          task.eventId,
          eventDate
            ? admin.firestore.Timestamp.fromDate(eventDate)
            : undefined
        );
      }
    }

    await doc.ref.delete();
    processed++;
  }

  return { processed };
});

// 4. Scheduled function that runs every minute to process reminders
export const scheduledProcessReminders = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await admin
      .firestore()
      .collection("reminder_tasks")
      .where("executeAt", "<=", now)
      .limit(50)
      .get();

    for (const doc of snapshot.docs) {
      const task = doc.data();
      const eventDoc = await admin.firestore().collection("events").doc(task.eventId).get();
      if (!eventDoc.exists) {
        await doc.ref.delete();
        continue;
      }

      const event = eventDoc.data() as EventData;
      const timingLabel = task.timing === "1hr" ? "1 hour" : "15 minutes";
      const eventDate = parseEventDateTime(event.date, event.time);

      const studentsSnapshot = await admin.firestore().collection("users").get();
      for (const studentDoc of studentsSnapshot.docs) {
        const student = studentDoc.data() as UserData;
        if (student.role === "rep") continue;

        if (isStudentTargeted(student.degree, student.groupNo, event.targetAudience)) {
          await sendCombinedNotification(
            studentDoc.id.trim().toUpperCase(),
            `Reminder: ${event.title}`,
            `${event.title} starts in ${timingLabel} at ${event.venue}`,
            "event",
            "reminder",
            task.eventId,
            eventDate
              ? admin.firestore.Timestamp.fromDate(eventDate)
              : undefined
          );
        }
      }
      await doc.ref.delete();
    }
  });