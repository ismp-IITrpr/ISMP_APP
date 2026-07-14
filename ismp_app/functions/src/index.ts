import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

interface EventData {
  title: string;
  date: string;
  time: string;
  venue: string;
  targetAudience?: string;
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

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

function parseEventDateTime(date: string, time: string): Date | null {
  try {
    const [year, month, day] = date.split("-");
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

    const utcDate = new Date(Date.UTC(parseInt(year), parseInt(month) - 1, parseInt(day), hours, minutes));
    return new Date(utcDate.getTime() - IST_OFFSET_MS);
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
  targetAudience: string | undefined
): boolean {
  if (!targetAudience) return false;
  const target = targetAudience.trim();
  if (!target || target === "All Members" || target.toLowerCase() === "all: all") return true;

  const sDegree = normalizeDegree(studentDegree || "");
  const sGroup =
    typeof studentGroup === "number"
      ? studentGroup
      : parseInt(studentGroup?.toString() || "0", 10);

  let degreeLimit = "All";
  let targetGroups: number[] = [];

  if (target.includes(":")) {
    const parts = target.split(":");
    degreeLimit = parts[0].trim();
    const groupsPart = parts.slice(1).join(":").trim().toLowerCase();
    if (groupsPart !== "all" && groupsPart !== "all members" && groupsPart !== "") {
      targetGroups = groupsPart
        .split(/[\s,]+/)
        .map((s) => parseInt(s, 10))
        .filter((n) => !isNaN(n));
    }
  } else {
    const lower = target.toLowerCase();
    if (lower !== "all" && lower !== "all members") {
      targetGroups = target
        .split(/[\s,]+/)
        .map((s) => parseInt(s, 10))
        .filter((n) => !isNaN(n));
    }
  }

  if (normalizeDegree(degreeLimit) !== "all" && normalizeDegree(degreeLimit) !== sDegree) {
    return false;
  }

  if (targetGroups.length > 0 && !targetGroups.includes(sGroup)) {
    return false;
  }

  return true;
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
    reminderTiming: "",
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
  async (data: SendNotificationData, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }
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

    await Promise.all([
      scheduleReminder(60, "1hr"),
      scheduleReminder(15, "15min"),
    ]);
  });

// 3. Processes pending reminders (call this via Cloud Scheduler every minute)
export const processReminders = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  const now = admin.firestore.Timestamp.now();
  const snapshot = await admin
    .firestore()
    .collection("reminder_tasks")
    .where("executeAt", "<=", now)
    .limit(50)
    .get();

  let processed = 0;
  for (const doc of snapshot.docs) {
    try {
      const task = doc.data();
      const eventDoc = await admin.firestore().collection("events").doc(task.eventId).get();
      if (!eventDoc.exists) {
        await doc.ref.delete();
        continue;
      }

      const event = eventDoc.data() as EventData;
      const timingLabel = task.timing === "1hr" ? "1 hour" : "15 minutes";
      const eventDate = parseEventDateTime(event.date, event.time);

      const studentsSnapshot = await admin.firestore().collection("users").limit(1500).get();
      const notificationPromises: Promise<void>[] = [];

      for (const studentDoc of studentsSnapshot.docs) {
        const student = studentDoc.data() as UserData;
        if (student.role === "rep") continue;

        if (isStudentTargeted(student.degree, student.groupNo, event.targetAudience)) {
          notificationPromises.push(
            sendCombinedNotification(
              studentDoc.id.trim().toUpperCase(),
              `Reminder: ${event.title}`,
              `${event.title} starts in ${timingLabel} at ${event.venue}`,
              "event",
              "reminder",
              task.eventId,
              eventDate
                ? admin.firestore.Timestamp.fromDate(eventDate)
                : undefined
            )
          );
        }
      }

      await Promise.all(notificationPromises);
      await doc.ref.delete();
      processed++;
    } catch (e) {
      console.error("Error processing reminder task:", e);
    }
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
      try {
        const task = doc.data();
        const eventDoc = await admin.firestore().collection("events").doc(task.eventId).get();
        if (!eventDoc.exists) {
          await doc.ref.delete();
          continue;
        }

        const event = eventDoc.data() as EventData;
        const timingLabel = task.timing === "1hr" ? "1 hour" : "15 minutes";
        const eventDate = parseEventDateTime(event.date, event.time);

        const studentsSnapshot = await admin.firestore().collection("users").limit(1500).get();
        const notificationPromises: Promise<void>[] = [];

        for (const studentDoc of studentsSnapshot.docs) {
          const student = studentDoc.data() as UserData;
          if (student.role === "rep") continue;

          if (isStudentTargeted(student.degree, student.groupNo, event.targetAudience)) {
            notificationPromises.push(
              sendCombinedNotification(
                studentDoc.id.trim().toUpperCase(),
                `Reminder: ${event.title}`,
                `${event.title} starts in ${timingLabel} at ${event.venue}`,
                "event",
                "reminder",
                task.eventId,
                eventDate
                  ? admin.firestore.Timestamp.fromDate(eventDate)
                  : undefined
              )
            );
          }
        }

        await Promise.all(notificationPromises);
        await doc.ref.delete();
      } catch (e) {
        console.error("Error processing scheduled reminder:", e);
      }
    }
  });
