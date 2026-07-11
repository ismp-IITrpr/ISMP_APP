import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_preferences.dart';
import 'services/notification_service.dart';
import 'widgets/main_layout.dart';
import 'widgets/rep_main_layout.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId: '231730406983-ivqk4ir349scpola2l866t9t4pth22kl.apps.googleusercontent.com',
  );
  // Run seeding asynchronously so it doesn't block the splash screen if the user is offline
  FirebaseService.instance.seedDatabaseIfNeeded().catchError((e) {
    debugPrint('Seeding failed: $e');
  });

  // Initialize notification service
  final notifService = NotificationService.instance;
  await notifService.initialize();

  // Foreground messages
  FirebaseMessaging.onMessage.listen(notifService.onForegroundMessage);

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // When app opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    // Navigate to relevant screen based on message data if needed
  });
  
  // Remove the splash screen once Flutter has initialized
  FlutterNativeSplash.remove();
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISMP App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0920),
        primaryColor: const Color(0xFFD9278D),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1635),
          selectedItemColor: Color(0xFFD9278D),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Checks SharedPreferences on startup to decide whether to show
/// the login screen or skip directly to the main app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthPreferences.isLoggedIn(),
      builder: (context, snapshot) {
        // Show a splash-style loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0920),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD9278D)),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        if (!isLoggedIn) {
          return const LoginScreen();
        }

        // User is logged in — determine their role
        return FutureBuilder<bool>(
          future: AuthPreferences.getIsRep(),
          builder: (context, repSnapshot) {
            if (repSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F0920),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD9278D)),
                ),
              );
            }

            final isRep = repSnapshot.data ?? false;
            if (isRep) {
              return const RepMainLayout();
            }
            return const MainLayout(isRep: false);
          },
        );
      },
    );
  }
}