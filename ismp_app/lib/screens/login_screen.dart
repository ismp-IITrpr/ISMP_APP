import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/firebase_service.dart';
import '../widgets/rep_main_layout.dart';
import 'rep_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseService.instance.deleteOldEvents();
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.instance.signInWithGoogle();
      if (user != null) {
        if (mounted) {
          final isRep = FirebaseService.instance.isClubRep(user.email);
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
            backgroundColor: const Color(0xFF1C1C23),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
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
                child: const Text('OK', style: TextStyle(color: Color(0xFF8B78FF), fontWeight: FontWeight.bold)),
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
            'assets/Theme images/login_bg.png',
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
                      color: Color(0xFFE6E6FA),
                      fontWeight: FontWeight.bold

                    ),
                  ),
                  const Text(
                    'Mentorship Program',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFFE6E6FA),
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'IIT Ropar',
                    style: TextStyle(
                      fontSize: 40,
                      color: Color(0xFFE6E6FA),
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
                'assets/Theme images/college.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.24,
            left: 30,
            right: 30,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/Theme images/G.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 20),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Only for IIT Ropar Freshers',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showTesterLoginSheet(context),
                  child: const Text(
                    'Tester Sign In',
                    style: TextStyle(
                      color: Color(0xFF8B78FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTesterLoginSheet(BuildContext context) {
    final emailCtrl = TextEditingController(text: 'repaccess@gmail.com');
    final passCtrl = TextEditingController(text: '12345678');
    bool isTesterLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tester / Representative Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F0F13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F0F13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isTesterLoading
                        ? null
                        : () async {
                            setSheetState(() {
                              isTesterLoading = true;
                            });
                            try {
                              final user = await FirebaseService.instance.signInWithEmail(
                                emailCtrl.text,
                                passCtrl.text,
                              );
                              final currentEmail = FirebaseService.instance.currentUserEmail;
                              if ((user != null || currentEmail == 'repaccess@gmail.com') && mounted) {
                                Navigator.pop(context); // Close bottom sheet
                                final isRep = FirebaseService.instance.isClubRep(FirebaseService.instance.currentUserEmail);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isRep
                                        ? const RepMainLayout()
                                        : const MainLayout(isRep: false),
                                  ),
                                );
                              } else {
                                setSheetState(() {
                                  isTesterLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Login Failed: Unable to verify account.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                isTesterLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Login Failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B78FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isTesterLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}