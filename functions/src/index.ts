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
  targetRollNos?: string[];
  dotColor?: number;
}

interface UserProfile {
  degree: string;
  groupNo: number | string;
  fcmToken?: string;
  role?: string;
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

// 1a. Triggered when an event is created or updated to compute targetRollNos
export const onEventWrite = functions.firestore
  .document('events/{eventId}')
  .onWrite(async (change: functions.Change<functions.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const after = change.after.data() as Event | undefined;
    if (!after) return; // Event deleted

    const before = change.before.data() as Event | undefined;

    // Skip if targeting didn't change and targetRollNos already exists to prevent infinite loops
    if (before &&
      before.targetAudience === after.targetAudience &&
      before.groupNo === after.groupNo &&
      after.targetRollNos !== undefined) {
      return;
    }

    console.log(`Computing targetRollNos for event ${context.params.eventId}`);
    const studentsSnapshot = await admin.firestore().collection('users').get();
    const targetRollNos: string[] = [];

    for (const doc of studentsSnapshot.docs) {
      const student = doc.data() as UserProfile;
      if (student.role === 'rep') continue;

      if (isTargeted(student, after)) {
        targetRollNos.push(doc.id.toUpperCase().trim());
      }
    }

    await change.after.ref.update({ targetRollNos });
    console.log(`Saved ${targetRollNos.length} target roll numbers for event ${context.params.eventId}`);
  });


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


// 5. Submit session attendance (Cloud Function replaces client-side 1000+ reads)
export const submitAttendance = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const sessionId = data.sessionId;
  if (!sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'sessionId is required.');
  }

  const db = admin.firestore();
  const sessionDoc = await db.collection('attendance_sessions').doc(sessionId).get();
  if (!sessionDoc.exists) return { success: false, message: 'Session not found' };

  const sessionData = sessionDoc.data()!;
  const eventId = sessionData.eventId || '';
  const eventName = sessionData.eventName || '';
  const venue = sessionData.venue || '';

  let event: Event | null = null;
  if (eventId) {
    const eventDoc = await db.collection('events').doc(eventId).get();
    if (eventDoc.exists) {
      event = eventDoc.data() as Event;
    }
  }

  const eventType = event?.type || 'E';
  const clubName = event?.club || '';
  const date = event?.date || '';
  const time = event?.time || '';
  const dotColor = event?.dotColor ?? 0xFFD9278D; // Default to AppColors.primary

  // Get present students
  const scansSnapshot = await db.collection('attendance_sessions').doc(sessionId).collection('scans').get();
  const presentRollNos = new Set(scansSnapshot.docs.map(doc => doc.id.toUpperCase().trim()));

  // Get target students
  let targetRollNos: string[] = [];
  if (event?.targetRollNos) {
    targetRollNos = event.targetRollNos;
  } else {
    // Fallback if targetRollNos not computed yet
    const studentsSnapshot = await db.collection('users').get();
    for (const doc of studentsSnapshot.docs) {
      const student = doc.data() as UserProfile;
      if (student.role !== 'rep' && (!event || isTargeted(student, event))) {
        targetRollNos.push(doc.id.toUpperCase().trim());
      }
    }
  }

  const batch = db.batch();
  const notificationPromises: Promise<void>[] = [];

  // 1. Process Present Students
  for (const doc of scansSnapshot.docs) {
    const rollNo = doc.id.toUpperCase().trim();
    const attendanceRef = db.collection('users').doc(rollNo).collection('attendance').doc(eventId || sessionId);

    batch.set(attendanceRef, {
      eventId: eventId || sessionId,
      eventType,
      title: eventName,
      club: clubName,
      date,
      time,
      venue,
      isPresent: true,
      iconColor: dotColor,
      markedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update stickers if club event
    if (eventType === 'C' && clubName) {
      const existing = await db.collection('users').doc(rollNo).collection('attendance')
        .where('club', '==', clubName).where('isPresent', '==', true).limit(1).get();
      if (existing.empty) {
        batch.update(db.collection('users').doc(rollNo), {
          stickersCollected: admin.firestore.FieldValue.increment(1)
        });
      }
    }

    notificationPromises.push(
      sendCombinedNotification(rollNo, 'Attendance Marked', `Your attendance for the session "${eventName}" has been marked present.`, 'attendance', 'attendance')
    );
  }

  // 2. Process Absent Students
  for (const rollNo of targetRollNos) {
    if (presentRollNos.has(rollNo)) continue;

    const attendanceRef = db.collection('users').doc(rollNo).collection('attendance').doc(eventId || sessionId);
    batch.set(attendanceRef, {
      eventId: eventId || sessionId,
      eventType,
      title: eventName,
      club: clubName,
      date,
      time,
      venue,
      isPresent: false,
      iconColor: dotColor,
      markedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // End session
  batch.update(db.collection('attendance_sessions').doc(sessionId), {
    status: 'ended'
  });

  await batch.commit();
  await Promise.all(notificationPromises);

  return { success: true, presentCount: presentRollNos.size, absentCount: targetRollNos.length - presentRollNos.size };
});
