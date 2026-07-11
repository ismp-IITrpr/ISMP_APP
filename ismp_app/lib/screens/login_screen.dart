import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/main_layout.dart';
import '../services/firebase_service.dart';
import '../services/auth_preferences.dart';
import '../widgets/rep_main_layout.dart';
import '../widgets/google_sign_in_button.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSignInSubscription;

  @override
  void initState() {
    super.initState();
    FirebaseService.instance.deleteOldEvents();
    if (kIsWeb) {
      _googleSignInSubscription = GoogleSignIn.instance.authenticationEvents.listen((GoogleSignInAuthenticationEvent event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _handleGoogleSignInAccount(event.user);
        }
      });
    }
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    super.dispose();
  }

  void _handleGoogleSignInAccount(GoogleSignInAccount account) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.instance.signInWithGoogleAccount(account);
      if (user != null) {
        if (mounted) {
          FirebaseService.instance.seedDatabaseIfNeeded().catchError((e) {
            debugPrint('Post-login seeding failed: $e');
          });
          final isRep = FirebaseService.instance.isClubRep(user.email);
          await AuthPreferences.saveLogin(user.email ?? '', isRep);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isRep
                  ? const RepMainLayout()
                  : const MainLayout(isRep: false),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred during sign-in. Please try again.';
        if (e.toString().contains('invalid-email-domain')) {
          errorMessage = 'Access Denied: You are not authorized to access this app.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('Sign In Failed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              '$errorMessage\n\nError details: $e',
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.instance.signInWithGoogle();
      if (user != null) {
        if (mounted) {
          FirebaseService.instance.seedDatabaseIfNeeded().catchError((e) {
            debugPrint('Post-login seeding failed: $e');
          });
          final isRep = FirebaseService.instance.isClubRep(user.email);
          await AuthPreferences.saveLogin(user.email ?? '', isRep);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isRep
                  ? const RepMainLayout()
                  : const MainLayout(isRep: false),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred during sign-in. Please try again.';
        if (e.toString().contains('invalid-email-domain')) {
          errorMessage = 'Access Denied: You are not authorized to access this app.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('Sign In Failed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              '$errorMessage\n\nError details: $e',
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/Theme images/login_bg_new.jpg',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.20,
            left: 50,
            right: 50,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Institute Student',
                    style: TextStyle(
                      fontSize: 26,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.bold

                    ),
                  ),
                  const Text(
                    'Mentorship Program',
                    style: TextStyle(
                      fontSize: 26,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'IIT Ropar',
                    style: TextStyle(
                      fontSize: 40,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ]
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.33,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/Theme images/college_new.jpg',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.265,
            left: 30,
            right: 30,
            child: Column(
              children: [
                buildGoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Only for IIT Ropar Freshers',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}