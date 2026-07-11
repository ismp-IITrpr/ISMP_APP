import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface Event {
  title: string;
  date: string;
  time: string;
  venue: string;
  targetAudience: string;
  groupNo?: string | number;
  type?: string;
  club?: string;
  description?: string;
}

interface UserProfile {
  degree: string;
  groupNo: number | string;
  fcmToken?: string;
  role?: string;
}

// Parse time string like "5:30 PM" or "05:30 PM" to a Date object
function parseEventDateTime(dateStr: string, timeStr: string): { start: Date; isValid: boolean } {
  try {
    const [day, month, year] = dateStr.split('/');
    const timeParts = timeStr.split(' ');
    const timeValue = timeParts[0];
    const period = timeParts[1];
    
    let [hoursStr, minutesStr] = timeValue.split(':');
    let hours = parseInt(hoursStr, 10);
    const minutes = parseInt(minutesStr, 10);
    
    if (period?.toLowerCase() === 'pm' && hours !== 12) {
      hours += 12;
    } else if (period?.toLowerCase() === 'am' && hours === 12) {
      hours = 0;
    }
    
    const eventDate = new Date(
      parseInt(year, 10),
      parseInt(month, 10) - 1,
      parseInt(day, 10),
      hours,
      minutes
    );
    return { start: eventDate, isValid: true };
  } catch (error) {
    console.error('Error parsing date/time:', dateStr, timeStr, error);
    return { start: new Date(), isValid: false };
  }
}

// Normalize strings for comparison
function normalize(val: string): string {
  return val.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
}

// Check if student is targeted for the event
function isTargeted(student: UserProfile, event: Event): boolean {
  if (!event.targetAudience) return false;
  const target = event.targetAudience.trim();
  
  if (target === 'All Members') return true;

  // Handles target format like "B.Tech-7" or "All-7"
  const parts = target.split('-');
  if (parts.length !== 2) return false;
  
  const targetDegree = normalize(parts[0]);
  const targetGroup = parseInt(parts[1], 10);
  
  const studentDegree = normalize(student.degree || '');
  const studentGroup = typeof student.groupNo === 'number'
    ? student.groupNo
    : parseInt(student.groupNo?.toString() ?? '0', 10);
    
  const degreeMatch = targetDegree === 'all' || targetDegree === studentDegree;
  return degreeMatch && studentGroup === targetGroup;
}

// Create Firestore notification doc (which triggers onNotificationCreated to send FCM)
async function sendCombinedNotification(
  userRollNo: string,
  title: string,
  description: string,
  iconType: string,
  notificationType: string,
  eventId?: string,
  eventDateTime?: admin.firestore.Timestamp
) {
  const notifRef = admin.firestore().collection('notifications').doc();
  await notifRef.set({
    userRollNo,
    title,
    description,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
    iconType,
    notificationType,
    eventId: eventId ?? '',
    eventDateTime: eventDateTime ?? null,
    reminderTiming: '',
  });
}

// === CLOUD FUNCTIONS ===

// 1. Triggered when a notification document is created — sends FCM push notification
export const onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const notification = snap.data();
    if (!notification) return;

    const userRollNo = notification.userRollNo;
    const title = notification.title || 'Notification';
    const description = notification.description || '';
    const iconType = notification.iconType || 'info';
    const eventId = notification.eventId || '';

    if (!userRollNo) return;

    try {
      const userDoc = await admin.firestore().collection('users').doc(userRollNo).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) return;

      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title,
          body: description,
        },
        data: {
          type: iconType,
          eventId: eventId,
          iconType: iconType,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`Successfully sent push notification to user ${userRollNo}`);
    } catch (error) {
      console.error(`Error sending push notification to user ${userRollNo}:`, error);
    }
  });

// 2. Triggered when an event is created — schedules reminders
export const scheduleEventReminders = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const event = snap.data() as Event;
    const { start, isValid } = parseEventDateTime(event.date, event.time);
    if (!isValid) return;

    const scheduleAt = async (minutesBefore: number, timing: string) => {
      const triggerTime = new Date(start.getTime() - minutesBefore * 60 * 1000);
      const delayMs = triggerTime.getTime() - Date.now();
      if (delayMs <= 0) return; // Already past reminder time

      await admin.firestore().collection('reminder_tasks').add({
        eventId: context.params.eventId,
        timing,
        executeAt: admin.firestore.Timestamp.fromDate(triggerTime),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    await scheduleAt(60, '1hr');
    await scheduleAt(15, '15min');
  });

// 3. Processes pending reminders (run via scheduled function or on-demand)
export const processReminders = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  const now = admin.firestore.Timestamp.now();
  const pendingRef = admin.firestore()
    .collection('reminder_tasks')
    .where('executeAt', '<=', now)
    .limit(10);

  const snapshot = await pendingRef.get();

  for (const doc of snapshot.docs) {
    const task = doc.data();
    const eventDoc = await admin.firestore().collection('events').doc(task.eventId).get();
    if (!eventDoc.exists) {
      await doc.ref.delete();
      continue;
    }

    const event = eventDoc.data() as Event;
    const { start } = parseEventDateTime(event.date, event.time);
    const timingLabel = task.timing === '1hr' ? '1 hour' : '15 minutes';

    const studentsSnapshot = await admin.firestore().collection('users').get();

    for (const studentDoc of studentsSnapshot.docs) {
      const student = studentDoc.data() as UserProfile;
      if (student.role === 'rep') continue; // skip reps
      const rollNo = studentDoc.id.trim().toUpperCase();

      if (isTargeted(student, event)) {
        await sendCombinedNotification(
          rollNo,
          `Event Reminder: ${event.title}`,
          `${event.title} starts in ${timingLabel} at ${event.venue}`,
          'event',
          'reminder',
          task.eventId,
          admin.firestore.Timestamp.fromDate(start),
        );
      }
    }

    await doc.ref.delete();
  }

  return { processed: snapshot.docs.length };
});
