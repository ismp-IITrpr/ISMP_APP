import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/events.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // 1. Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotif.initialize(settings: initSettings);

    // 2. Request FCM permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Set up token logic
    _setupToken();

    // 4. Listen to token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      _updateTokenInFirestore(newToken);
    });

    // 5. Listen to auth state changes to update token when user logs in
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _setupToken();
      }
    });
  }

  Future<void> _setupToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final email = user.email;
        if (email != null && email.contains('@')) {
          final rollNo = email.split('@')[0].toUpperCase();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(rollNo)
              .set({'fcmToken': token}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error updating FCM token in Firestore: $e');
    }
  }

  // Called when push notification arrives while app is in foreground
  void onForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'Standard notification channel for ISMP app',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotif.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: message.data.toString(),
      );
    }
  }

  /// Schedules local reminders for events the student is targeted for.
  /// Call this whenever fresh events are fetched from the server.
  Future<void> scheduleEventReminders(List<EventModel> events) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;
      final rollNo = user.email!.split('@')[0].toUpperCase();
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
      if (!userDoc.exists) return;
      
      final studentDegree = userDoc.data()?['degree']?.toString() ?? 'B.Tech';
      final studentGroupNoStr = userDoc.data()?['groupNo']?.toString() ?? '0';
      final studentGroupNo = int.tryParse(studentGroupNoStr) ?? 0;

      // Clear all existing local scheduled notifications so we don't duplicate
      await _localNotif.cancelAll();

      const androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Event Reminders',
        channelDescription: 'Reminders for upcoming events',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      int idCounter = 1000;
      final now = DateTime.now();

      for (var event in events) {
        if (!event.isStudentTargeted(studentDegree, studentGroupNo)) continue;

        final eventTime = event.getParsedDateTime();
        
        // 1 hour reminder
        final oneHourBefore = eventTime.subtract(const Duration(hours: 1));
        if (oneHourBefore.isAfter(now)) {
          await _localNotif.zonedSchedule(
            id: idCounter++,
            title: 'Event Reminder: ${event.title}',
            body: 'Starts in 1 hour at ${event.venue}',
            scheduledDate: tz.TZDateTime.from(oneHourBefore, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }

        // 15 min reminder
        final fifteenMinBefore = eventTime.subtract(const Duration(minutes: 15));
        if (fifteenMinBefore.isAfter(now)) {
          await _localNotif.zonedSchedule(
            id: idCounter++,
            title: 'Event Reminder: ${event.title}',
            body: 'Starts in 15 minutes at ${event.venue}',
            scheduledDate: tz.TZDateTime.from(fifteenMinBefore, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
      debugPrint('Successfully scheduled local event reminders.');
    } catch (e) {
      debugPrint('Error scheduling local reminders: $e');
    }
  }
}
