import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_preferences.dart';
import 'widgets/main_layout.dart';
import 'widgets/rep_main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Run seeding asynchronously so it doesn't block the splash screen if the user is offline
  FirebaseService.instance.seedDatabaseIfNeeded().catchError((e) {
    debugPrint('Seeding failed: $e');
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
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        primaryColor: const Color(0xFF4A3AFF),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C23),
          selectedItemColor: Color(0xFF4A3AFF),
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
            backgroundColor: Color(0xFF0F0F13),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4A3AFF)),
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
                backgroundColor: Color(0xFF0F0F13),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A3AFF)),
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