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

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

function parseEventDateTime(dateStr: string, timeStr: string): { start: Date | null; isValid: boolean } {
  try {
    const [year, month, day] = dateStr.split('-');
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

    const utcDate = new Date(Date.UTC(
      parseInt(year, 10),
      parseInt(month, 10) - 1,
      parseInt(day, 10),
      hours,
      minutes
    ));
    const istDate = new Date(utcDate.getTime() - IST_OFFSET_MS);
    return { start: istDate, isValid: true };
  } catch (error) {
    console.error('Error parsing date/time:', dateStr, timeStr, error);
    return { start: null, isValid: false };
  }
}

function normalize(val: string): string {
  return val.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
}

function isTargeted(student: UserProfile, event: Event): boolean {
  if (!event.targetAudience) return false;
  const target = event.targetAudience.trim();

  if (target === 'All Members' || target.toLowerCase() === 'all: all') return true;

  let degreeLimit = 'All';
  let targetGroups: number[] = [];

  if (target.includes(':')) {
    const parts = target.split(':');
    degreeLimit = parts[0].trim();
    const groupsPart = parts.slice(1).join(':').trim().toLowerCase();
    if (groupsPart !== 'all' && groupsPart !== 'all members' && groupsPart !== '') {
      targetGroups = groupsPart
        .split(/[\s,]+/)
        .map((s) => parseInt(s, 10))
        .filter((n) => !isNaN(n));
    }
  } else {
    const lower = target.toLowerCase();
    if (lower !== 'all' && lower !== 'all members') {
      targetGroups = target
        .split(/[\s,]+/)
        .map((s) => parseInt(s, 10))
        .filter((n) => !isNaN(n));
    }
  }

  const studentDegree = normalize(student.degree || '');
  const studentGroup = typeof student.groupNo === 'number'
    ? student.groupNo
    : parseInt(student.groupNo?.toString() ?? '0', 10);

  if (normalize(degreeLimit) !== 'all' && normalize(degreeLimit) !== studentDegree) {
    return false;
  }

  if (targetGroups.length > 0 && !targetGroups.includes(studentGroup)) {
    return false;
  }

  return true;
}

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
    if (!isValid || !start) return;

    const scheduleAt = async (minutesBefore: number, timing: string) => {
      const triggerTime = new Date(start.getTime() - minutesBefore * 60 * 1000);
      const delayMs = triggerTime.getTime() - Date.now();
      if (delayMs <= 0) return;

      await admin.firestore().collection('reminder_tasks').add({
        eventId: context.params.eventId,
        timing,
        executeAt: admin.firestore.Timestamp.fromDate(triggerTime),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    };

    await Promise.all([
      scheduleAt(60, '1hr'),
      scheduleAt(15, '15min'),
    ]);
  });

// 3. Processes pending reminders (run via scheduled function or on-demand)
export const processReminders = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const now = admin.firestore.Timestamp.now();
  const pendingRef = admin.firestore()
    .collection('reminder_tasks')
    .where('executeAt', '<=', now)
    .limit(50);

  const snapshot = await pendingRef.get();

  for (const doc of snapshot.docs) {
    try {
      const task = doc.data();
      const eventDoc = await admin.firestore().collection('events').doc(task.eventId).get();
      if (!eventDoc.exists) {
        await doc.ref.delete();
        continue;
      }

      const event = eventDoc.data() as Event;
      const { start } = parseEventDateTime(event.date, event.time);
      const timingLabel = task.timing === '1hr' ? '1 hour' : '15 minutes';

      const studentsSnapshot = await admin.firestore().collection('users').limit(1500).get();
      const notificationPromises: Promise<void>[] = [];

      for (const studentDoc of studentsSnapshot.docs) {
        const student = studentDoc.data() as UserProfile;
        if (student.role === 'rep') continue;
        const rollNo = studentDoc.id.trim().toUpperCase();

        if (isTargeted(student, event)) {
          notificationPromises.push(
            sendCombinedNotification(
              rollNo,
              `Event Reminder: ${event.title}`,
              `${event.title} starts in ${timingLabel} at ${event.venue}`,
              'event',
              'reminder',
              task.eventId,
              start ? admin.firestore.Timestamp.fromDate(start) : undefined,
            )
          );
        }
      }

      await Promise.all(notificationPromises);
      await doc.ref.delete();
    } catch (e) {
      console.error('Error processing reminder task:', e);
    }
  }

  return { processed: snapshot.docs.length };
});

// 4. Scheduled function that runs every minute to process reminders
export const scheduledProcessReminders = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await admin.firestore()
      .collection('reminder_tasks')
      .where('executeAt', '<=', now)
      .limit(50)
      .get();

    for (const doc of snapshot.docs) {
      try {
        const task = doc.data();
        const eventDoc = await admin.firestore().collection('events').doc(task.eventId).get();
        if (!eventDoc.exists) {
          await doc.ref.delete();
          continue;
        }

        const event = eventDoc.data() as Event;
        const { start } = parseEventDateTime(event.date, event.time);
        const timingLabel = task.timing === '1hr' ? '1 hour' : '15 minutes';

      const studentsSnapshot = await admin.firestore().collection('users').limit(1500).get();
        const notificationPromises: Promise<void>[] = [];

        for (const studentDoc of studentsSnapshot.docs) {
          const student = studentDoc.data() as UserProfile;
          if (student.role === 'rep') continue;
          const rollNo = studentDoc.id.trim().toUpperCase();

          if (isTargeted(student, event)) {
            notificationPromises.push(
              sendCombinedNotification(
                rollNo,
                `Event Reminder: ${event.title}`,
                `${event.title} starts in ${timingLabel} at ${event.venue}`,
                'event',
                'reminder',
                task.eventId,
                start ? admin.firestore.Timestamp.fromDate(start) : undefined,
              )
            );
          }
        }

        await Promise.all(notificationPromises);
        await doc.ref.delete();
      } catch (e) {
        console.error('Error processing scheduled reminder:', e);
      }
    }
  });
