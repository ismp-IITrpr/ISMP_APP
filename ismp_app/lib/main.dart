import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'theme/app_theme.dart';

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
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize();
  } else {
    await GoogleSignIn.instance.initialize(
      serverClientId: '231730406983-ivqk4ir349scpola2l866t9t4pth22kl.apps.googleusercontent.com',
    );
  }
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
      theme: AppTheme.darkTheme,
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
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
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